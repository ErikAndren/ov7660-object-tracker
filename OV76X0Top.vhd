library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity OV76X0 is 
	generic (
	Freq : positive := 25000000;
	Displays : positive := 8
	);
	port (
	AsyncRstN : in bit1;
	Clk      : in bit1;
	--
	Button1 : in bit1;
	Button2 : in bit1;
	--
	VSYNC : in bit1;
	HREF : in bit1;
	--
	XCLK : out bit1;
	PCLK : in  bit1;
	D    : in  word(8-1 downto 0);
	-- Lcd Interface
	Display : out word(Displays-1 downto 0);
	Segments : out word(8-1 downto 0);
	-- SCCB interface
	SIO_C : out bit1;
	SIO_D : inout bit1;
	-- VGA interface
	VgaRed   : out bit1;
	VgaGreen : out bit1;
	VgaBlue  : out bit1;
	VgaHsync : out bit1;
	VgaVsync : out bit1;
	-- Sram interface
	SramD    : inout word(16-1 downto 0);
	SramAddr : out word(18-1 downto 0);
	SramCeN  : out bit1;
	SramOeN  : out bit1;
	SramWeN  : out bit1;
	SramUbN  : out bit1;
	SramLbN  : out bit1
	);
end entity;

architecture rtl of OV76X0 is
	signal LcdDisp : word(bits(10**Displays)-1 downto 0);
	signal Btn1Stab, Btn2Stab : bit1;
	signal SccbData, DispData : word(SccbDataW-1 downto 0);
	signal SccbRe   : bit1;
	signal SccbWe   : bit1;
	signal SccbAddr : word(SccbAddrW-1 downto 0);
	signal XCLK_i : bit1;
	signal RstN : bit1;
	signal RstNPClk : bit1;

	signal PixelData : word(8-1 downto 0);
	signal PixelVal : bit1;
	
	signal VgaContAddr : word(18-1 downto 0);
	signal PixelInData : word(16-1 downto 0);
	signal PixelOutData : word(16-1 downto 0);
	signal VgaContWe : bit1;
	signal VgaContRe : bit1;
	
	signal PixelCompData : word(3-1 downto 0);
	signal PixelCompVal : bit1;
	
	signal SramWriteReq : bit1;
	signal PixelPopWrite : bit1;
	signal PixelRead : bit1;
	signal PixelReadPop : bit1;
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
		Clk      => XCLK_i,
		--
		Rst_N    => RstN
	);
	
	DebBtn1 : entity work.Debounce
	port map (
		Clk => XCLK_i,
		x   => Button1,
		DBx => Btn1Stab
	);
	
	DebBtn12 : entity work.Debounce
	port map (
		Clk => XCLK_i,
		x   => Button2,
		DBx => Btn2Stab
	);

	BcdDisp : entity work.BcdDisp
	generic map (
		Displays => 8,
	   Freq => Freq
	)
	port map (
		Clk => XCLK_i,
		RstN => AsyncRstN,
		--
		Data => LcdDisp,
		--
		Segments => Segments,
		Display  => Display
	);
	
	--LcdDisp <= xt0(SccbData, LcdDisp'length);
	LcdDisp <= xt0(x"ADBEEF", LcdDisp'length);
	
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
	
	CaptPixel : entity work.VideoCapturer
	generic map (
		DataW => D'length
	)
	port map (
		RstN      => RstN,
		Clk       => XCLK_i,
		--
		PixelOut  => PixelData,
		PixelVal  => PixelVal,
		--
		PRstN     => AsyncRstN,
		PClk      => PCLK,
		Vsync     => VSYNC,
		HREF      => HREF,
		PixelData => D
	);

	VideoComp : entity work.VideoCompressor
	port map (
		Clk       => XCLK_i,
		RstN      => RstN,
		--
		PixelData => PixelData,
		PixelVal  => PixelVal,
		--
		PixelCompData => PixelCompData,
		PixelCompVal  => PixelCompVal
	);
	
	VideoPack : entity work.VideoPacker
	port map (
		Clk            => XCLK_i,
		RstN           => RstN,
		--
		PixelComp      => PixelCompData,
		PixelCompVal   => PixelCompVal,
		--
		PixelPacked    => PixelInData(15-1 downto 0),
		PixelPackedVal => SramWriteReq,
		--
		PopPixelPack   => PixelPopWrite);
		PixelInData(15) <= '0';
		
	SramArb : entity work.SramArbiter
	port map (
		RstN => RstN,
		Clk  => XCLK_i,
		--
		WriteReq => PixelCompVal,
		PopWrite => PixelPopWrite,
		--
		ReadReq => PixelRead,
		PopRead => PixelReadPop,
		--
		SramWe =>  VgaContWe,
		SramRe =>  VgaContRe
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
		Clk    => XCLK_i, -- FIXME: Higher clock will improve performance
		RstN   => RstN,
		AddrIn => VgaContAddr,
		WrData => PixelInData,
		RdData => PixelOutData,
		We     => VgaContWe,
		Re     => VgaContRe,
		--
		D       => SramD,
		AddrOut => SramAddr,
		CeN     => SramCeN,
		OeN     => SramOeN,
		WeN     => SramWeN,
		UbN     => SramUbN,
		LbN     => SramLbN
	);
	
	VgaGen : entity work.VgaGenerator
	generic map (
		DivideClk => false
	)
	port map (
		Clk   => XCLK_i,
		--
		DataToDisplay => PixelData(3-1 downto 0),
		--
		Red   => VgaRed,
		Green => VgaGreen,
		Blue  => VgaBlue,
		HSync => VgaHsync,
		VSync => VgaVsync
	);
end architecture rtl;