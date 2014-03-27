library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VGAGenerator is
  generic (
    DivideClk : boolean := true
    );
  port (
    Clk           : in  bit1;
    RstN          : in  bit1;
    --
    DataToDisplay : in  word(3-1 downto 0);
    InView        : out bit1;
    --
    Red           : out word(3-1 downto 0);
    Green         : out word(3-1 downto 0);
    Blue          : out word(3-1 downto 0);
    HSync         : out bit1;
    VSync         : out bit1
    );
end entity;

architecture rtl of VGAGenerator is
  signal PixelClk : bit1;

  constant hsync_end  : positive := 95;
  constant hdat_begin : positive := 143;
  constant hdat_end   : positive := 783;
  constant hpixel_end : positive := 799;
  constant vsync_end  : positive := 1;
  constant vdat_begin : positive := 34;
  constant vdat_end   : positive := 514;
  constant vline_end  : positive := 524;

  signal hCount    : word(10-1 downto 0);
  signal vCount    : word(10-1 downto 0);
  signal hCount_ov : bit1;
  signal vCount_ov : bit1;
  --
  signal InView_i  : bit1;
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

  hcount_ov <= '1' when hcount = hpixel_end else '0';
  HCnt : process (RstN, PixelClk)
  begin
    if RstN = '0' then
      hcount <= (others => '0');
    elsif rising_edge(PixelClk) then
      if (hcount_ov = '1') then
        hcount <= (others => '0');
      else
        hcount <= hcount + 1;
      end if;
    end if;
  end process;

  vcount_ov <= '1' when vcount = vline_end else '0';
  VCnt : process (RstN, PixelClk)
  begin
    if RstN = '0' then
      vcount <= (others => '0');
    elsif rising_edge(PixelClk) then
      if (hcount_ov = '1') then
        if (vcount_ov = '1') then
          vcount <= (others => '0');
        else
          vcount <= vcount + 1;
        end if;
      end if;
    end if;
  end process;

  InView_i <= '1' when ((hcount >= hdat_begin) and (hcount < hdat_end)) and ((vcount >= vdat_begin) and (vcount < vdat_end)) else '0';
  InView   <= InView_i;
  Hsync    <= '1' when hcount > hsync_end                                                                                    else '0';
  Vsync    <= '1' when vcount > vsync_end                                                                                    else '0';

  Red   <= (others => '0') when InView_i = '0' else DataToDisplay(3-1 downto 0);
  Green <= (others => '0') when InView_i = '0' else DataToDisplay(3-1 downto 0);
  Blue  <= (others => '0') when InView_i = '0' else DataToDisplay(3-1 downto 0);
end architecture rtl;
