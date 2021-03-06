-- Find a object in the middle and try to track it
-- Erik Zachrisson - erik@zachrisson.info, copyright 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity ObjectFinder is
  generic (
    DataW : positive
    );
  port (
    RstN        : in  bit1;
    Clk         : in  bit1;
    --
    Vsync       : in  bit1;
    --
    PixelIn     : in  word(DataW-1 downto 0);
    PixelInVal  : in  bit1;
    -- Vga if
    PixelOut    : out word(DataW-1 downto 0);
    PixelOutVal : out bit1;
    RectAct     : out bit1;
    -- Box if
    TopLeft     : out Cord;
    BottomRight : out Cord
    );
end entity;

architecture rtl of ObjectFinder is
  signal TopLeft_N, TopLeft_D         : Cord;
  signal BottomRight_N, BottomRight_D : Cord;
  --
  signal PixelCnt_N, PixelCnt_D       : word(FrameWW-1 downto 0);
  signal LineCnt_N, LineCnt_D         : word(FrameHW-1 downto 0);
  --
  signal PixelOut_N, PixelOut_D       : word(DataW-1 downto 0);
  --
  -- Set low threshold for now
  constant Threshold                  : natural  := 2;
  --
  constant Levels                     : positive := 3;
  signal IncY0_N, IncY0_D             : word(Levels downto 0);
  signal IncY1_N, IncY1_D             : word(Levels downto 0);
  signal IncX0_N, IncX0_D             : word(Levels downto 0);
  signal IncX1_N, IncX1_D             : word(Levels downto 0);
  --
  signal DecY0_N, DecY0_D             : word(Levels-1 downto 0);
  signal DecY1_N, DecY1_D             : word(Levels-1 downto 0);
  signal DecX0_N, DecX0_D             : word(Levels-1 downto 0);
  signal DecX1_N, DecX1_D             : word(Levels-1 downto 0);

  signal TrackLost_N, TrackLost_D : bit1;

  function calcDelta(D : word) return word is
    variable delta : word(bits(D'length)-1 downto 0);
    variable NormD : word(D'length-1 downto 0);
  begin
    NormD := D;
    delta := (others => '0');
    for i in 0 to D'length-1 loop
      if NormD(i) = '1' then
        delta := delta + 1;
      end if;
    end loop;
    return delta;  
  end function;
             
begin
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      TopLeft_D     <= MiddleOfScreen;
      BottomRight_D <= MiddleOfScreen;
      --
      PixelCnt_D    <= (others => '0');
      LineCnt_D     <= (others => '0');
      --
      IncY0_D       <= (others => '0');
      IncY1_D       <= (others => '0');
      IncX0_D       <= (others => '0');
      IncX1_D       <= (others => '0');
      DecY0_D       <= (others => '0');
      DecY1_D       <= (others => '0');
      DecX0_D       <= (others => '0');
      DecX1_D       <= (others => '0');
      TrackLost_D   <= '0';

    elsif rising_edge(Clk) then
      TopLeft_D     <= TopLeft_N;
      BottomRight_D <= BottomRight_N;
      --
      PixelCnt_D    <= PixelCnt_N;
      LineCnt_D     <= LineCnt_N;
      --
      IncY0_D       <= IncY0_N;
      IncY1_D       <= IncY1_N;
      IncX0_D       <= IncX0_N;
      IncX1_D       <= IncX1_N;
      DecY0_D       <= DecY0_N;
      DecY1_D       <= DecY1_N;
      DecX0_D       <= DecX0_N;
      DecX1_D       <= DecX1_N;
      TrackLost_D   <= TrackLost_N;
    end if;
  end process;
  
  AsyncProc : process (TopLeft_D, BottomRight_D, PixelIn, PixelInVal, PixelCnt_D, LineCnt_D, IncY0_D, IncY1_D, IncX0_D, IncX1_D, DecY0_D, DecY1_D, DecX0_D, DecX1_D, TrackLost_D)
    variable TmpRectAct : bit1;
    variable delta : word(bits(Levels)-1 downto 0);
  begin
    TopLeft_N     <= TopLeft_D;
    BottomRight_N <= BottomRight_D;
    PixelCnt_N    <= PixelCnt_D;
    LineCnt_N     <= LineCnt_D;
    RectAct       <= '0';
    --
    IncY0_N       <= IncY0_D;
    IncY1_N       <= IncY1_D;
    IncX0_N       <= IncX0_D;
    IncX1_N       <= IncX1_D;
    --
    DecY0_N       <= DecY0_D;
    DecY1_N       <= DecY1_D;
    DecX0_N       <= DecX0_D;
    DecX1_N       <= DecX1_D;
    --
    TrackLost_N   <= TrackLost_D;
    TmpRectAct := '0';

    if PixelInVal = '1' then
      -- Pixel counting
      PixelCnt_N <= PixelCnt_D + 1;
      if PixelCnt_D + 1 = FrameW then
        -- End of line
        PixelCnt_N <= (others => '0');
        LineCnt_N <= LineCnt_D + 1;
        if LineCnt_D + 1 = FrameH then
          LineCnt_N <= (others => '0');
          -- End of frame
          -- Clear frame history
          IncY0_N <= (others => '0');
          IncY1_N <= (others => '0');
          IncX0_N <= (others => '0');
          IncX1_N <= (others => '0');
          --
          DecY0_N <= (others => '0');
          DecY1_N <= (others => '0');
          DecX0_N <= (others => '0');
          DecX1_N <= (others => '0');

          if IncY0_D > 0 then
            if TopLeft_D.Y - IncY0_D(Levels downto 1) > 0 then
              TopLeft_N.Y <= TopLeft_D.Y - calcDelta(IncY0_D(Levels downto 1));
            end if;
          elsif DecY0_D > 0 then
            if (TopLeft_D.Y + DecY0_D < FrameH) and (TopLeft_D.Y + DecY0_D < BottomRight_D.Y) then
              TopLeft_N.Y <= TopLeft_D.Y + calcDelta(DecY0_D);
            end if;
          else
            -- If inactive, try to crawl back to middle
            if TopLeft_D.Y > MiddleYOfScreen then
              TopLeft_N.Y <= TopLeft_D.Y - 1;
            else
              TopLeft_N.Y <= TopLeft_D.Y + 1;
            end if;
          end if;
          
          if IncY1_D > 0 then
            if BottomRight_D.Y + IncY1_D(Levels downto 1) < FrameH then
              BottomRight_N.Y <= BottomRight_D.Y + calcDelta(IncY1_D(Levels downto 1));
            end if;
          elsif DecY1_D > 0 then
            if (BottomRight_D.Y - DecY1_D > 0) and (BottomRight_D.Y - DecY1_D > TopLeft_D.Y) then
              BottomRight_N.Y <= BottomRight_D.Y - calcDelta(DecY1_D);
            end if;
          else
            if BottomRight_D.Y > MiddleYOfScreen then
              BottomRight_N.Y <= BottomRight_D.Y - 1;
            else
              BottomRight_N.Y <= BottomRight_D.Y + 1;
            end if;
          end if;

          if IncX0_D > 0 then
            if TopLeft_D.X - IncX0_D(Levels downto 1) > 0 then
              TopLeft_N.X <= TopLeft_D.X - calcDelta(IncX0_D(Levels downto 1));
            end if;
          elsif DecX0_D > 0 then
            if (TopLeft_D.X + DecX0_D < FrameW) and (TopLeft_D.X + DecX0_D < BottomRight_D.X) then
              TopLeft_N.X <= TopLeft_D.X + calcDelta(DecX0_D);
            end if;
          else
            if TopLeft_D.X > MiddleXOfScreen then
              TopLeft_N.X <= TopLeft_D.X - 1;
            else
              TopLeft_N.X <= TopLeft_D.X + 1;
            end if;
          end if;

          if IncX1_D > 0 then
            if BottomRight_D.X + IncX1_D(Levels downto 1) < FrameW then
              BottomRight_N.X <= BottomRight_D.X + calcDelta(IncX1_D(Levels downto 1));
            end if;
          elsif DecX1_D > 0 then
            if (BottomRight_D.X - DecX1_D > 0) and (BottomRight_D.X - DecX1_D > TopLeft_D.X) then
              BottomRight_N.X <= BottomRight_D.X - calcDelta(DecX1_D);
            end if;
          else
            if BottomRight_D.X > MiddleXOfScreen then
              BottomRight_N.X <= BottomRight_D.X - 1;
            else
              BottomRight_N.X <= BottomRight_D.X + 1;
            end if;
          end if;

          -- No rect was drawn this frame. We've lost track, reset to default
          if TrackLost_D = '1' then
            TopLeft_N     <= MiddleOfScreen;
            BottomRight_N <= MiddleOfScreen;
          end if;
          -- Set trap for next frame
          TrackLost_N <= '1';
        end if;
      end if;

      -- Try to grow upper boundary, y0
      for i in Levels downto 0 loop
        if ((LineCnt_D = TopLeft_D.Y-i) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X))) then
          if PixelIn >= Threshold then
            IncY0_N(i) <= '1';
          end if;
        end if;

        -- Try to grow lower boundary, y1
        if ((LineCnt_D = BottomRight_D.Y+i) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X))) then
          if PixelIn >= Threshold then
            IncY1_N(i) <= '1';
          end if;
        end if;

        -- Try to grow left boundary, x0
        if ((PixelCnt_D = TopLeft_D.X-i) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)))  then
          if PixelIn >= Threshold then
            IncX0_N(i) <= '1';
          end if;
        end if;

        -- Try to grow right boundary, x1
        if ((PixelCnt_D = BottomRight_D.X+i) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)))  then
          if PixelIn >= Threshold then
            IncX1_N(i) <= '1';
          end if;
        end if;        
      end loop;

      for i in Levels downto 1 loop
        if ((LineCnt_D = TopLeft_D.Y+i) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X))) then
          if PixelIn < Threshold then
            DecY0_N(i-1) <= '1';
          end if;
        end if;

        if ((LineCnt_D = BottomRight_D.Y-i) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X))) then
          if PixelIn < Threshold then
            DecY1_N(i-1) <= '1';
          end if;
        end if;

        if ((PixelCnt_D = TopLeft_D.X+i) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)))  then
          if PixelIn < Threshold then
            DecX0_N(i-1) <= '1';
          end if;
        end if;
        
        if ((PixelCnt_D = BottomRight_D.X-i) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y))) then
          if PixelIn < Threshold then
            DecX1_N(i-1) <= '1';
          end if;
        end if;
      end loop;
    end if;

    -- Draw rectangle
    -- Top, y0 line
    if (LineCnt_D = TopLeft_D.Y) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X)) then
      TmpRectAct := '1';
    end if;

    -- Bottom, y1 line
    if (LineCnt_D = BottomRight_D.Y) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X)) then
      TmpRectAct := '1';
    end if;

    -- Left, x0 line
    if (PixelCnt_D = TopLeft_D.X) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)) then
      TmpRectAct := '1';
    end if;

    -- Right, x1 line
    if (PixelCnt_D = BottomRight_D.X) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)) then
      TmpRectAct := '1';
    end if;

    if TmpRectAct = '1' then
      TrackLost_N <= '0';
    end if;
    
    RectAct <= TmpRectAct;
  end process;

  TopLeftAssign     : TopLeft     <= TopLeft_D;
  BottomRightAssign : BottomRight <= BottomRight_D;
  PixelOutAssign    : PixelOut    <= PixelIn;
  PixelOutValAssign : PixelOutVal <= PixelInVal;
end architecture rtl;
