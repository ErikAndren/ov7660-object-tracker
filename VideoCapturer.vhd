-- This file handles the sampling and clock crossing from the incoming pixel
-- clock to the internal system clock.
-- This is done using a 2 port fifo generated by the altera mega wizard
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VideoCapturer is
  generic (
    DataW : positive := 8
    );
  port (
    PRstN     : in  bit1;
    PClk      : in  bit1;
    --
    RstN      : in  bit1;
    Clk       : in  bit1;
    --
    Vsync     : in  bit1;
    Href      : in  bit1;
    PixelData : in  word(DataW-1 downto 0);
    --
    PixelOut  : out word(DataW-1 downto 0);
    PixelVal  : out bit1;
    FillLevel : out word(3-1 downto 0);
    Vsync_Clk : out bit1
    );

end entity;

architecture rtl of VideoCapturer is
  signal ValData_N                : bit1;
  signal PixelData_N, PixelData_D : word(DataW-1 downto 0);
  signal SeenVsync_N, SeenVsync_D : word(4-1 downto 0);
  --
  signal FifoEmpty                : bit1;
  signal RdFifo                   : bit1;
  signal FifoRdVal_N, FifoRdVal_D : bit1;
  signal RdData                   : word(DataW-1 downto 0);

  signal PixelOut_D : word(DataW-1 downto 0);
  signal PixelVal_D : bit1;

  signal VSync_D          : word(4-1 downto 0);

  signal VSync_META, VSync_D_Clk : bit1;
begin
  PClkSync : process (PCLK, PRstN)
  begin
    if PRstN = '0' then
      PixelData_D <= (others => '0');
      SeenVsync_D <= (others => '0');
      Vsync_D     <= (others => '0');
    elsif rising_edge(PCLK) then
      PixelData_D <= PixelData_N;
      SeenVsync_D <= SeenVsync_N;
      Vsync_D(0)  <= Vsync;
      for i in 1 to 3 loop
        Vsync_D(i) <= Vsync_D(i-1);
      end loop;

    end if;
  end process;

  PClkAsync : process (PixelData, Href, Vsync_D, SeenVsync_D)
  begin
    PixelData_N <= PixelData;
    ValData_N   <= '0';
    SeenVsync_N <= SeenVsync_D;

    -- Initial gating to ensure that we start to capture at the start of a frame
    if (RedAnd(SeenVsync_D) = '1') then
      -- VSync observed
      null;
    elsif (RedAnd(Vsync_D) = '1') then
      SeenVsync_N <= SeenVsync_D + 1;
    else
      -- Vsync tracking lost, go to start state
      SeenVSync_N <= (others => '0');
    end if;

    if Href = '1' and RedAnd(SeenVsync_D) = '1' then
      ValData_N <= '1';
    end if;
  end process;

  ClkCrossingFifo : entity work.AsyncFifo
    port map (
      data    => PixelData_D,
      wrclk   => PClk,
      wrreq   => ValData_N,
      --
      rdclk   => Clk,
      rdempty => FifoEmpty,
      rdreq   => RdFifo,
      q       => RdData,
      --
      rdusedw => FillLevel,
      wrfull  => open
      );
  RdFifo <= not FifoEmpty;

  ClkAsync : process (RdFifo)
  begin
    FifoRdVal_N <= '0';

    if RdFifo = '1' then
      FifoRdVal_N <= '1';
    end if;
  end process;

  ClkRstSync : process (RstN, Clk)
  begin
    if RstN = '0' then
      PixelVal_D <= '0';
    elsif rising_edge(Clk) then
      PixelVal_D <= FifoRdVal_D;
    end if;
  end process;

  ClkNoRstSync : process (Clk)
  begin
    if rising_edge(Clk) then
      FifoRdVal_D <= FifoRdVal_N;
      PixelOut_D  <= RdData;
      --
      VSync_META  <= RedAnd(VSync);
      VSync_D_Clk <= VSync_META;
    end if;
  end process;
  
  PixelFeed    : PixelOut  <= PixelOut_D;
  PixelValFeed : PixelVal  <= PixelVal_D;
  VsyncFeed    : Vsync_Clk <= Vsync_D_Clk;
end architecture;
