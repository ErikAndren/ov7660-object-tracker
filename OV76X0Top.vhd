library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity OV76X0 is
  generic (
    Freq     : positive := 25000000;
    Displays : positive := 8
    );
  port (
    AsyncRstN : in    bit1;
    Clk       : in    bit1;
    --
    Button1   : in    bit1;
    Button2   : in    bit1;
    --
    VSYNC     : in    bit1;
    HREF      : in    bit1;
    --
    XCLK      : out   bit1;
    PCLK      : in    bit1;
    D         : in    word(8-1 downto 0);
    -- SCCB interface
    SIO_C     : out   bit1;
    SIO_D     : inout bit1;
    -- VGA interface
    VgaRed    : out   word(3-1 downto 0);
    VgaGreen  : out   word(3-1 downto 0);
    VgaBlue   : out   word(3-1 downto 0);
    VgaHsync  : out   bit1;
    VgaVsync  : out   bit1;
    -- Sram interface
    SramD     : inout word(16-1 downto 0);
    SramAddr  : out   word(18-1 downto 0);
    SramCeN   : out   bit1;
    SramOeN   : out   bit1;
    SramWeN   : out   bit1;
    SramUbN   : out   bit1;
    SramLbN   : out   bit1
    );
end entity;

architecture rtl of OV76X0 is
  signal Btn1Stab, Btn2Stab : bit1;
  signal SccbData, DispData : word(SccbDataW-1 downto 0);
  signal SccbRe             : bit1;
  signal SccbWe             : bit1;
  signal SccbAddr           : word(SccbAddrW-1 downto 0);
  signal XCLK_i             : bit1;
  signal RstN               : bit1;
  signal RstNPClk           : bit1;

  signal PixelData : word(8-1 downto 0);
  signal PixelVal  : bit1;

  signal VgaContAddr  : word(18-1 downto 0);
  signal PixelInData  : word(16-1 downto 0);
  signal PixelOutData : word(16-1 downto 0);
  signal VgaContWe    : bit1;
  signal VgaContRe    : bit1;
  signal VgaInView    : bit1;
  signal VgaDispData  : word(3-1 downto 0);

  signal PixelCompData : word(3-1 downto 0);
  signal PixelCompVal  : bit1;

  signal PixelPopWrite : bit1;
  signal PixelRead     : bit1;
  signal PixelReadPop  : bit1;

  signal SramWriteReq                : bit1;
  signal SramWriteAddr, SramReadAddr : word(SramAddrW-1 downto 0);

  signal FakeHref, FakeVSync : bit1;
  signal FakeD               : word(8-1 downto 0);

  signal Vsync_Clk : bit1;

  signal AlignedPixel    : word(8-1 downto 0);
  signal AlignedPixelVal : bit1;
  
begin
  Pll : entity work.Pll
    port map (
      inclk0 => Clk,
      c0     => XCLK_i
      );
  XCLK <= XCLK_i;

  RstSync : entity work.ResetSync
    port map (
      AsyncRst => AsyncRstN,
      Clk      => Clk,
      --
      Rst_N    => RstN
      );

  DebBtn1 : entity work.ButtonPulse
    port map (
      Clk         => Clk,
      RstN        => RstN,
      --
      Button      => Button1,
      ButtonPulse => Btn1Stab
      );

  DebBtn2 : entity work.ButtonPulse
    port map (
      Clk         => Clk,
      RstN        => RstN,
      --
      Button      => Button2,
      ButtonPulse => Btn2Stab
      );

  SccbM : entity work.SccbMaster
    generic map (
      ClkFreq => Freq
      )
    port map (
      Clk          => XCLK_i,
      Rst_N        => RstN,
      --
      DataFromSccb => SccbData,
      --
      SIO_C        => SIO_C,
      SIO_D        => SIO_D
      );

