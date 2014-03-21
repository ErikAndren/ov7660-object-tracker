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
    PixelOut    : out PixVec(OutRes-1 downto 0);
    PixelOutVal : out bit1
    );
end entity;

architecture rtl of LineSampler is
  signal WrAddr_N, WrAddr_D : word(FrameHW-1 downto 0);
  signal RdAddr_N, RdAddr_D : word(FrameHW-1 downto 0);
  type AddrArr is array (natural range <>) of word(Buffers-1 downto 0);
  --
  signal Addr : AddrArr(Buffers-1 downto 0);
  signal LineCnt_N, LineCnt_D : word(bits(Buffers)-1 downto 0);
  signal WrEn : word(Buffers-1 downto 0);
begin
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      LineCnt_D <= (others => '0');
      WrAddr_D  <= (others => '0');
      RdAddr_D  <= (others => '0');
    elsif rising_edge(Clk) then
      LineCnt_D <= LineCnt_N;
      WrAddr_D  <= WrAddr_N;
      RdAddr_D  <= RdAddr_N;
    end if;
  end process;

  AsyncProc : process (LineCnt_D)
  begin
    LineCnt_N <= LineCnt_D;
    WrAddr_N  <= WrAddr_D;
    RdAddr_N  <= RdAddr_N;
  end process;

  OneHotProc : process (LineCnt_D, PixelInVal, WrAddr_D, RdAddr_D)
  begin
    WrEn <= (others => '0');
    Addr <= (others => RdAddr_D);

    if PixelInVal = '1' then
      WrEn(conv_integer(LineCnt_D)) <= '1';
      Addr(conv_integer(LineCnt_D)) <= WrAddr_D;
    end if;
  end process;

  Ram : for i in 0 to Buffers-1 generate
    R : entity work.LineSampler1pRAM
      port map (
        Clock   => Clk,
        Data    => PixelIn,
        WrEn    => WrEn(i),
        address => Addr(i),
        --
        q       => PixelOut(i)
        );
  end generate;
end architecture rtl;
