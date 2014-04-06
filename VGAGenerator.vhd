-- Generates the vga signal for a 640x480 signal
-- Copyright 2014 Erik Zachrisson - erik@zachrisson.info
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VGAGenerator is
  generic (
    DataW     : positive := 3;
    DivideClk : boolean  := true;
    Offset    : natural  := 0
    );
  port (
    Clk            : in  bit1;
    RstN           : in  bit1;
    --
    PixelToDisplay : in  word(DataW-1 downto 0);
    DrawRect       : in  bit1;
    InView         : out bit1;
    --
    Red            : out word(DataW-1 downto 0);
    Green          : out word(DataW-1 downto 0);
    Blue           : out word(DataW-1 downto 0);
    HSync          : out bit1;
    VSync          : out bit1
    );
end entity;

architecture rtl of VGAGenerator is
  signal PixelClk : bit1;

  constant HSyncEnd  : positive := 95;
  constant HDatBegin : positive := 143;
  constant HDatEnd   : positive := 783;
  constant HPixelEnd : positive := 799;
  constant VSyncEnd  : positive := 1;
  constant VDatBegin : positive := 34;
  constant VDatEnd   : positive := 514;
  constant VLineEnd  : positive := 524;

  signal hCount     : word(bits(HPixelEnd)-1 downto 0);
  signal vCount     : word(bits(VLineEnd)-1 downto 0);
  signal HCountOvfl : bit1;
  signal VCountOvfl : bit1;
  --
  signal InView_i   : bit1;
begin
  DivClkGen : if DivideClk = true generate
    ClkDiv : process (RstN, Clk)
    begin
      if RstN = '0' then
        PixelClk <= '0';
      elsif rising_edge(Clk) then
        PixelClk <= not PixelClk;
      end if;
    end process;
  end generate;

  NoDivClkGen : if DivideClk = false generate
    PixelClk <= Clk;
  end generate;

  HCountOvfl <= '1' when hcount = HPixelEnd else '0';
  HCnt : process (RstN, PixelClk)
  begin
    if RstN = '0' then
      hcount <= (others => '0');
    elsif rising_edge(PixelClk) then
      if (HCountOvfl = '1') then
        hcount <= (others => '0');
      else
        hcount <= hcount + 1;
      end if;
    end if;
  end process;

  VCountOvfl <= '1' when vcount = VLineEnd else '0';
  VCnt : process (RstN, PixelClk)
  begin
    if RstN = '0' then
      vcount <= (others => '0');
    elsif rising_edge(PixelClk) then
      if (HCountOvfl = '1') then
        if (VCountOvfl = '1') then
          vcount <= (others => '0');
        else
          vcount <= vcount + 1;
        end if;
      end if;
    end if;
  end process;

  InView_i <= '1' when ((hcount >= HDatBegin - Offset) and (hcount < HDatEnd - Offset)) and ((vcount >= VDatBegin) and (vcount < VDatEnd)) else '0';
  InView   <= InView_i;
  
  Hsync <= '1' when hcount > HSyncEnd else '0';
  Vsync <= '1' when vcount > VSyncEnd else '0';

  DrawColorProc : process (PixelToDisplay, DrawRect, InView_i)
  begin
    Red <= (others => '0');
    Green <= (others => '0');
    Blue <= (others => '0');

    if InView_i = '1' then
      Red <= PixelToDisplay;
      Green <= PixelToDisplay;
      Blue <= PixelToDisplay;

      -- Draw green rectangle overlay
      if DrawRect = '1' then
        Green <= (others => '1');
      end if;
    end if;
  end process;
  
end architecture rtl;
