library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SramArbiter is 
	port (
	RstN : in bit1;
	Clk      : in bit1;
	--
	WriteReq : in bit1;
	PopWrite : out bit1;
	ReadReq : in bit1;
	PopRead : out bit1;
	--
	SramWe : out bit1;
	SramRe : out bit1
	);
end entity;

architecture rtl of SramArbiter is
	constant SramWaitPenalty : natural := 1;
	
	signal WaitCnt_N, WaitCnt_D : word(1-1 downto 0);
begin
	ArbiterSync : process (Clk, RstN)
	begin
		if RstN = '0' then
			WaitCnt_D <= (others => '0');
		elsif rising_edge(Clk) then
			WaitCnt_D <= WaitCnt_N;
		end if;
	end process;
	
	ArbiterAsync : process (WaitCnt_D, WriteReq, ReadReq)
	begin
		SramWe    <= '0';
		SramRe    <= '0';
		WaitCnt_N <= WaitCnt_D;
		PopRead   <= '0';
		PopWrite  <= '0';
		
		if (WaitCnt_D > 0) then
			WaitCnt_N <= WaitCnt_D - 1;
		else
			if (ReadReq = '1') then
					PopRead <= '1';
					SramRe <= '1';
					WaitCnt_N <= conv_word(SramWaitPenalty, WaitCnt_N'length);
			elsif (WriteReq = '1') then
					PopWrite <= '1';
					SramWe <= '1';
					WaitCnt_N <= conv_word(SramWaitPenalty, WaitCnt_N'length);
			end if;
		end if;
	end process;
end architecture rtl;
