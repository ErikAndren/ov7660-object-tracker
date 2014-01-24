library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SccbAddrReader is 
	generic (
		DataW : positive := 8;
		AddrW : positive := 8;
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
		Data : out word(DataW-1 downto 0);
		Re   : out bit1;
		We   : out bit1
	);
end entity;

architecture rtl of SccbAddrReader is
	signal Addr_N, Addr_D : word(AddrW-1 downto 0);
	signal Data_N, Data_D : word(DataW-1 downto 0);
	signal LastInc_N, LastInc_D : bit1;
	signal LastDec_N, LastDec_D : bit1;
	signal ThresHld_N, ThresHld_D : word(10-1 downto 0);
begin
	SyncProc : process (RstN, Clk)
	begin
		if RstN = '0' then
			Addr_D <= (others => '0');
			Data_D <= (others => '0');
			LastInc_D <= '1';
			LastDec_D <= '1';
			ThresHld_D <= (others => '0');
		elsif rising_edge(Clk) then
			Addr_D <= Addr_N;
			Data_D <= Data_N;
			LastInc_D <= LastInc_N;
			LastDec_D <= LastDec_N;
			ThresHld_D <= ThresHld_N;
		end if;
	end process;
	
	AsyncProc : process (IncAddr, DecAddr, Addr_D, Data_D, LastInc_D, LastDec_D, ThresHld_D)
	begin
		Addr_N <= Addr_D;
		Data_N <= Data_D;
		LastInc_N <= IncAddr;
		LastDec_N <= DecAddr;
		Re <= '0';
		ThresHld_N <= ThresHld_D;
		We <= '0';

		if IncAddr = '0' and LastInc_D = '1' then
			--Addr_N <= Addr_D + 1;
			Addr_N <= "00001001"; -- COM2
			Data_N   <= "00000101"; -- Soft sleep, output drive
			--Re <= '1';
			We <= '1';
		elsif DecAddr = '0' and LastDec_D = '1' then
			Addr_N <= Addr_D - 1;
			Re <= '1';
		end if;
		
		if (RedAnd(ThresHld_D) = '0') then
			-- Do not trigger an operation in the beginning.
			Re <= '0';
			We <= '0';
			Addr_N <= Addr_D;
			Data_N <= Data_D;
			ThresHld_N <= ThresHld_D + 1;
		end if;

	end process;
	Addr <= Addr_N;
	Data <= Data_N;
end architecture rtl;