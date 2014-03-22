library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity LineSampler is
  generic (
    DataW   : positive;
    Buffers : positive;
    OutRes  : positive
    );
  port (
    Clk         : in  bit1;
    RstN        : in  bit1;
    --
    PixelIn     : in  word(DataW-1 downto 0);
    PixelInVal  : in  bit1;
    --
    PixelOut    : out PixVec2D(OutRes-1 downto 0);
    PixelOutVal : out bit1
    );
end entity;

architecture rtl of LineSampler is
  signal Addr_N, Addr_D       : word(FrameWW-1 downto 0);
  type AddrArr is array (natural range <>) of word(Buffers-1 downto 0);
  signal PixArr_N, PixArr_D   : PixVec2D(3-1 downto 0);
  --
  --
  signal Addr                 : AddrArr(Buffers-1 downto 0);
  signal LineCnt_N, LineCnt_D : word(bits(Buffers)-1 downto 0);
  signal WrEn                 : word(Buffers-1 downto 0);
  signal RamOut               : PixVec;

  function CalcLine(CurLine : word; Offs : natural) return natural is
  begin
    return conv_integer(CurLine) + Offs + 1 mod Buffers;
  end function;
begin
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      LineCnt_D <= (others => '0');
      Addr_D    <= (others => '0');
      PixArr_D  <= (others => (others => (others => '0')));
    elsif rising_edge(Clk) then
      LineCnt_D <= LineCnt_N;
      Addr_D    <= Addr_N;
      PixArr_D  <= PixArr_N;
    end if;
  end process;

  AsyncProc : process (LineCnt_D, Addr_D, PixArr_D)
  begin
    LineCnt_N <= LineCnt_D;
    Addr_N    <= Addr_D;
    PixArr_N  <= PixArr_D;

    if PixelInVal = '1' then
      Addr_N <= Addr_D + 1;
      if Addr_D + 1 = FrameW then
        Addr_N <= (others => '0');
        LineCnt_N <= LineCnt_D + 1;
        if LineCnt_D + 1 = Buffers then
          LineCnt_N <= (others => '0');
        end if;
      end if;
        
      for i in 0 to 3-1 loop
        PixArr_N(i)(0) <= PixArr_N(i)(1);
        PixArr_N(i)(1) <= PixArr_N(i)(2);
        PixArr_N(i)(2) <= RamOut(CalcLine(LineCnt_D, i));
      end loop;
    end if;
  end process;
  Addr <= (others => Addr_D);

  OneHotProc : process (LineCnt_D, PixelInVal)
  begin
    WrEn <= (others => '0');

    if PixelInVal = '1' then
      WrEn(conv_integer(LineCnt_D)) <= '1';
    end if;
  end process;

  Ram : for i in 0 to Buffers-1 generate
    R : entity work.LineSampler1pRAM
      port map (
        Clock   => Clk,
        Data    => PixelIn,
        WrEn    => WrEn(i),
        address => Addr_D,
        --
        q       => RamOut(i)
        );
  end generate;

  PixelOutVal <= PixelInVal;
  PixelOutMux : process (RamOut, LineCnt_D)
  begin
    for i in 0 to OutRes-1 loop
      PixelOut(i) <= PixArr_D(CalcLine(LineCnt_D, i));
    end loop;
  end process;
end architecture rtl;
