library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity PrewittFilter is
  generic (
    DataW     : positive := 8;
    CompDataW : positive := 3
    );
  port (
    RstN        : in  bit1;
    Clk         : in  bit1;
    --
    Vsync       : in  bit1;
    --
    PixelIn     : in  word(DataW-1 downto 0);
    PixelInVal  : in  bit1;
    --
    PixelOutVal : out bit1;
    PixelOut    : out word(CompDataW-1 downto 0)
    );
end entity;

architecture rtl of PrewittFilter is
  signal PixelCnt_D, PixelCnt_N : word(bits(FrameW)-1 downto 0);
  signal LineCnt_D, LineCnt_N : word(bits(FrameH)-1 downto 0);
  
begin
  SyncProc : process (RstN, Clk)
  begin
    if RstN = '0' then
      PixelCnt_D <= (others => '0');
      LineCnt_D <= (others => '0');
    elsif rising_edge(Clk) then
      PixelCnt_D <= PixelCnt_N;
      LineCnt_D <= LineCnt_N;
    end if;
  end process;

  AsyncProc : process (PixelCnt_D, LineCnt_D, PixelInVal, Vsync)
  begin
    PixelCnt_N <= PixelCnt_D;
    LineCnt_N <= LineCnt_D;

    if (PixelInVal = '1') then
      PixelCnt_N <= PixelCnt_D + 1;
      if (PixelCnt_D = FrameW-1) then
        PixelCnt_N <= (others => '0');
        LineCnt_N <= LineCnt_D + 1;
        if (LineCnt_D = FrameH-1) then
          LineCnt_D <= (others => '0');
        end if;
      end if;
    end if;

    if (Vsync = '1') then
      PixelCnt_N <= (others => '0');
      LineCnt_N  <= (others => '0');
    end if;
  end process;
  
end architecture rtl;
