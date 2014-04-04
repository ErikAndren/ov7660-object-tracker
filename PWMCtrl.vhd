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
    PitchPos    : out word(ServoResW-1 downto 0);
    --
    Btn1 : in bit1;
    Btn2 : in bit1
    );
end entity;

architecture rtl of PWMCtrl is
  signal BoxMiddle                    : Cord;
  signal CalcMiddle                   : Cord;
  --
  signal CurYawPos_N, CurYawPos_D     : word(ServoResW-1 downto 0);
  signal CurPitchPos_N, CurPitchPos_D : word(ServoResW-1 downto 0);
  signal BoxDelta                     : Cord;
  
begin
  -- Calculate middle by adding half the delta 
  -- BoxMiddle.X <= TopLeft.X + (SHR((BottomRight.X - TopLeft.X), "1"));
  -- BoxMiddle.Y <= TopLeft.Y + (SHR((BottomRight.Y - TopLeft.Y), "1"));

  BoxDelta.X  <= BottomRight.X - TopLeft.X;
  BoxDelta.Y  <= BottomRight.Y - TopLeft.Y;
  --
  BoxMiddle.X <= TopLeft.X + Quotient(BoxDelta.X, 2);
  BoxMiddle.Y <= TopLeft.Y + Quotient(BoxDelta.Y, 2);

  CalcDelta : process (BoxMiddle, CurYawPos_D, CurPitchPos_D)
    variable DeltaToMiddle : Cord;
  begin
    -- Box is on right side of screen, must move camera to the left
    if BoxMiddle.X > MiddleXOfScreen then
      DeltaToMiddle.X := BoxMiddle.X - MiddleXOfScreen;
      -- Delta must be adjusted to available pwm resolution
      -- Add adjusted delta to yaw pos
      CurYawPos_N     <= CurYawPos_D + Quotient(DeltaToMiddle.X, TileXRes);
      -- Protect against overflow
      if CurYawPos_D + Quotient(DeltaToMiddle.X, TileXRes) > xt1(CurYawPos_D'length) then
        CurYawPos_N <= (others => '1');
      end if;
    else
      DeltaToMiddle.X := MiddleXOfScreen - BoxMiddle.X;
      CurYawPos_N     <= CurYawPos_D - Quotient(DeltaToMiddle.X, TileXRes);
      -- Protect against underflow
      if (CurYawPos_D - Quotient(DeltaToMiddle.X, TileXRes) < 0) then
        CurYawPos_N <= (others => '0');
      end if;
    end if;

    -- Lower half of screen, must decrement to lower
    if BoxMiddle.Y > MiddleYOfScreen then
      DeltaToMiddle.Y := BoxMiddle.Y - MiddleYOfScreen;
      CurPitchPos_N   <= CurPitchPos_D - Quotient(DeltaToMiddle.Y, TileYRes);
      -- Protect against underflow
      if CurPitchPos_D - Quotient(DeltaToMiddle.Y, TileYRes) < 0 then
        CurPitchPos_N <= (others => '0');
      end if;
    else
      DeltaToMiddle.Y := MiddleYOfScreen - BoxMiddle.Y;
      CurPitchPos_N   <= CurPitchPos_D + Quotient(DeltaToMiddle.Y, TileYRes);
      if CurPitchPos_D + Quotient(DeltaToMiddle.Y, TileYRes) > xt1(CurPitchPos_D'length) then
        CurPitchPos_N <= (others => '1');
      end if;
    end if;

--    CalcMiddle <= DeltaToMiddle;
  end process;

  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      CurYawPos_D   <= conv_word(ServoYawStart, CurYawPos_D'length);
      CurPitchPos_D <= conv_word(ServoPitchStart, CurPitchPos_D'length);

    elsif rising_edge(Clk) then
      CurYawPos_D   <= CurYawPos_N;
      CurPitchPos_D <= CurPitchPos_N;
    end if;
  end process;
  
  YawPossAssign  : YawPos   <= CurYawPos_D;
  PitchPosAssign : PitchPos <= CurPitchPos_D;
end architecture rtl;