--      FakeVgaCam : entity work.FakeVgaCam
--      port map (
--              RstN  => RstN,
--              Clk   => XCLK_i,
--              --
--              VSync => FakeVSync,
--              HRef  => FakeHRef,
--              D     => FakeD
--      );

  CaptPixel : entity work.VideoCapturer
    generic map (
      DataW => D'length
      )
    port map (
      RstN      => RstN,
      Clk       => Clk,
      --
      PixelOut  => PixelData,
      PixelVal  => PixelVal,
      --
      PRstN     => AsyncRstN,
      PClk      => XCLK_i,
      Vsync     => VSYNC,
      HREF      => HREF,
      PixelData => D,
      --
      Vsync_Clk => Vsync_Clk
      );

  PixelAlign : entity work.PixelAligner
    port map (
      Clk         => Clk,
      RstN        => RstN,
      --
      Vsync       => Vsync_Clk,
      --
      PixelInVal  => PixelVal,
      PixelIn     => PixelData,
      --
      PixelOut    => AlignedPixel,
      PixelOutVal => AlignedPixelVal
      );

--      VideoComp : entity work.VideoCompressor
--      port map (
--              Clk       => Clk,
--              RstN      => RstN,
--              --
--              PixelData => PixelData,
--              PixelVal  => PixelVal,
--              --
--              PixelCompData => PixelCompData,
--              PixelCompVal  => PixelCompVal
--      );

  VideoComp : entity work.DitherFloydSteinberg
    port map (
      Clk          => Clk,
      RstN         => RstN,
      --
      Vsync        => Vsync_Clk,
      --
      ToggleEnable => Btn1Stab,
      ToggleTrunc  => Btn2Stab,
      --
      PixelIn      => AlignedPixel,
      PixelInVal   => AlignedPixelVal,
      --
      PixelOut     => PixelCompData,
      PixelOutVal  => PixelCompVal
      );

  VideoPack : entity work.VideoPacker
    port map (
      Clk            => Clk,
      RstN           => RstN,
      --
      PixelComp      => PixelCompData,
      PixelCompVal   => PixelCompVal,
      --
      PixelPacked    => PixelInData(15-1 downto 0),
      PixelPackedVal => SramWriteReq,
      SramWriteAddr  => SramWriteAddr,
      --
      PopPixelPack   => PixelPopWrite,
      Vsync          => Vsync_Clk
      );

  PixelInData(15) <= '0';

  SramArb : entity work.SramArbiter
    port map (
      RstN      => RstN,
      Clk       => Clk,
      --
      WriteAddr => SramWriteAddr,
      WriteReq  => SramWriteReq,
      PopWrite  => PixelPopWrite,
      --
      ReadAddr  => SramReadAddr,
      ReadReq   => PixelRead,
      PopRead   => PixelReadPop,
      --
      SramAddr  => VgaContAddr,
      SramWe    => VgaContWe,
      SramRe    => VgaContRe
      );

  -- 262144 words
  -- Each image is 640x480 = 307200 pixels
  -- Currently we have 3 bits of display (R, G, B)
  -- Each image then contains 307200 * 3 = 921600 bits
  -- That is 57600 words
  -- Up to 4 images may be stored with this encoding.
  -- If 2 frames are needed, each image may consume 6 bits per pixel
  SramCon : entity work.SramController
    port map (
      Clk     => Clk,
      RstN    => RstN,
      AddrIn  => VgaContAddr,
      WrData  => PixelInData,
      RdData  => PixelOutData,
      We      => VgaContWe,
      Re      => VgaContRe,
      --
      D       => SramD,
      AddrOut => SramAddr,
      CeN     => SramCeN,
      OeN     => SramOeN,
      WeN     => SramWeN,
      UbN     => SramUbN,
      LbN     => SramLbN
      );

  VideoCont : entity work.VideoController
    port map (
      Clk           => Clk,
      RstN          => RstN,
      --
      ReadSram      => PixelRead,
      SramAddr      => SramReadAddr,
      SramReqPopped => PixelReadPop,
      SramData      => PixelOutData,
      --
      InView        => VgaInView,
      DataToDisp    => VgaDispData
      );

  VgaGen : entity work.VgaGenerator
    generic map (
      DivideClk => true
      )
    port map (
      Clk           => Clk,
      RstN          => RstN,
      --
      DataToDisplay => VgaDispData,
      InView        => VgaInView,
      --
      Red           => VgaRed,
      Green         => VgaGreen,
      Blue          => VgaBlue,
      HSync         => VgaHsync,
      VSync         => VgaVsync
      );
end architecture rtl;
