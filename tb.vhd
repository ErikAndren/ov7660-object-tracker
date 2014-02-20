
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity tb is
end entity;

architecture rtl of tb is
  signal RstN  : bit1;
  signal Clk50 : bit1;

  signal XCLK, PCLK  : bit1;
  signal D           : word(8-1 downto 0);
  signal VSYNC, HREF : bit1;

  signal SramD : word(16-1 downto 0);
  
begin
  RstN <= '0', '1' after 100 ns;

  ClkGen : process
  begin
    while true loop
      Clk50 <= '0';
      wait for 10 ns;
      Clk50 <= '1';
      wait for 10 ns;
    end loop;
  end process;


  OV7660SignalGen : block
    signal clkCnt  : integer;
    signal lineCnt : integer;
    signal pixCnt  : integer;

  begin
    Sync : process (XClk, RstN)
    begin
      if RstN = '0' then
        clkCnt <= 0;
      elsif rising_edge(Xclk) then
        clkCnt <= clkCnt + 1;
        if (clkCnt = tVsyncPeriod-1) then
          clkCnt <= 0;
        end if;
      end if;
    end process;

    lineCnt <= clkCnt / tLine;
    pixCnt  <= clkCnt mod tLine;

    Async : process (clkCnt, lineCnt, pixCnt)
    begin
      vsync <= '0';
      href  <= '0';
      D     <= (others => 'X');

      if (lineCnt < tVsyncHigh) then
        vsync <= '1';
      end if;
      
      if (lineCnt >= tHrefPreamble and
          (lineCnt < (tVsyncPeriod - tHrefPostamble))) then
        if (pixCnt < tHrefHigh) then
          href <= '1';
          D    <= conv_word(pixCnt, D'length);
        end if;
      end if;
    end process;
  end block;

  DUT : entity work.OV76X0
    port map (
      AsyncRstN => RstN,
      Clk       => Clk50,
      --
      Button1   => '1',
      Button2   => '1',
      --
      VSYNC     => VSYNC,
      HREF      => HREF,
      --
      XCLK      => XCLK,
      PCLK      => XCLK,
      D         => D,
      --
      Display   => open,
      Segments  => open,
      --
      SIO_C     => open,
      SIO_D     => open,
      --
      VgaRed    => open,
      VgaGreen  => open,
      VgaBlue   => open,
      VgaHsync  => open,
      VgaVsync  => open,
      --
      SramD     => SramD,
      SramAddr  => open,
      SramCeN   => open,
      SramOeN   => open,
      SramWeN   => open,
      SramUbN   => open,
      SramLbN   => open
      );

  SramD <= (others => 'Z');
  SramD <= "1111000011110000";
  
end architecture;
