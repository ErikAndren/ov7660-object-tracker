library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity SpatialAverager is
  generic (
    DataW : positive
    );
  port (
    RstN          : in  bit1;
    Clk           : in  bit1;
    --
    Vsync         : in  bit1;
    --
    PixelInVal    : in  bit1;
    PixelIn       : in  word(DataW-1 downto 0);
    --
    SramAddr      : out word(SramAddrW-1 downto 0);
    SramReq       : out bit1;
    SramWe        : out bit1;
    SramRe        : out bit1;
    --
    PopWrite      : in  bit1;
    PopRead       : in  bit1;
    PixelFromSram : in  word(DataW-1 downto 0);
    PixelToSram   : out word(DataW-1 downto 0)
    );
end entity;

architecture rtl of SpatialAverager is
  signal LineCnt_N, LineCnt_D                   : word(FrameHW-1 downto 0);
  signal PixelCnt_N, PixelCnt_D                 : word(FrameWW-1 downto 0);
  signal PixelFromSram_N, PixelFromSram_D       : word(DataW-1 downto 0);
  signal PixelToSram_N, PixelToSram_D           : word(DataW-1 downto 0);
  signal SramWe_N, SramWe_D, SramRe_N, SramRe_D : bit1;
begin
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      LineCnt_D       <= (others => '0');
      PixelCnt_D      <= (others => '0');
      PixelFromSram_D <= (others => '0');
      PixelToSram_D   <= (others => '0');
      SramWe_D        <= '0';
      SramRe_D        <= '0';
    elsif rising_edge(Clk) then
      LineCnt_D       <= LineCnt_N;
      PixelCnt_D      <= PixelCnt_N;
      PixelFromSram_D <= PixelFromSram_N;
      PixelToSram_D   <= PixelToSram_N;
      SramWe_D        <= SramWe_N;
      SramRe_D        <= SramRe_N;      

      if Vsync = '1' then
        LineCnt_D       <= (others => '0');
        PixelCnt_D      <= (others => '0');
        PixelFromSram_D <= (others => '0');
        PixelToSram_D   <= (others => '0');
        SramRe_D        <= '0';
        SramWe_D        <= '0';
      end if;
    end if;
  end process;
  
  ASyncProc : process (LineCnt_D, PixelCnt_D, PixelInVal, SramRe_D, SramWe_D, PixelIn, PixelFromSram, PopRead, PixelFromSram_D)
    variable Avg : word(DataW downto 0);
  begin
    LineCnt_N <= LineCnt_D;
    PixelCnt_N <= PixelCnt_D;

    SramRe_N <= SramRe_D;
    if PopRead = '1' then
      SramRe_N <= '0';
      PixelFromSram_N <= PixelFromSram;
    end if;

    SramWe_N <= SramWe_D;
    if PopWrite = '1' then
      SramWe_N <= '0';
    end if;

    if PixelInVal = '1' then
      PixelCnt_N <= PixelCnt_D + 1;
      if PixelCnt_D + 1 = FrameW then
        PixelCnt_N <= (others => '0');
        LineCnt_N <= LineCnt_D + 1;
        if LineCnt_D + 1 = FrameH then
          LineCnt_N <= (others => '0');
        end if;
      end if;

      -- Perform delta calculation
      --  newAvg = oldAvg - oldAvg>>2 + newColor>>2.
      Avg         := (PixelFromSram - PixelFromSram(PixelFromSram'high downto 2)) + PixelIn;
      PixelToSram <= Avg(PixelToSram'high downto 0);
      SramWe_N <= '1';
      SramRe_N <= '1';
    end if;
  end process;
  
  SramAddr <= xt0(LineCnt_D & PixelCnt_D, SramAddr'length);


end architecture rtl;
