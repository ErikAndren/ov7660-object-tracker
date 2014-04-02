-- This function implements a simple P controller, trying to send pulses to
-- always keep the object tracked focused in the middle
-- Copyright erik@zachrisson.info

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity PWMCtrl is
  port (
    RstN        : in  bit1;
    Clk         : in  bit1;
    --
    TopLeft     : in  Cord;
    BottomRight : in  Cord;
    --
    YawPos      : out word(ServoResW-1 downto 0);
    PitchPos    : out word(ServoResW-1 downto 0)
    );
end entity;

architecture rtl of PWMCtrl is
  signal BoxMiddle     : Cord;
  --
  signal CurYawPos_N, CurYawPos_D     : word(ServoResW-1 downto 0);
  signal CurPitchPos_N, CurPitchPos_D : word(ServoResW-1 downto 0);

begin
  BoxMiddle.X <= BottomRight.X + (SHR((BottomRight.X - TopLeft.X), "1"));
  BoxMiddle.Y <= BottomRight.Y + (SHR((BottomRight.Y - TopLeft.Y), "1"));

  CalcDelta : process (BoxMiddle, CurYawPos_D, CurPitchPos_D)
    variable DeltaToMiddle : Cord;
  begin
    -- Box is on right side of screen, must move camera to the left
    if BoxMiddle.X > MiddleXOfScreen then
      DeltaToMiddle.X := BoxMiddle.X - MiddleXOfScreen;
      CurYawPos_N <= CurYawPos_D + Quotient(DeltaToMiddle.X, TileXRes);
    else
      DeltaToMiddle.X := MiddleXOfScreen - BoxMiddle.X;
      CurYawPos_N <= CurYawPos_D - Quotient(DeltaToMiddle.X, TileXRes);
    end if;

    -- Lower half of screen, must decrement to lower
    if BoxMiddle.Y > MiddleYOfScreen then
      DeltaToMiddle.Y := BoxMiddle.Y - MiddleYOfScreen;
      CurPitchPos_N <= CurPitchPos_D - Quotient(DeltaToMiddle.Y, TileYRes);
    else
      DeltaToMiddle.Y := MiddleYOfScreen +  BoxMiddle.Y;
      CurPitchPos_N <= CurPitchPos_D + Quotient(DeltaToMiddle.Y, TileYRes);
    end if;
  end process;

  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      CurYawPos_D   <= conv_word(ServoMiddle, CurYawPos_D'length);
      CurPitchPos_D <= conv_word(ServoMiddle, CurPitchPos_D'length);
    elsif rising_edge(Clk) then
      CurYawPos_D   <= CurYawPos_N;
      CurPitchPos_D <= CurPitchPos_N;
    end if;
  end process;
end architecture rtl;
