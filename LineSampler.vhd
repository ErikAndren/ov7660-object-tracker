-- Samples the line and stores it in 3 rams
-- This is then sent in a 3x3 array to a filter
-- Copyright Erik Zachrisson erik@zachrisson.info


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
    Vsync       : in  bit1;
    RdAddr      : out word(bits(FrameW)-1 downto 0);
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
  signal LineCnt_N, LineCnt_D : word(bits(Buffers)-1 downto 0);
  signal WrEn                 : word(Buffers-1 downto 0);
  type BuffArr is array (natural range <>) of word(PixelW-1 downto 0);
  signal RamOut               : BuffArr(Buffers-1 downto 0);

  signal PixelVal_D : bit1;
  
  function CalcLine(CurLine : word; Offs : natural) return natural is
  begin
    return ((conv_integer(CurLine) + Offs + 1) mod Buffers);
  end function;
begin
  SyncRstProc : process (RstN, Clk)
  begin
    if RstN = '0' then
      PixelVal_D <= '0';
    elsif rising_edge(Clk) then
      PixelVal_D <= PixelInVal;
    end if;
  end process;
  
  SyncNoRstProc : process (Clk)
  begin
    if rising_edge(Clk) then
      LineCnt_D <= LineCnt_N;
      Addr_D    <= Addr_N;
      PixArr_D  <= PixArr_N;

      if Vsync = '1' then
        LineCnt_D <= (others => '0');
        Addr_D    <= (others => '0');
        PixArr_D  <= (others => (others => (others => '0')));
      end if;
    end if;
  end process;
  
  AsyncProc : process (LineCnt_D, Addr_D, PixArr_D, PixelInVal, RamOut)
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

      -- Shift all entries one step to the left
      for i in 0 to OutRes-1 loop
        PixArr_N(i)(0) <= PixArr_D(i)(1);        
        PixArr_N(i)(1) <= PixArr_D(i)(2);
        PixArr_N(i)(2) <= RamOut(CalcLine(LineCnt_D, i));

        -- Clear buffer on the end of the line
        -- FIXME: is this necessary?
      end loop;
    end if;
  end process;

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

  AddrFeed        : RdAddr      <= Addr_D;
  PixelOutValFeed : PixelOutVal <= PixelVal_D;
  PixelOutFeed    : PixelOut    <= PixArr_D;
end architecture rtl;
