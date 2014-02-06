library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VideoPacker is
	generic (
		CompPixelW : positive := 3;
		PackedPixelW : positive := 15
	);
	port (
	Clk      : in bit1;
	RstN    : in bit1;
	--
	PixelComp : in word(CompPixelW-1 downto 0);
	PixelCompVal : in bit1;
	--
	PixelPacked : out word(PackedPixelW-1 downto 0);
	PixelPackedVal : out bit1;
	--
	PopPixelPack : in bit1
	);
end entity;

architecture rtl of VideoPacker is
	constant NbrSegs : positive := PackedPixelW / CompPixelW;
	constant NbrBufs : positive := 2;
	type PackedPixels is array (NbrBufs-1 downto 0) of word(PackedPixelW-1 downto 0);
	type PackCntPixels is array (NbrBufs-1 downto 0) of word(bits(NbrSegs)-1 downto 0);

	signal PackCnt_N, PackCnt_D : PackCntPixels;
	signal WriteBufPtr_N, WriteBufPtr_D : word(bits(NbrBufs)-1 downto 0);
	signal ReadBufPtr_N, ReadBufPtr_D : word(bits(NbrBufs)-1 downto 0);
	
	signal PackedData_N, PackedData_D : PackedPixels;
begin
	SyncProc : process (Clk, RstN)
	begin
		if RstN = '0' then
			PackCnt_D <= (others => (others => '0'));
			PackedData_D <= (others => (others => '0'));
			WriteBufPtr_D <= (others => '0');
			ReadBufPtr_D <= (others => '0');
		
		elsif rising_edge(Clk) then
			PackCnt_D         <= PackCnt_N;
			PackedData_D      <= PackedData_N;
			WriteBufPtr_D     <= WriteBufPtr_N;
			ReadBufPtr_D      <= ReadBufPtr_N;
		end if;
	end process;
	
	AsyncProc : process (PackedData_D, PackCnt_D, PixelCompVal, WriteBufPtr_D, ReadBufPtr_D, PopPixelPack, PixelComp)
		variable WriteBufPtr : integer;
	begin
		PackedData_N  <= PackedData_D;
		PackCnt_N     <= PackCnt_D;
		WriteBufPtr_N <= WriteBufPtr_D;
		ReadBufPtr_N  <= ReadBufPtr_D;
		WriteBufPtr   := conv_integer(WriteBufPtr_D);
		
		if PixelCompVal = '1' then
			-- Shift up the data
			PackedData_N(WriteBufPtr) <= PackedData_D(WriteBufPtr)(PackedData_D'high-CompPixelW downto 0) & PixelComp;
			PackCnt_N(WriteBufPtr)    <= PackCnt_D(WriteBufPtr) + 1;
			
			if (PackCnt_D(WriteBufPtr + 1) = NbrSegs) then 
				WriteBufPtr_N <= WriteBufPtr_D + 1;
			end if;
		end if;
		
		if PopPixelPack = '1' then
			ReadBufPtr_N <= ReadBufPtr_D + 1;
			PackCnt_N(conv_integer(ReadBufPtr_D)) <= (others => '0');
		end if;
	end process;

	PixelPackedVal <= '1' when PackCnt_D(conv_integer(ReadBufPtr_D)) = NbrSegs else '0'; 
	PixelPacked <= PackedData_D(conv_integer(ReadBufPtr_D));

end architecture rtl;
