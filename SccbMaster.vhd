library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity SccbMaster is
  generic (
    DataW   : positive := 8;
    AddrW   : positive := 8;
    -- 
    ClkFreq : positive := 25000000
    );  
  port (
    Clk          : in    bit1;
    Rst_N        : in    bit1;
    --
    DataFromSccb : out   word(8-1 downto 0);
    AckErr       : out   bit1;
    --
    SIO_C        : out   bit1;
    SIO_D        : inout bit1;
    --
    InstPtr      : out   word(InstPtrW-1 downto 0)
    );
end entity;

architecture fpga of SccbMaster is
  -- 7 bit, OV7670 W:0x42, R:0x43
  constant DeviceAddr : word(8-1 downto 0) := "01000010";

  constant SccbClkFreq : positive := 100000;
  constant ClkWrap     : positive := ((ClkFreq / SccbClkFreq) / 2) -1;
  -- Data is to be output 90 degrees before 
  constant DataWrap    : positive := ClkWrap / 2;

  signal ClkCnt_N, ClkCnt_D   : word(bits(ClkWrap)-1 downto 0);
  signal ClkFlop_N, ClkFlop_D : bit1;
  --
  signal ReWe                 : bit1;
  signal DataPulse            : bit1;
  --
  signal data_i               : word(16-1 downto 0);
  signal TransDone            : bit1;
  signal ack_err              : bit1;
  --
  signal AddrData             : word(16-1 downto 0);
  signal StartTrans           : bit1;
  
  
begin
  AckErr <= ack_err;

  SccbM : entity work.SCCBCtrl
    port map (
      clk_i        => Clk,
      rst_i        => Rst_N,
      --
      sccb_clk_i   => ClkFlop_D,
      data_pulse_i => DataPulse,
      addr_i       => DeviceAddr,
      data_i       => AddrData,
      data_o       => DataFromSccb,
      rw_i         => ReWe,
      start_i      => StartTrans,
      ack_error_o  => ack_err,
      done_o       => TransDone,
      sioc_o       => SIO_C,
      siod_io      => SIO_D
      );

  OV7660I : entity work.OV7660Init
    port map (
      Clk      => Clk,
      Rst_N    => Rst_N,
      --
      NextInst => TransDone,
      --
      We       => ReWe,
      Start    => StartTrans,
      AddrData => AddrData,
      --
      InstPtr  => InstPtr
      );

  FSMSync : process (Clk, Rst_N)
  begin
    if Rst_N = '0' then
      ClkCnt_D  <= (others => '0');
      ClkFlop_D <= '0';
    elsif rising_edge(Clk) then
      ClkCnt_D  <= ClkCnt_N;
      ClkFlop_D <= ClkFlop_N;
    end if;
  end process;

  DataPulse <= '1' when ClkFlop_D = '0' and ClkCnt_D = DataWrap else '0';

  FSMAsync : process (ClkCnt_D, ClkFlop_D)
  begin
    ClkFlop_N <= ClkFlop_D;
    ClkCnt_N  <= ClkCnt_D + 1;

    if (ClkCnt_D = ClkWrap) then
      ClkCnt_N  <= (others => '0');
      ClkFlop_N <= not ClkFlop_D;
    end if;
  end process;
end architecture;
