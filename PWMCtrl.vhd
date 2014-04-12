-- This function implements a simple P controller, trying to send pulses to
-- always keep the object tracked focused in the middle
-- Copyright 2014 erik@zachrisson.info

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
    Clk64KHz    : in  bit1;
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

  signal Cnt_N, Cnt_D : word(bits(64000)-1 downto 0);
  
begin
  -- Calculate middle by adding half the delta 
  -- BoxMiddle.X <= TopLeft.X + (SHR((BottomRight.X - TopLeft.X), "1"));
  -- BoxMiddle.Y <= TopLeft.Y + (SHR((BottomRight.Y - TopLeft.Y), "1"));

  BoxDelta.X  <= BottomRight.X - TopLeft.X;
  BoxDelta.Y  <= BottomRight.Y - TopLeft.Y;
  --
  BoxMiddle.X <= TopLeft.X + Quotient(BoxDelta.X, 2);
  BoxMiddle.Y <= TopLeft.Y + Quotient(BoxDelta.Y, 2);

  CalcDelta : process (BoxMiddle, CurYawPos_D, CurPitchPos_D, Cnt_D)
    variable DeltaToMiddle : Cord;
  begin
    -- Box is on right side of screen, must move camera to the left
    if BoxMiddle.X > MiddleXOfScreen then
      DeltaToMiddle.X := BoxMiddle.X - MiddleXOfScreen;
      -- Delta must be adjusted to available pwm resolution
      -- Add adjusted delta to yaw pos
      -- CurYawPos_N     <= CurYawPos_D + Quotient(DeltaToMiddle.X, TileXRes);
      CurYawPos_N <= CurYawPos_D + 1;
      -- Protect against overflow
      if CurYawPos_D + 1 > ServoYawMax then
        CurYawPos_N <= conv_word(ServoYawMax, CurYawPos_N'length);
      end if;
      
    else
      DeltaToMiddle.X := MiddleXOfScreen - BoxMiddle.X;
      --CurYawPos_N     <= CurYawPos_D - Quotient(DeltaToMiddle.X, TileXRes);
      CurYawPos_N <= CurYawPos_D - 1;
      -- Protect against underflow
      if (CurYawPos_D - 1 < ServoYawMin) then
        CurYawPos_N <= conv_word(ServoYawMin, CurYawPos_N'length);
      end if;
    end if;

    -- Lower half of screen, must decrement to lower
    if BoxMiddle.Y > MiddleYOfScreen then
      DeltaToMiddle.Y := BoxMiddle.Y - MiddleYOfScreen;
      CurPitchPos_N   <= CurPitchPos_D - Quotient(DeltaToMiddle.Y, TileYRes);
      -- Protect against underflow
      if CurPitchPos_D - Quotient(DeltaToMiddle.Y, TileYRes) < ServoPitchMin then
        CurPitchPos_N <= conv_word(ServoYawMin, CurPitchPos_N'length);
      end if;
    else
      DeltaToMiddle.Y := MiddleYOfScreen - BoxMiddle.Y;
      CurPitchPos_N   <= CurPitchPos_D + Quotient(DeltaToMiddle.Y, TileYRes);
      if CurPitchPos_D + Quotient(DeltaToMiddle.Y, TileYRes) > ServoPitchMax then
        CurPitchPos_N <= conv_word(ServoPitchMax, CurPitchPos_D'length);
      end if;
    end if;

--    CalcMiddle <= DeltaToMiddle;
    -- FIXME: Keep idle for now
    CurPitchPos_N <= CurPitchPos_D;

    Cnt_N <= Cnt_D + 1;
    if (Cnt_D = 3200) then
      Cnt_N <= (others => '0');
    else
      CurPitchPos_N <= CurPitchPos_D;
      CurYawPos_N   <= CurYawPos_D;
    end if;
  end process;

  SyncProc : process (Clk64Khz, RstN)
  begin
    if RstN = '0' then
      CurYawPos_D   <= conv_word(ServoYawStart, CurYawPos_D'length);
      CurPitchPos_D <= conv_word(ServoPitchStart, CurPitchPos_D'length);
      Cnt_D <= (others => '0');
    elsif rising_edge(Clk64Khz) then
      Cnt_D <= Cnt_N;
      CurYawPos_D   <= CurYawPos_N;
      CurPitchPos_D <= CurPitchPos_N;
    end if;
  end process;
  
  YawPossAssign  : YawPos   <= CurYawPos_D;
  PitchPosAssign : PitchPos <= CurPitchPos_D;
end architecture rtl;
