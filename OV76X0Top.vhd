library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

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
	VgaVsync : out bit1
	);
end entity;

architecture rtl of OV76X0 is
	constant SccbAddrW : positive := 8;
	constant SccbDataW : positive := 8;

	signal LcdDisp : word(bits(10**Displays)-1 downto 0);
	signal Btn1Stab, Btn2Stab : bit1;
	signal SccbData, DispData : word(SccbDataW-1 downto 0);
	signal SccbRe   : bit1;
	signal SccbWe   : bit1;
	signal SccbAddr : word(SccbAddrW-1 downto 0);
	signal XCLK_i : bit1;
	signal RstN : bit1;
	signal RstNPClk : bit1;

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
		RstN  => RstN,
		Clk   => XCLK_i,
		--
		PRstN => AsyncRstN,
		PClk  => PCLK,
		Vsync => VSYNC,
		HREF  => HREF,
		PixelData => D
	);
	
	VgaGen : entity work.VgaVhdl
	generic map (
		DivideClk => false
	)
	port map (
		Clk   => XCLK_i,
		--
		Red   => VgaRed,
		Green => VgaGreen,
		Blue  => VgaBlue,
		HSync => VgaHsync,
		VSync => VgaVsync
	);
	

	-- 262144 words
	-- Each image is 640x480 = 307200 pixels
	-- Currently we have 3 bits of display (R, G, B)
	-- Each image then contains 307200 * 3 = 921600 bits
	-- That is 57600 words
	-- Up to 4 images may be stored with this encoding.
	-- If 2 frames are needed, each image may consume 6 bits per pixel
	-- This might 
--	SramCon : entity work.SramController
--	generic map (
--		
--	);
--	generic map (
--		AddrW : positive := 18;
--		DataW : positive := 16
--	);
--	port (
--		Clk    : in bit1;
--		RstN   : in bit1;
--		AddrIn : in word(AddrW-1 downto 0);
--		WrData : in word(DataW-1 downto 0);
--		RdData : out word(DataW-1 downto 0);
--		We     : in bit1;
--		Re     : in bit1;
--		--
--		D       : inout word(DataW-1 downto 0);
--		AddrOut : out word(AddrW-1 downto 0);
--		CeN     : out bit1;
--		OeN     : out bit1;
--		WeN     : out bit1;
--		UbN     : out bit1;
--		LbN     : out bit1
--	);
	
end architecture rtl;