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
		NextInst         : in bit1;
		--
		We           : out bit1;
		Start        : out bit1;
		AddrData     : out word(16-1 downto 0)
	);
end entity;	

architecture fpga of OV7660Init is
	constant NbrOfInst : positive := 1;
	signal InstPtr_N, InstPtr_D : word(bits(NbrOfInst)-1 downto 0);
	signal Delay_N, Delay_D : word(16-1 downto 0);
begin	
	SyncProc : process (Clk, Rst_N)
	begin
		if Rst_N = '0' then
			InstPtr_D <= (others => '0');
			Delay_D   <= (others => '0');
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
			when "0" =>
				AddrData <= x"0911";
				We       <= '1';
				Start    <= '1';

			when others =>
				InstPtr_N <= (others => '1');
				Start     <= '0';
			
			end case;
		end if;
	end process;
	
end architecture;
