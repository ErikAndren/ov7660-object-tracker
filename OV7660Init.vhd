library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity OV7660Init is
	port (
		Clk          : in bit1;
		Rst_N        : in bit1;
		--
		NextInst     : in bit1;
		--
		We           : out bit1;
		Start        : out bit1;
		AddrData     : out word(16-1 downto 0)
	);
end entity;	

architecture fpga of OV7660Init is
	constant COM2 : word(8-1 downto 0) := x"09";
	constant TSLB : word(8-1 downto 0) := x"3a";
	constant MANU : word(8-1 downto 0) := x"67";
	constant MANV : word(8-1 downto 0) := x"68";
	
	constant NbrOfInst : positive := 1;
	
	signal InstPtr_N, InstPtr_D : word(4-1 downto 0);
	signal Delay_N, Delay_D : word(16-1 downto 0);
begin	
	SyncProc : process (Clk, Rst_N)
	begin
		if Rst_N = '0' then
			InstPtr_D <= (others => '0');
			
			if Simulation then
				Delay_D   <= "1111111111111100";
			end if;
				
			if Synthesis then
				Delay_D <= (others => '0');
			end if;
		elsif rising_edge(Clk) then
			InstPtr_D <= InstPtr_N;
			Delay_D <= Delay_N;
		end if;
	end process;
	
	ASyncProc : process  (InstPtr_D, NextInst, Delay_D)
	begin
		InstPtr_N <= InstPtr_D;
		AddrData <= (others => '0');
		We <= '0';
		Start <= '0';
		Delay_N <= Delay_D + 1;
		if (RedAnd(Delay_D) = '1') then
			Delay_N <= Delay_D;
		
			if (NextInst = '1') then
				InstPtr_N <= InstPtr_D + 1;
			end if;
		
			case InstPtr_D is
--			when "0000" =>
--				AddrData <= TSLB & x"1C"; -- enable line buffer test option
--				We       <= '1';
--				Start    <= '1';

--			when "0000" =>
--				AddrData <= COM2 & x"11"; -- enable soft sleep
--				We       <= '1';
--				Start    <= '1';

			when others =>
				InstPtr_N <= (others => '1');
				Start     <= '0';
			
			end case;
		end if;
	end process;
	
end architecture;
