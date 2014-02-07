library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity SramArbiter is 
	port (
	RstN     : in bit1;
	Clk      : in bit1;
	--
	WriteReq : in bit1;
	WriteAddr : in word(SramAddrW-1 downto 0);
	PopWrite : out bit1;
	--
	ReadReq : in bit1;
	ReadAddr : in word(SramAddrW-1 downto 0);
	PopRead : out bit1;
	--
	SramAddr : out word(SramAddrW-1 downto 0);
	SramWe : out bit1;
	SramRe : out bit1
	);
end entity;

architecture rtl of SramArbiter is
	constant SramWaitPenalty : natural := 1;
	
	signal WaitCnt_N, WaitCnt_D : word(1-1 downto 0);
	signal PopRead_N, PopRead_D : bit1;
	signal PopWrite_N, PopWrite_D : bit1;
begin
	ArbiterSync : process (Clk, RstN)
	begin
		if RstN = '0' then
			WaitCnt_D  <= (others => '0');
			PopWrite_D <= '0';
			PopRead_D  <= '0';
		elsif rising_edge(Clk) then
			WaitCnt_D  <= WaitCnt_N;
			PopWrite_D <= PopWrite_N;
			PopRead_D  <= PopRead_N;
		end if;
	end process;
	
	ArbiterAsync : process (WaitCnt_D, WriteReq, ReadReq, ReadAddr, WriteAddr)
	begin
		SramWe      <= '0';
		SramRe      <= '0';
		WaitCnt_N   <= WaitCnt_D;
		PopRead_N   <= '0';
		PopWrite_N  <= '0';
		SramAddr    <= (others => 'X');

		if (WaitCnt_D > 0) then
			WaitCnt_N <= WaitCnt_D - 1;
		else
			if (ReadReq = '1') then
					PopRead_N <= '1';
					SramRe    <= '1';
					SramAddr  <= ReadAddr;
					WaitCnt_N <= conv_word(SramWaitPenalty, WaitCnt_N'length);
			elsif (WriteReq = '1') then
					PopWrite_N <= '1';
					SramWe     <= '1';
					SramAddr    <= WriteAddr;
					WaitCnt_N <= conv_word(SramWaitPenalty, WaitCnt_N'length);
			end if;
		end if;
	end process;
	
	PopRead  <= PopRead_D;
	PopWrite <= PopWrite_D;
end architecture rtl;
