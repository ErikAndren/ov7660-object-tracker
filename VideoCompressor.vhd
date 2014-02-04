library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VideoCompressor is
	generic (
		PixelW : positive := 8;
		CompPixelW : positive := 3
	);
	port (
	Clk      : in bit1;
	Rst_N    : in bit1;
	--
	PixelData : in word(PixelW-1 downto 0);
	PixelVal  : in bit1;
	--
	PixelCompData : out word(CompPixelW-1 downto 0);
	PixelCompVal  : out bit1
	);
end entity;

architecture rtl of VideoCompressor is
	signal DrpCnt_N, DrpCnt_D : word(1-1 downto 0);
begin
	-- Compress data according to usage and resolution
	-- First stab will simply compress the 8 bit luminance
	SyncProc : process (Clk, Rst_N)
	begin
		if Rst_N = '0' then
			DrpCnt_D <= (others => '0');
		elsif rising_edge(Clk) then
			DrpCnt_D <= DrpCnt_N;
		end if;
	end process;
	
	AsyncProc : process (DrpCnt_D, PixelVal, PixelData)
	begin
		DrpCnt_N <= DrpCnt_D;
		PixelCompVal <= '0';
		PixelCompData <= (others => '0');
		
		if PixelVal = '1' then
			DrpCnt_N <= DrpCnt_D + 1;
			
			-- Luminance is sent on every other byte, offset by one
			if (DrpCnt_D = 1) then
				PixelCompVal <= '1';
				-- This can be much improved by dithering etc.
				-- Should evaluate to shift, might need to be written
				PixelCompData <= PixelData(PixelData'length-1 downto PixelData'length-CompPixelW);
			end if;
		end if;
	end process;
	
end architecture rtl;
