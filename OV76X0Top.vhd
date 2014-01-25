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
	PllClk : out bit1;
	-- Lcd Interface
	Display : out word(Displays-1 downto 0);
	Segments : out word(8-1 downto 0);
	-- SCCB interface
	SIO_C : out bit1;
	SIO_D : inout bit1
	);
end entity;

architecture rtl of OV76X0 is
	constant SccbAddrW : positive := 8;
	constant SccbDataW : positive := 8;

	signal AsyncRst : bit1;
	signal LcdDisp : word(bits(10**Displays)-1 downto 0);
	signal Btn1Stab, Btn2Stab : bit1;
	signal SccbData, DispData : word(SccbDataW-1 downto 0);
	signal SccbRe   : bit1;
	signal SccbWe   : bit1;
	signal SccbAddr : word(SccbAddrW-1 downto 0);
	signal PllClk_i : bit1;

begin
	AsyncRst <= not AsyncRstN;

	Pll : entity work.Pll
	port map (
		areset => AsyncRst,
		inclk0 => Clk,
		c0 => PllClk_i
	);
	PllClk <= PllClk_i;
	
	DebBtn1 : entity work.Debounce
	port map (
		Clk => PllClk_i,
		x   => Button1,
		DBx => Btn1Stab
	);
	
	DebBtn12 : entity work.Debounce
	port map (
		Clk => PllClk_i,
		x   => Button2,
		DBx => Btn2Stab
	);

	BcdDisp : entity work.BcdDisp
	generic map (
		Displays => 8,
	   Freq => Freq
	)
	port map (
	Clk => PllClk_i,
	--
	Data => LcdDisp,
	--
	Segments => Segments,
	Display  => Display
	);
	
	--LcdDisp <= xt0(SccbData, LcdDisp'length);
	LcdDisp <= xt0(SccbAddr, LcdDisp'length);
	
	SccbM : entity work.SccbMaster
	generic map (
		ClkFreq => Freq
	)
	port map (
		Clk          => PllClk_i,
		Rst_N        => AsyncRstN,
		--
		Addr         => SccbAddr,
		We           => SccbWe,
		Re           => SccbRe,
		Data         => SccbData,
		DataFromSccb => DispData,
		Valid        => open,
		--
		SIO_C        => SIO_C,
		SIO_D        => SIO_D
	);
	
	SccbReader : entity work.SccbAddrReader
	port map (
		Clk => PllClk_i,
		RstN => ASyncRstN,
		--
		Addr => SccbAddr,
		Re   => SccbRe,
		We   => SccbWe,
		Data => SccbData,
		--
		IncAddr => Btn2Stab,
		DecAddr => Btn1Stab
	);
	
end architecture rtl;