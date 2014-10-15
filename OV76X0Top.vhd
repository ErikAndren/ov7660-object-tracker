-- Top file for the OV76X0 project
-- Purpose is to grab video from a VGA camera, perform edge detection and track
-- an object and generate a control signal to two servos controlloing the
-- movement of a camera.
-- Implemented on an altera Cyclone II FPGA
-- Copyright erik@zachrisson.info 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.Types.all;
use work.OV76X0Pack.all;
use work.SerialPack.all;

entity OV76X0Top is
  generic (
    Freq     : positive := 25000000;
    Displays : positive := 8
    );
  port (
    AsyncRstN  : in    bit1;
    RawClk        : in    bit1;
    --
    VSYNC      : in    bit1;
    HREF       : in    bit1;
    --
    XCLK       : out   bit1;
    PCLK       : in    bit1;
    D          : in    word(8-1 downto 0);
    -- SCCB interface
    SIO_C      : out   bit1;
    SIO_D      : inout bit1;
    -- VGA interface
    VgaRed     : out   word(3-1 downto 0);
    VgaGreen   : out   word(3-1 downto 0);
    VgaBlue    : out   word(3-1 downto 0);
    VgaHsync   : out   bit1;
    VgaVsync   : out   bit1;
    -- Sram interface
    SramD      : inout word(16-1 downto 0);
    SramAddr   : out   word(18-1 downto 0);
    SramCeN    : out   bit1;
    SramOeN    : out   bit1;
    SramWeN    : out   bit1;
    SramUbN    : out   bit1;
    SramLbN    : out   bit1;
    --
    SerialIn   : in    bit1;
    SerialOut  : out   bit1;    
    --
    -- Servo interface
    PitchServo : out   bit1;
    YawServo   : out   bit1
    );
end entity;

architecture rtl of OV76X0Top is
  constant Clk50Mhz_int              : positive := 50000000;
  --
  signal Clk50MHz                    : bit1;
  signal DispData                    : word(SccbDataW-1 downto 0);
  signal SccbRe                      : bit1;
  signal SccbWe                      : bit1;
  signal SccbAddr                    : word(SccbAddrW-1 downto 0);
  signal XCLK_i                      : bit1;
  signal Clk64KHz                    : bit1;
  signal RstN                        : bit1;
  signal RstNPClk                    : bit1;
  --
  signal PixelData                   : word(8-1 downto 0);
  signal PixelVal                    : bit1;
  --
  signal VgaContAddr                 : word(18-1 downto 0);
  signal PixelInData                 : word(16-1 downto 0);
  signal PixelOutData                : word(16-1 downto 0);
  signal VgaContWe                   : bit1;
  signal VgaContRe                   : bit1;
  signal VgaInView                   : bit1;
  signal PixelDispData               : word(3-1 downto 0);
  signal PixelDisp                   : bit1;
  signal DrawRect                    : bit1;
  signal PixelToObjFind              : word(PixelResW-1 downto 0);
  signal PixelToObjFindVal           : bit1;
  signal PixelToVga                  : word(PixelResW-1 downto 0);
  signal PixelCompData               : word(3-1 downto 0);
  signal PixelCompVal                : bit1;
  --
  signal PixelPopWrite               : bit1;
  signal PixelRead                   : bit1;
  signal PixelReadPop                : bit1;
  --
  signal SramWriteReq                : bit1;
  signal SramWriteAddr, SramReadAddr : word(SramAddrW-1 downto 0);

  signal RegAccess : RegAccessRec;

  signal FakeHref, FakeVSync : bit1;
  signal FakeD               : word(8-1 downto 0);

  signal Vsync_Clk : bit1;

  signal AlignedPixel    : word(8-1 downto 0);
  signal AlignedPixelVal : bit1;

  signal TopLeft, BottomRight : Cord;

  signal YawPos, PitchPos : word(ServoResW-1 downto 0);
  
