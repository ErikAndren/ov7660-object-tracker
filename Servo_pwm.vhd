library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity servo_pwm is
  generic (
    ResW : positive := 7
    );
  port (
    Clk   : in  bit1; -- Must be 64 kHz
    RstN  : in  bit1;
    --
    Pos   : in  word(ResW-1 downto 0);
    --
    Servo : out bit1
    );
end Servo_pwm;

architecture Behavioral of Servo_pwm is
  constant MaxCnt  : positive := 1279;
  constant MaxCntW : positive := bits(MaxCnt);

  -- Counter, from 0 to 1279.
  signal Cnt_D : word(MaxCntW-1 downto 0);

  -- Temporal signal used to generate the PWM pulse.
  signal pwmi : word(ResW downto 0);
begin
  -- Minimum value should be 0.5ms.
  pwmi <= ('0' & Pos) + 32;

  -- Counter process, from 0 to 1279.
  counter : process (RstN, Clk)
  begin
    if (RstN = '0') then
      Cnt_D <= (others => '0');
    elsif rising_edge(Clk) then
      if Cnt_D = MaxCnt then
        Cnt_D <= (others => '0');
      else
        Cnt_D <= Cnt_D + 1;
      end if;
    end if;
  end process;

  -- Output signal for the Servomotor.
  Servo <= '1' when Cnt_D < pwmi else '0';
end Behavioral;
