library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity OV76X0 is 
	generic (
	Displays : positive := 8
	);
	port (
	AsyncRstN : in bit1;
	Clk      : in bit1;
	--
	PllClk : out bit1;
	-- Lcd Interface
	Display : out word(Displays-1 downto 0);
	Segments : out word(8-1 downto 0)
	);
end entity;

architecture rtl of OV76X0 is
	signal AsyncRst : bit1;
	signal LcdDisp : word(bits(10**Displays)-1 downto 0);
begin
	AsyncRst <= not AsyncRstN;

	Pll : entity work.Pll
	port map (
		areset => AsyncRst,
		inclk0 => Clk,
		c0 => PllClk
	);
	
	LcdDisp <= (others => '0');
	BcdDisp : entity work.BcdDisp
	generic map (
		Displays => 8,
	   Freq => 50000000
	)
	port map (
	Clk => Clk,
	--
	Data => LcdDisp,
	--
	Segments => Segments,
	Display  => Display
	);
	
end architecture rtl;