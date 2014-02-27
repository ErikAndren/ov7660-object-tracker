
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
USE ieee.math_real.ALL;   -- for UNIFORM, TRUNC functions
USE ieee.numeric_std.ALL; -- for TO_UNSIGNED function

use work.Types.all;
use work.OV76X0Pack.all;

entity tb is
end entity;

architecture rtl of tb is
  signal RstN  : bit1;
  signal Clk50 : bit1;

  signal XCLK  : bit1;
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
    signal href_rand, vsync_rand : bit1;
    signal s1 : positive := 1;
    signal s2 : positive := 2;

    signal HrefFilt, VSyncFilt : bit1;
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

    Async : process (clkCnt, lineCnt, pixCnt, href_rand, vsync_rand)
    begin
      vsync <= '0';
      href  <= '0';
      D     <= (others => 'X');

      if (lineCnt < tVsyncHigh) then
        -- vsync <= '1' xor vsync_rand;
        vsync <= '1';
      end if;
      
      if (lineCnt >= tHrefPreamble and
          (lineCnt < (tVsyncPeriod - tHrefPostamble))) then
        if (pixCnt < tHrefHigh) then
--          href <= '1' xor href_rand;
            href <= '1';

          D    <= conv_word(pixCnt, D'length);
        end if;
      end if;
    end process;

    RandProc : process (XClk)
      variable rand : real;
      variable int_rand : integer;
      variable seed1, seed2 : positive;
    begin
      if rising_edge(XClk) then
        seed1 := s1;
        seed2 := s2;
        
        href_rand <= '0';
        vsync_rand <= '0';
        
        UNIFORM(seed1, seed2, rand);                                   -- generate random number
        int_rand := INTEGER(TRUNC(rand*100.0));                       -- rescale to 0..4096, find integer part
        if (int_rand = 1) then
          href_rand <= conv_word(int_rand, 7)(0);  -- convert to std_logic_vector
        end if;

        UNIFORM(seed1, seed2, rand);                                   -- generate random number
        int_rand := INTEGER(TRUNC(rand*100.0));                       -- rescale to 0..4096, find integer part
        if (int_rand = 1) then
          vsync_rand <= conv_word(int_rand, 7)(0);  -- convert to std_logic_vector
        end if;  
        s1 <= seed1 + int_rand;
      end if;
    end process;

    --Filter : entity work.OV76X0Filter
    --  port map (
    --    Rst_N => RstN,
    --    Clk => XClk,
    --    --
    --    Href => href,
    --    VSync => vsync,
    --    --
    --    HrefFiltered => HRefFilt,
    --    VsyncFiltered => VsyncFilt
    --    );
      
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
