
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity tb is
end entity;

architecture rtl of tb is
	signal RstN : bit1;
	signal Clk50 : bit1;
	
	signal XCLK, PCLK : bit1;
	signal D : word(8-1 downto 0);
	signal VSYNC, HREF : bit1;
	
	signal SramD : word(16-1 downto 0);
	
begin
	RstN <= '0', '1' after 100 ns;
	
	ClkGen : process 
	begin
		while true loop 
			Clk50 <= '0';
			wait for 10 ns;
			Clk50 <= '1';
			wait for 10 ns;
		end loop;
	end process;
	
	VgaCamGen : entity work.VgaGenerator
	generic map (
		DivideClk => false
	)
	port map (
		Clk => XCLK,
		RstN => RstN,
		DataToDisplay => "101",
		InView => HREF,
		Red => D(7),
		Green => D(6),
		Blue => D(5),
		Hsync => open,
		Vsync => VSYNC
	);
	D(4 downto 0) <= (others => '0');
	
	DUT : entity work.OV76X0
	port map (
		AsyncRstN => RstN,
		Clk => Clk50,
		--
		Button1 => '1',
		Button2 => '1',
		--
		VSYNC => VSYNC,
		HREF  => HREF,
		--
		XCLK => XCLK,
		PCLK => XCLK, 
		D    => D,
		--
		Display => open,
		Segments => open,
		--
		SIO_C => open,
		SIO_D => open,
		--
		VgaRed => open,
		VgaGreen => open,
		VgaBlue => open,
		VgaHsync => open,
		VgaVsync => open,
		--
		SramD => SramD,
		SramAddr => open,
		SramCeN  => open,
		SramOeN  => open,
		SramWeN  => open,   
		SramUbN  => open,
		SramLbN => open
	);
	
	SramD <= (others => 'Z');
	SramD <= "1111000011110000";
	
end architecture;
