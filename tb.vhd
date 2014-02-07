library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity Tb is
end entity;

architecture test of Tb is 
	signal RstN : bit1;
	signal Clk : bit1;

	constant Clk50Period : time := 20 ns;
begin
	ClkGen : process 
	begin
		while true loop
			Clk <= '0';
			wait for Clk50Period / 2;
			Clk <= '1';
			wait for Clk50Period / 2;
		end loop;
	end process;
	
	RstN <= '0', '1' after 200 ns;

	DUT : entity work.OV76X0
	port map (
		AsyncRstN => RstN,
		Clk => Clk,
		--
		Button1 => '1',
		Button2 => '1',
		--
		VSYNC => '0',
		HREF  => '0',
		--
		PllClk => open,
		--
		Display => open,
		Segments => open,
		--
		SIO_C => open,
		SIO_D => open
	);


end architecture;