library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity ConvFilter is
  generic (
    DataW     : positive;
    CompDataW : positive;
    Res       : positive
    );
  port (
    Clk        : in  bit1;
    RstN      : in  bit1;
    --
    PixelInVal : in  bit1;
    PixelIn    : in  PixVec2D(Res-1 downto 0);
    --
    PixelOut   : out word(CompDataW-1 downto 0);
    PixelOutVal : out bit1
    );
end entity;

architecture rtl of ConvFilter is
  signal PixelOut_N, PixelOut_D       : word(DataW-1 downto 0);
  signal PixelOutVal_N, PixelOutVal_D : bit1;
begin
  -- FIXME: How to handle line delay of 2
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      PixelOut_D    <= (others => '0');
      PixelOutVal_D <= '0';
    elsif rising_edge(Clk) then
      PixelOut_D    <= PixelOut_N;
      PixelOutVal_D <= PixelOutVal_N;
    end if;
  end process;

  AsyncProc : process (PixelIn, PixelInVal, PixelOut_D)
  begin
    PixelOut_N <= PixelOut_D;
    
    -- Prewitt filter
    if PixelInVal = '1' then
      PixelOut_N    <= PixelIn(0)(1) + SHL(PixelIn(0)(2), "1") + PixelIn(1)(2) - PixelIn(1)(0) - SHL(PixelIn(2)(0), "1") - PixelIn(2)(1);
    end if;
    PixelOutVal_N <= PixelInVal;
  end process;

  -- Slice out the resolution we support
  PixelOut    <= PixelOut_D(DataW-1 downto DataW-CompDataW);
  PixelOutVal <= PixelOutVal_D;
end architecture rtl;
