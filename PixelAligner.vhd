-- Extract the different types of signals in the incoming data stream.
-- Current implementation extracts the luminance from the incoming YUV encoded
-- signal.
-- Copyright Erik Zachrisson, erik@zachrisson.info 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity PixelAligner is
  generic (
    DataInW  : positive := 8;
    DataOutW : positive := 8
    );
  port (
    RstN        : in  bit1;
    Clk         : in  bit1;
    --
    Vsync       : in  bit1;
    PixelInVal  : in  bit1;
    PixelIn     : in  word(DataInW-1 downto 0);
    --
    PixelOutVal : out bit1;
    PixelOut    : out word(DataOutW-1 downto 0)
    );
end entity;

architecture rtl of PixelAligner is
  signal Cnt_N, Cnt_D                 : word(1-1 downto 0);
begin
  SyncProc : process (RstN, Clk)
  begin
    if RstN = '0' then
      Cnt_D         <= (others => '0');
    elsif rising_edge(Clk) then
      Cnt_D         <= Cnt_N;
    end if;
  end process;

  AsyncProc : process (Cnt_D, Vsync, PixelInVal)
  begin
    Cnt_N         <= Cnt_D;
    PixelOutVal   <= '0';

    if PixelInVal = '1' then
      Cnt_N <= Cnt_D + 1;

      -- YUV sample black and white on second cycle
      if (Cnt_D = 0) then
        PixelOutVal <= '1';
      end if;
    end if;

    if Vsync = '1' then
      Cnt_N <= (others => '0');
    end if;
  end process;

  PixelOutFeed : PixelOut    <= PixelIn;
end architecture rtl;