begin
  Pll : entity work.Pll
    port map (
      inclk0 => RawClk,
      c0     => XCLK_i,
      c1     => Clk50MHz
      );
  XCLK <= XCLK_i;

  RstSync : entity work.ResetSync
    port map (
      AsyncRst => AsyncRstN,
      Clk      => Clk50MHz,
      --
      Rst_N    => RstN
      );

  SccbM : entity work.SccbMaster
    generic map (
      ClkFreq => Freq
      )
    port map (
      Clk          => XCLK_i,
      Rst_N        => RstN,
      --
      DataFromSccb => open,
      --
      SIO_C        => SIO_C,
      SIO_D        => SIO_D
      );

  CaptPixel : entity work.VideoCapturer
    generic map (
      DataW => D'length
      )
    port map (
      RstN      => RstN,
      Clk       => Clk50MHz,
      --
      PixelOut  => PixelData,
      PixelVal  => PixelVal,
      --
      PRstN     => AsyncRstN,
      PClk      => XCLK_i, -- HACK: We use the internal raw 25 MHz clock for
                           -- now due to the bad quality of the incoming one.
      Vsync     => VSYNC,
      HREF      => HREF,
      PixelData => D,
      --
      Vsync_Clk => Vsync_Clk
      );

  PixelAlign : entity work.PixelAligner
    port map (
      Clk         => Clk50MHz,
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

  FChain : entity work.FilterChain
    generic map (
      DataW     => 8,
      CompDataW => 3
      )
    port map (
      Clk          => Clk50MHz,
      RstN         => RstN,
      --
      Vsync        => Vsync_Clk,
      ToggleMode   => '0',
      IncThreshold => '0',
      DecThreshold => '0',
      --
      PixelIn      => AlignedPixel,
      PixelInVal   => AlignedPixelVal,
      --
      PixelOut     => PixelCompData,
      PixelOutVal  => PixelCompVal
      );

  VideoPack : entity work.VideoPacker
    port map (
      Clk            => Clk50MHz,
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

  -- FIXME: This should be automagically padded
  PixelInData(15) <= '0';

  SramArb : entity work.SramArbiter
    port map (
      RstN      => RstN,
      Clk       => Clk50MHz,
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
      Clk     => Clk50MHz,
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
      Clk           => Clk50MHz,
      RstN          => RstN,
      --
      ReadSram      => PixelRead,
      SramAddr      => SramReadAddr,
      SramReqPopped => PixelReadPop,
      SramData      => PixelOutData,
      --
      InView        => VgaInView,
      PixelToDisp   => PixelToObjFind,
      PixelVal      => PixelToObjFindVal
      );

  ObjectFinder : entity work.ObjectFinder
    generic map (
      DataW => PixelResW
      )
    port map (
      RstN        => RstN,
      Clk         => Clk50MHz,
      --
      Vsync       => Vsync_Clk,
      --
      PixelIn     => PixelToObjFind,
      PixelInVal  => PixelToObjFindVal,
      --
      PixelOut    => PixelToVga,
      PixelOutVal => open,
      RectAct     => DrawRect,
      --
      TopLeft     => TopLeft,
      BottomRight => BottomRight
      );

  VgaGen : entity work.VgaGenerator
    generic map (
      DivideClk => false,
      DataW     => PixelResW,
      Offset    => 1
      )
    port map (
      Clk            => XCLK_i,
      RstN           => RstN,
      --
      PixelToDisplay => PixelToVga,
      DrawRect       => DrawRect,
      InView         => VgaInView,
      --
      Red            => VgaRed,
      Green          => VgaGreen,
      Blue           => VgaBlue,
      HSync          => VgaHsync,
      VSync          => VgaVsync
      );

  PWMCtrler : entity work.PWMCtrl
    port map (
      RstN        => RstN,
      Clk         => Clk50MHz,
      Clk64KHz    => Clk64kHz,
      --
      Btn1        => '0',
      Btn2        => '0',
      --
      TopLeft     => TopLeft,
      BottomRight => BottomRight,
      --
      YawPos      => YawPos,
      PitchPos    => PitchPos
      );

  Clk64kHzGen : entity work.ClkDiv
    generic map (
      SourceFreq => Freq,
      SinkFreq   => 32000
    )
    port map (
      Clk     => Clk50MHz,
      RstN    => RstN,
      Clk_out => Clk64khz
      );

  YawServoDriver : entity work.Servo_pwm
    generic map (
      ResW => ServoResW
      )
    port map (
      Clk   => Clk64Khz,
      RstN  => RstN,
      --
      Pos   => YawPos,
      --
      Servo => YawServo
      );

  PitchServoDriver : entity work.Servo_pwm
    generic map (
      ResW => ServoResW
      )
    port map (
      Clk   => Clk64Khz,
      RstN  => RstN,
      --
      Pos   => PitchPos,
      --
      Servo => PitchServo
      );

  Serial : block
    constant FifoSize : positive := 128;
    constant FifoSizeW : positive := bits(FifoSize);
    --
    signal Baud                                                 : word(3-1 downto 0);
    signal SerDataFromFifo                                      : word(8-1 downto 0);
    signal SerDataToFifo                                        : word(8-1 downto 0);
    signal SerDataRd, SerDataFifoEmpty, SerDataWr, SerWriteBusy : bit1;
    signal Busy                                                 : bit1;
    --
    signal IncSerChar                                           : word(8-1 downto 0);
    signal IncSerCharVal                                        : bit1;
    signal Level                                                : word(FifoSizeW-1 downto 0);
    signal MaxFillLevel_N, MaxFillLevel_D                       : word(FifoSizeW-1 downto 0);
    --
    
  begin
    Baud <= "010";
    
    SerRead : entity work.SerialReader
      generic map (
        DataW   => 8,
        ClkFreq => Clk50MHz_int
        )
      port map (
        Clk   => Clk50MHz,
        RstN  => RstN,
        --
        Rx    => SerialIn,
        --
        Baud  => Baud,
        --
        Dout  => IncSerChar,
        RxRdy => IncSerCharVal
        );
    
     SerCmdParser : entity work.SerialCmdParser
       port map (
         RstN           => RstN,
         Clk            => Clk50MHz,
         --
         IncSerChar     => IncSerChar,
         IncSerCharVal  => IncSerCharVal,
         --
         RegAccessOut   => RegAccess,
         RegAccessIn    => RegAccess,
         --
         OutSerCharBusy => Busy,
         OutSerChar     => SerDataToFifo,
         OutSerCharVal  => SerDataWr
         );

    --RegAccess.Val  <= RegAccessFromPS2.Val;
    --RegAccess.Data <= RegAccessFromPS2.Data;
    --RegAccess.Addr <= RegAccessFromPS2.Addr;
    --RegAccess.Cmd  <= RegAccessFromPS2.Cmd;
    
    SerOutFifo : entity work.SerialOutFifo
      port map (
        clock => Clk50MHz,
        data  => SerDataToFifo,
        wrreq => SerDataWr,
        full  => Busy,
        --
        usedw => Level,
        --
        rdreq => SerDataRd,
        q     => SerDataFromFifo,
        empty => SerDataFifoEmpty
        );
    SerDataRd <= '1' when SerDataFifoEmpty = '0' and SerWriteBusy = '0' else '0';

    SerWrite : entity work.SerialWriter
      generic map (
        ClkFreq => Clk50MHz_int
        )
      port map (
        Clk       => Clk50MHz,
        Rst_N     => RstN,
        --
        Baud      => Baud,
        --
        We        => SerDataRd,
        WData     => SerDataFromFifo,
        Busy      => SerWriteBusy,
        --
        SerialOut => SerialOut
        );
  end block;
  
end architecture rtl;
