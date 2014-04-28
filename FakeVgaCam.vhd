library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity FakeVgaCam is
  port (
    RstN  : in  bit1;
    Clk   : in  bit1;
    --
    VSync : out bit1;
    HRef  : out bit1;
    D     : out word(8-1 downto 0)
    );
end entity;

architecture rtl of FakeVgaCam is
  signal clkCnt  : word(bits(tVsyncPeriod)-1 downto 0);
  signal lineCnt : word(bits(tVsyncPeriod / tLine)-1 downto 0);
  signal pixCnt  : word(bits(tLine)-1 downto 0);
begin
  Sync : process (Clk, RstN)
  begin
    if RstN = '0' then
      clkCnt <= (others => '0');
    elsif rising_edge(Clk) then
      clkCnt <= clkCnt + 1;
      if (clkCnt = tVsyncPeriod-1) then
        clkCnt <= (others => '0');
      end if;
    end if;
  end process;

  lineCnt <= conv_word(conv_integer(clkCnt) / tLine, lineCnt'length);
  pixCnt  <= conv_word(conv_integer(clkCnt) mod tLine, pixCnt'length);

  Async : process (lineCnt, pixCnt)
  begin
    vsync <= '0';
    href  <= '0';
    D     <= (others => '0');

    if (lineCnt < tVsyncHigh) then
      vsync <= '1';
    end if;
    
    if (conv_integer(lineCnt) >= tHrefPreamble and
        (conv_integer(lineCnt) < (tVsyncPeriod - tHrefPostamble))) then
      if (pixCnt < tHrefHigh) then
        href <= '1';
        D    <= pixCnt(D'range);
      end if;
    end if;
  end process;
end architecture rtl;
