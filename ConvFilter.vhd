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
    Clk          : in  bit1;
    RstN         : in  bit1;
    --
    FilterSel    : in  word(MODESW-1 downto 0);
    --
    IncThreshold : in  bit1;
    DecThreshold : in bit1;
    --
    RdAddr       : in  word(bits(FrameW)-1 downto 0);
    Vsync        : in  bit1;
    --
    PixelInVal   : in  bit1;
    PixelIn      : in  PixVec2D(Res-1 downto 0);
    --
    PixelOut     : out word(CompDataW-1 downto 0);
    PixelOutVal  : out bit1
    );
end entity;

architecture rtl of ConvFilter is
  signal PixelOut_N, PixelOut_D       : word(DataW-1 downto 0);
  signal PixelOutVal_N, PixelOutVal_D : bit1;

  constant RowsToFilter             : natural := 5;
  constant LinesToFilter            : natural := 9;
  signal LineFilter_N, LineFilter_D : word(bits(LinesToFilter)-1 downto 0);
  signal FirstColumn                : bit1;

  constant ThresholdStep : natural := 32;

  signal CurThres_N, CurThres_D : word(3-1 downto 0);
begin
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      PixelOut_D    <= (others => '0');
      PixelOutVal_D <= '0';
      LineFilter_D  <= (others => '0');
      CurThres_D    <= conv_word(3, CurThres_D'length);
    elsif rising_edge(Clk) then
      PixelOut_D    <= PixelOut_N;
      PixelOutVal_D <= PixelOutVal_N;
      LineFilter_D  <= LineFilter_N;
      CurThres_D    <= CurThres_N;
    end if;
  end process;

  -- Filter out noise in left column
  FirstColumn <= '1' when RdAddr < RowsToFilter else '0';

  AsyncProc : process (PixelIn, PixelInVal, PixelOut_D, Vsync, LineFilter_D, FirstColumn, RdAddr, FilterSel, IncThreshold, DecThreshold, CurThres_D)
    variable SumX, SumY, Sum : word(DataW+1 downto 0);
  begin
    PixelOut_N    <= PixelOut_D;
    LineFilter_N  <= LineFilter_D;
    -- Filter away edges
    PixelOutVal_N <= PixelInVal;
    CurThres_N    <= CurThres_D;

    if IncThreshold = '1' and DecThreshold = '1' then
      null;
    elsif IncThreshold = '1' then
      if CurThres_D /= xt1(CurThres_D'length) then
        CurThres_N <= CurThres_D + 1;
      end if;
    elsif DecThreshold = '1' then
      if CurThres_D /= xt0(CurThres_D'length) then
        CurThres_N <= CurThres_D - 1;
      end if;
    end if;
    
    if Vsync = '1' then
      LineFilter_N <= conv_word(LinesToFilter, LineFilter_N'length);
    end if;

    if PixelInVal = '1' then
      -- Sobel filter
      SumY := ("00" & PixelIn(0)(0)) + ('0' & PixelIn(0)(1) & '0') + ("00" & PixelIn(0)(2)) - (("00" & PixelIn(2)(0)) + ('0' & PixelIn(2)(1) & '0') + ("00" & PixelIn(2)(2)));
      SumX := ("00" & PixelIn(0)(2)) + ('0' & PixelIn(1)(2) & '0') + ("00" & PixelIn(2)(2)) - (("00" & PixelIn(0)(0)) + ('0' & PixelIn(1)(0) & '0') + ("00" & PixelIn(0)(2)));

      -- Convert to Absolute values
      if (SumX(SumX'high) = '1') then
        SumX := not SumX + 1;
      end if;

      if (SumY(SumY'high) = '1') then
        SumY := not SumY + 1;
      end if;

      Sum := SumX + SumY;

      if FilterSel = SOBEL_MODE then
        if Sum > ((conv_integer(CurThres_D)+1) * ThresholdStep)-1 then
          PixelOut_N <= (others => '1');
        else
          PixelOut_N <= Sum(PixelOut_N'length-1 downto 0);
        end if;
      end if;

      if FirstColumn = '1' then
        PixelOut_N <= (others => '0');
      end if;

      if LineFilter_D > 0 then
        PixelOut_N <= (others => '0');
        if RdAddr = FrameW-1 then
          LineFilter_N <= LineFilter_D - 1;
        end if;
      end if;
    end if;
    
  end process;

  -- Slice out the resolution we support
  PixelOut    <= PixelOut_D(DataW-1 downto DataW-CompDataW);
  PixelOutVal <= PixelOutVal_D;
end architecture rtl;
