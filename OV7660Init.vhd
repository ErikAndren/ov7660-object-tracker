library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity OV7660Init is
  port (
    Clk      : in  bit1;
    Rst_N    : in  bit1;
    --
    NextInst : in  bit1;
    --
    We       : out bit1;
    Start    : out bit1;
    AddrData : out word(16-1 downto 0);
    --
    InstPtr  : out word(InstPtrW-1 downto 0)
    );
end entity;

architecture fpga of OV7660Init is
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
  constant MANU  : word(8-1 downto 0) := x"67";
  constant MANV  : word(8-1 downto 0) := x"68";

  constant NbrOfInst : positive := 1;

  signal InstPtr_N, InstPtr_D : word(InstPtrW-1 downto 0);
  signal Delay_N, Delay_D     : word(16-1 downto 0);
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
    elsif rising_edge(Clk) then
      InstPtr_D <= InstPtr_N;
      Delay_D   <= Delay_N;
    end if;
  end process;

  ASyncProc : process (InstPtr_D, NextInst, Delay_D)
    variable InstPtr_T : word(InstPtrW-1 downto 0);
  begin
    InstPtr_T := InstPtr_D;
    AddrData  <= (others => '0');
    We        <= '0';
    Start     <= '0';
    Delay_N   <= Delay_D + 1;
    if (RedAnd(Delay_D) = '1') then
      Delay_N <= Delay_D;

      if (NextInst = '1') then
        InstPtr_T := InstPtr_D + 1;
      end if;

      case InstPtr_D is
        when "0000" =>
          AddrData <= COM7 & x"80";     -- SCCB Register reset
          We       <= '1';
          Start    <= '1';
          
        when "0001" =>
          AddrData <= COM2 & x"00";     -- Enable 4x drive
          We       <= '1';
          Start    <= '1';

        when "0010" =>
          AddrData <= MVFP & x"10";      -- Flip image to it mount
          We       <= '1';
          Start    <= '1';

--                              when "0001" =>
--                                      AddrData <= COM7 & x"00"; -- SCCB Register reset release
--                                      We       <= '1';
--                                      Start    <= '1';
--                                      
--                              when "0001" =>
--                                      AddrData <= COM7 & x"04"; -- Enable RGB
--                                      We       <= '1';
--                                      Start    <= '1';
----                                    
--                              when "0010" =>
--                                      AddrData <= COM15 & x"D0"; -- Enable RGB565
--                                      We       <= '1';
--                                      Start    <= '1';

--                              when "0010" =>
--                                      AddrData <= AECH & x"01"; -- 
--                                      We       <= '1';
--                                      Start    <= '1';

--                              when "0010" =>
--                                      AddrData <= COM8 & x"A9"; -- Enable banding filter, disable AGC
--                                      We       <= '1';
--                                      Start    <= '1';

--                              when "0010" =>
--                                      AddrData <= CLKRC & x"80"; -- Reverse PCLK
--                                      We       <= '1';
--                                      Start    <= '1';

--                              when "0010" =>
--                                      AddrData <= COM2 & x"11"; -- enable soft sleep
--                                      We       <= '1';
--                                      Start    <= '1';

          --                    when "0000" =>
          --                            AddrData <= TSLB & x"1C"; -- enable line buffer test option
          --                            We       <= '1';
          --                            Start    <= '1';

        when others =>
          InstPtr_T := (others => '1');
          Start     <= '0';
          
      end case;
    end if;

    InstPtr_N <= InstPtr_T;
  end process;

  InstPtr <= InstPtr_D;
end architecture;
