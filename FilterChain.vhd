library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;
use work.SerialPack.all;

entity FilterChain is
  generic (
    DataW     : positive;
    CompDataW : positive
    );
  port (
    Clk          : in  bit1;
    RstN         : in  bit1;
    --
    Vsync        : in  bit1;
    --
    RegAccessIn  : in  RegAccessRec;
    RegAccessOut : out RegAccessRec;
    --
    PixelIn      : in  word(DataW-1 downto 0);
    PixelInVal   : in  bit1;
    --
    PixelOut     : out word(CompDataW-1 downto 0);
    PixelOutVal  : out bit1
    );
end entity;

architecture rtl of FilterChain is
  constant Res                                    : positive := 3;
  signal PixelArray, PixelArrayToConvFilter       : PixVec2D(Res-1 downto 0);
  signal PixelArrayVal, PixelArrayToConvFilterVal : bit1;
  signal PixelFromSobel                           : word(CompDataW-1 downto 0);
  signal PixelFromSobelVal                        : bit1;
  signal PixelFromDither                          : word(CompDataW-1 downto 0);
  signal PixelFromDitherVal                       : bit1;
  signal PixelFromGaussian                        : word(DataW-1 downto 0);
  signal PixelFromGaussianVal                     : bit1;
  signal RdAddr                                   : word(bits(FrameW)-1 downto 0);

  signal FilterSel_N, FilterSel_D : word(MODESW-1 downto 0);
begin
  LS : entity work.LineSampler
    generic map (
      DataW   => DataW,
      Buffers => 4,
      OutRes  => Res
      )
    port map (
      Clk         => Clk,
      RstN        => RstN,
      --
      Vsync       => Vsync,
      RdAddr      => open,
      --
      PixelIn     => PixelIn,
      PixelInVal  => PixelInVal,
      --
      PixelOut    => PixelArray,
      PixelOutVal => PixelArrayVal
    );

  MF : entity work.MedianFilter
    generic map (
      DataW => DataW,
      Res   => Res
      )
    port map (
      Clk         => Clk,
      RstN        => RstN,
      --
      PixelIn     => PixelArray,
      PixelInVal  => PixelArrayVal,
      --
      PixelOut    => PixelFromGaussian,
      PixelOutVal => PixelFromGaussianVal
      );
  
  LS_Conv : entity work.LineSampler
    generic map (
      DataW   => DataW,
      Buffers => 4,
      OutRes  => Res
      )
    port map (
      Clk         => Clk,
      RstN        => RstN,
      --
      Vsync       => Vsync,
      RdAddr      => RdAddr,
      --
      PixelIn     => PixelFromGaussian,
      PixelInVal  => PixelFromGaussianVal,
      --
      PixelOut    => PixelArrayToConvFilter,
      PixelOutVal => PixelArrayToConvFilterVal
    );

  CF : entity work.ConvFilter
    generic map (
      DataW     => DataW,
      CompDataW => CompDataW,
      Res       => Res
    )
    port map (
      Clk          => Clk,
      RstN         => RstN,
      --
      Vsync        => Vsync,
      IncThreshold => '0',
      DecThreshold => '0',
      --
      RdAddr       => RdAddr,
      FilterSel    => FilterSel_D,
      --
      PixelIn      => PixelArrayToConvFilter,
      PixelInVal   => PixelArrayToConvFilterVal,
      --
      PixelOut     => PixelFromSobel,
      PixelOutVal  => PixelFromSobelVal
      );

  VideoCompFloydSteinberg : entity work.DitherFloydSteinberg
    port map (
      Clk          => Clk,
      RstN         => RstN,
      --
      Vsync        => Vsync,
      --
      PixelIn      => PixelIn,
      PixelInVal   => PixelInVal,
      --
      PixelOut     => PixelFromDither,
      PixelOutVal  => PixelFromDitherVal
      );

  FilterSync : process (Clk, RstN)
  begin
    if RstN = '0' then
      FilterSel_D <= conv_word(SOBEL_MODE, FilterSel_D'length);
    elsif rising_edge(Clk) then
      FilterSel_D <= FilterSel_N;
    end if;
  end process;

  FilterAsync : process (FilterSel_D, RegAccessIn)
  begin
    FilterSel_N <= FilterSel_D;
    RegAccessOut <= RegAccessIn;

    if RegAccessIn.Val = "1" then
      if RegAccessIn.Addr = ModeToggleAddr then
        if RegAccessIn.Cmd = REG_WRITE then
          FilterSel_N <= RegAccessIn.Data(FilterSel_N'length-1 downto 0);
        else
          RegAccessOut.Data(FilterSel_N'length-1 downto 0) <= FilterSel_D;
        end if;
      end if;
    end if;
  end process;

  FilterMux : process (FilterSel_D, PixelFromSobel, PixelFromSobelVal, PixelFromDither, PixelFromDitherVal, PixelIn, PixelInVal, PixelFromGaussian, PixelFromGaussianVal)
  begin
    if FilterSel_D = SOBEL_MODE then
      PixelOutVal <= PixelFromSobelVal;
      PixelOut    <= PixelFromSobel;
    elsif FilterSel_D = DITHER_MODE then
      PixelOutVal <= PixelFromDitherVal;
      PixelOut    <= PixelFromDither;
    elsif FilterSel_D = GAUSSIAN_MODE then
      PixelOutVal <= PixelFromGaussianVal;
      PixelOut <= PixelFromGaussian(PixelIn'length-1 downto PixelIn'length-PixelOut'length);
    else
      PixelOutVal <= PixelInVal;
      PixelOut    <= PixelIn(PixelIn'length-1 downto PixelIn'length-PixelOut'length);
    end if;
  end process;
end architecture rtl;
