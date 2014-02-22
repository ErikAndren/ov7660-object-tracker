-- This component tries to filter out the noise generated y the OV7660 camera

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity OV76X0Filter is 
	port (
          Rst_N    : in bit1;
          Clk      : in bit1;
          --
          Href     : in bit1;
          VSync    : in bit1;
          --
          HrefFiltered  : out bit1;
          VsyncFiltered : out bit1
	);
end entity;

architecture rtl of OV76X0Filter is
  -- Assuming YUV/RGB
  constant tP : positive := 2;
  constant VSyncLines : positive := 510;
  constant VSyncLinesW : positive := bits(VSyncLines);
  constant VSyncThreshold : positive := 10;
  constant VSyncThresholdW : positive := bits(VSyncThreshold);
  constant VSyncLineLen : positive := 4;

  constant HRefPreamble : positive := VSyncLineLen + 11;
  constant HRefPostamble : positive := 15;
  constant HRefValPixels : positive := 640 * tP;

  constant ClksPerLine : positive := 784 * tP;
  constant ClksPerLineW : positive := bits(ClksPerLine);

  signal VSyncDetect_N, VSyncDetect_D : word(VSyncThresholdW-1 downto 0);
  signal StartLocVSync : bit1;
  signal StartLocVSync_D : bit1;

  signal PixelCnt_N, PixelCnt_D : word(ClksPerLineW-1 downto 0);
  signal LineCnt_N, LineCnt_D : word(VSyncLinesW-1 downto 0);
                                       
begin
  SyncProc : process (Clk, Rst_N)
  begin
    if Rst_N = '0' then
      VSyncDetect_D <= (others => '0');
      PixelCnt_D    <= (others => '0');
      LineCnt_D     <= (others => '0');

    elsif rising_edge(Clk) then
      VSyncDetect_D <= VSyncDetect_N;
      PixelCnt_D    <= PixelCnt_N;
      LineCnt_D     <= LineCnt_N;
    end if;
  end process;

  ASyncProc : process (VSyncDetect_D, VSync, StartLocVSync)
  begin
    VSyncDetect_N   <= (others => '0');
    PixelCnt_N      <= PixelCnt_D + 1;
    LineCnt_N       <= LineCnt_D;
    StartLocVSync_D <= StartLocVSync;

    if VSync = '1' then
      if VSyncDetect_D < VSyncThreshold then
        VSyncDetect_N <= VSyncDetect_D + 1;
      else
        VSyncDetect_N <= VSyncDetect_D;        
      end if;
    end if;

    if PixelCnt_D = ClksPerLine-1 then
      PixelCnt_N <= (others => '0');
      LineCnt_N <= LineCnt_D + 1;
    end if;

    if (StartLocVSync = '1') then
       PixelCnt_N <= conv_word(VsyncThreshold, PixelCnt_N'length);
       LineCnt_N  <= (others => '0');
    end if;
  end process;
--  StartLocVSync <= '1' when VsyncDetect_D = VSyncThreshold and StartLocVSync_D = '0' else '0';
  StartLocVSync <= '0';

  VSyncFiltered <= '1' when LineCnt_D < VSyncLineLen else '0';
  HRefFiltered <= '1'  when
                  LineCnt_D >= HRefPreamble and
                  LineCnt_D < VSyncLines - HrefPostamble and
                  PixelCnt_D < HRefValPixels else '0';
end architecture rtl;
