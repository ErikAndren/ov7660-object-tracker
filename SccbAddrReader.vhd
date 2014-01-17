library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SccbAddrReader is 
	generic (
		DataW : positive := 8;
		AddrW : positive := 7;
		-- 
		ClkFreq : positive := 25000000
	);	
	port (
		RstN : in bit1;
		Clk  : in bit1;
		--
		IncAddr : in bit1;
		DecAddr : in bit1;
		--
		Addr : out word(AddrW-1 downto 0);
		Re   : out bit1
	);
end entity;

architecture rtl of SccbAddrReader is
	signal Addr_N, Addr_D : word(AddrW-1 downto 0);
begin
	SyncProc : process (RstN, Clk)
	begin
		if RstN = '0' then
			Addr_D <= (others => '0');
		elsif rising_edge(Clk) then
			Addr_D <= Addr_N;
		end if;
	end process;
	
	AsyncProc : process (IncAddr, DecAddr, Addr_D)
	begin
		Addr_N <= Addr_D;
		Re <= '0';
		if IncAddr = '1' then
			Addr_N <= Addr_D + 1;
			Re <= '1';
		elsif DecAddr = '1' then
			Addr_N <= Addr_D - 1;
			Re <= '1';
		end if;
	end process;
	Addr <= Addr_N;
end architecture rtl;