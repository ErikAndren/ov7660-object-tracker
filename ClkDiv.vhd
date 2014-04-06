-- Clk divider implementation
-- Copyright Erik Zachrisson erik@zachrisson.info 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity ClkDiv is
  generic (
    SourceFreq : positive;
    SinkFreq   : positive
    );
  port (
    Clk     : in  bit1;
    RstN    : in  bit1;
    Clk_out : out bit1
    );
end;

architecture rtl of ClkDiv is
  signal divisor     : bit1;
  constant Period     : positive := SourceFreq / SinkFreq;
  constant HalfPeriod : positive := Period / 2;
  signal counter      : word(bits(HalfPeriod)-1 downto 0);
begin
  freq_divider : process (RstN, Clk)
  begin
    if (RstN = '0') then
      divisor <= '0';
      counter  <= (others => '0');
    elsif rising_edge(Clk) then
      if (counter = HalfPeriod-1) then
        divisor <= not divisor;
        counter  <= (others => '0');
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;

  Clk_out <= divisor;
end rtl;
