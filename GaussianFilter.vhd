--
-- Implements gaussian filter
-- 1 2 1
-- 2 4 2 * 1/16
-- 1 2 1
--
-- Copyright Erik Zachrisson - erik@zachrisson.info

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.Types.all;
use work.OV76X0Pack.all;

entity GaussianFilter is
  generic (
    DataW : in positive;
    Res   : in positive
    );
  port (
    Clk         : in  bit1;
    RstN        : in  bit1;
    --
    PixelIn     : in  PixVec2d(Res-1 downto 0);
    PixelInVal  : in  bit1;
    --
    PixelOut    : out word(DataW-1 downto 0);
    PixelOutVal : out bit1
    );
end entity;

architecture rtl of GaussianFilter is
  constant Threshold                  : natural := 255;
  signal PixelOut_N, PixelOut_D       : word(DataW-1 downto 0);
  signal PixelOutVal_N, PixelOutVal_D : bit1;
begin
  SyncRstProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      PixelOutVal_D <= '0';
    elsif rising_edge(Clk) then
      PixelOutVal_D <= PixelOutVal_N;
    end if;
  end process;

  SyncNoRstProc : process (Clk)
  begin
    if rising_edge(Clk) then
      PixelOut_D    <= PixelOut_N;
    end if;
  end process;
  
  AsyncProc : process (PixelIn, PixelInVal)
    variable Sum : word(DataW+3 downto 0);
  begin
    PixelOutVal_N <= PixelInVal;
    PixelOut_N    <= (others => '0');

    if PixelInVal = '1' then
      Sum := ("0000" & PixelIn(0)(0)) + (PixelIn(0)(1) & "0") + PixelIn(0)(2) +
              (PixelIn(1)(0) & "0") + (PixelIn(1)(1) & "00") + (PixelIn(1)(2) & "0") +
              PixelIn(2)(0) + (PixelIn(2)(1) & "0") + PixelIn(2)(2);
      -- Divide by 16
      Sum := SHR(Sum, "100");
      if Sum > Threshold then
        Sum := (others => '0');
      end if;
      PixelOut_N <= Sum(PixelOut'length-1 downto 0);
    end if;
  end process;

  PixelOut    <= PixelOut_D;
  PixelOutVal <= PixelOutVal_D;
end architecture rtl;
