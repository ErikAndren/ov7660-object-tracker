-- Table that defines what register and data pairs to write to the OV7660 via
-- SCCB after startup. A delay is needed before writing the actual data
-- Also perform a register reset first of all in order to ensure that we know
-- what state we are writing. A simple FPGA flash might not reset the OV7660 firmware.
-- Copyright Erik Zachrisson - erik@zachrisson.info

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;
use work.SerialPack.all;

entity OV7660Init is
  port (
    Clk          : in  bit1;
    Rst_N        : in  bit1;
    --
    NextInst     : in  bit1;
    --
    RegAccessIn  : in  RegAccessRec;
    RegAccessOut : out RegAccessRec;
    --
    We           : out bit1;
    Start        : out bit1;
    AddrData     : out word(16-1 downto 0)
    );
end entity;

architecture fpga of OV7660Init is
  signal We_N, Start_N : bit1;
  signal AddrData_N : word(16-1 downto 0);
  --
  constant BLUE  : word(8-1 downto 0) := x"01";
  constant RED   : word(8-1 downto 0) := x"02";  
  constant COM2  : word(8-1 downto 0) := x"09";
  constant AECH  : word(8-1 downto 0) := x"10";
  constant CLKRC : word(8-1 downto 0) := x"11";
  constant COM7  : word(8-1 downto 0) := x"12";
  constant COM8  : word(8-1 downto 0) := x"13";
  constant COM9  : word(8-1 downto 0) := x"14";
  constant COM10 : word(8-1 downto 0) := x"15";
  constant MVFP  : word(8-1 downto 0) := x"1e";
  constant TSLB  : word(8-1 downto 0) := x"3a";
  constant COM15 : word(8-1 downto 0) := x"40";
  -- Comment stolen from ov7660.c
  -- v-red, v-green, v-blue, u-red, u-green, u-blue
  -- They are nine-bit signed quantities, with the sign bit
  -- stored in 0x58.  Sign for v-red is bit 0, and up from there.

  -- Red
  constant MTX1  : word(8-1 downto 0) := x"4F";

  -- Red
  constant MTX2  : word(8-1 downto 0) := x"50";

  -- Red
  constant MTX3  : word(8-1 downto 0) := x"51";

  -- Blue
  constant MTX4  : word(8-1 downto 0) := x"52";

  -- Blue
  constant MTX5  : word(8-1 downto 0) := x"53";

  -- Blue
  constant MTX6  : word(8-1 downto 0) := x"54";

  constant MTX7  : word(8-1 downto 0) := x"55";
  constant MTX8  : word(8-1 downto 0) := x"56";
  constant MTX9  : word(8-1 downto 0) := x"57";
  constant MTXS  : word(8-1 downto 0) := x"58";
  --
  constant MANU  : word(8-1 downto 0) := x"67";
  constant MANV  : word(8-1 downto 0) := x"68";

  constant NbrOfInst : positive := 1;

  signal InstPtr_N, InstPtr_D : word(4-1 downto 0);
  -- FIXME: Potentially listen for a number of vsync pulses instead. This would
  -- save a number of flops
  -- wait for 2**16 cycles * 40 ns = ~2 ms
  signal Delay_N, Delay_D     : word(16-1 downto 0);

  signal LatchedAddrData_N, LatchedAddrData_D : word(16-1 downto 0);
  signal LatchedWe_N, LatchedWe_D             : bit1;
  signal LatchedStart_N, LatchedStart_D       : bit1;
  
begin
  SyncProc : process (Clk, Rst_N)
  begin
    if Rst_N = '0' then
      InstPtr_D <= (others => '0');

      if Simulation then
        Delay_D <= "1111111111111100";
      end if;

      if Synthesis then
        Delay_D <= (others => '0');
      end if;

      LatchedStart_D    <= '0';
      LatchedWe_D       <= '0';
      LatchedAddrData_D <= (others => '0');
      
    elsif rising_edge(Clk) then
      InstPtr_D         <= InstPtr_N;
      Delay_D           <= Delay_N;
      LatchedStart_D    <= LatchedStart_N;
      LatchedWe_D       <= LatchedWe_N;
      LatchedAddrData_D <= LatchedAddrData_N;
    end if;
  end process;

  ASyncProc : process (InstPtr_D, NextInst, Delay_D)
    variable InstPtr_T : word(4-1 downto 0);
  begin
    InstPtr_T := InstPtr_D;
    AddrData_N  <= (others => '0');
    We_N      <= '1';
    Start_N   <= '1';
    --
    Delay_N   <= Delay_D + 1;
    if (RedAnd(Delay_D) = '1') then
      Delay_N <= Delay_D;

      if (NextInst = '1') then
        InstPtr_T := InstPtr_D + 1;
      end if;

      case conv_integer(InstPtr_D) is
        when 0 =>
          AddrData_N <= COM7 & x"80";     -- SCCB Register reset

        when 1 =>
          AddrData_N <= COM7 & x"80";     -- SCCB Register reset

        when 2 =>
          AddrData_N <= COM7 & x"00";     -- SCCB Register reset

        when 3 =>
          AddrData_N <= COM2 & x"00";     -- Enable 4x drive

        when 4 =>
          AddrData_N <= MVFP & x"10";     -- Flip image to it mount

        when others =>
          We_N      <= '0';
          Start_N   <= '0';
          --
          InstPtr_T := (others => '1');
          Start_N   <= '0';
      end case;
    end if;

    InstPtr_N <= InstPtr_T;
  end process;

  InitAndRegMux : process (We_N, Start_N, RegAccessIn, AddrData_N, LatchedWe_D, LatchedStart_D, LatchedAddrData_D, NextInst)
  begin
    We                <= We_N;
    Start             <= Start_N;
    RegAccessOut      <= RegAccessIn;
    AddrData          <= AddrData_N;
    --
    LatchedWe_N       <= LatchedWe_D;
    LatchedStart_N    <= LatchedStart_D;
    LatchedAddrData_N <= LatchedAddrData_D;

    if RegAccessIn.Val = "1" then
       if RegAccessIn.Cmd = REG_WRITE and (RegAccessIn.Addr(32-1 downto 8) = SccbOffset) then
        LatchedWe_N       <= '1';
        LatchedStart_N    <= '1';
        LatchedAddrData_N <= RegAccessIn.Addr(8-1 downto 0) & RegAccessIn.Data(8-1 downto 0);
      end if;
    end if;

    if LatchedStart_D = '1' then
      Start    <= '1';
      We       <= LatchedWe_D;
      AddrData <= LatchedAddrData_D;

      if NextInst = '1' then
        LatchedStart_N <= '0';
      end if;
    end if;
  end process;
end architecture;
