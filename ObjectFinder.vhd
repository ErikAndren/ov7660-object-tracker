-- Find a object in the middle and try to track it
-- Erik Zachrisson - erik@zachrisson.info
--

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
    --
    PixelOut    : out word(DataW-1 downto 0);
    PixelOutVal : out bit1;
    RectAct     : out bit1
    );
end entity;

architecture rtl of ObjectFinder is
  type Cord is
  record
    X : word(FrameWW-1 downto 0);
    Y : word(FrameHW-1 downto 0);
  end record;

  constant Z_Cord : Cord :=
    (X => (others => '0'),
     Y => (others => '0'));

  constant MiddleXOfScreen : natural := FrameW/2;
  constant MiddleYOfScreen : natural := FrameH/2;

  constant MiddleOfScreen : Cord :=
    (X => conv_word(MiddleXOfScreen, FrameWW),
     Y => conv_word(MiddleYOfScreen, FrameHW));
  
  signal TopLeft_N, TopLeft_D       : Cord;
  signal BottomRight_N, BottomRight_D : Cord;

  signal PixelCnt_N, PixelCnt_D : word(FrameWW-1 downto 0);
  signal LineCnt_N, LineCnt_D   : word(FrameHW-1 downto 0);

  signal PixelOutVal_N, PixelOutVal_D : bit1;
  signal PixelOut_N, PixelOut_D       : word(DataW-1 downto 0);
  
  -- Set low threshold for now
  constant Threshold : natural := 1;

  signal OnEdge : bit1;
             
begin
  SyncProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      TopLeft_D      <= MiddleOfScreen;
      BottomRight_D  <= MiddleOfScreen;
      PixelCnt_D     <= (others => '0');
      LineCnt_D      <= (others => '0');
      PixelOutVal_D  <= '0';
      PixelOut_D     <= (others => '0');
    elsif rising_edge(Clk) then
      TopLeft_D      <= TopLeft_N;
      BottomRight_D  <= BottomRight_N;
      PixelCnt_D     <= PixelCnt_N;
      LineCnt_D      <= LineCnt_N;
      PixelOut_D     <= PixelOut_N;
      PixelOutVal_D  <= PixelOutVal_N;
    end if;
  end process;

  OnEdge <= '1' when LineCnt_D = 0 or LineCnt_D = FrameH-1 or
                     PixelCnt_D = 0 or PixelCnt_D = FrameW-1 else '0';

  PixelOut_N    <= PixelIn;
  PixelOutVal_N <= PixelInVal;
  
  AsyncProc : process (TopLeft_D, BottomRight_D, PixelIn, PixelInVal, PixelCnt_D, LineCnt_D, OnEdge)
  begin
    TopLeft_N      <= TopLeft_D;
    BottomRight_N  <= BottomRight_D;
    PixelCnt_N     <= PixelCnt_D;
    LineCnt_N      <= LineCnt_D;
    RectAct        <= '0';

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
        end if;
      end if;

      --if PixelIn < Threshold then
      --  -- If no valid pixel is found on the top line, reduce one step, gravitate back to middle
      --  if (LineCnt_D = TopLeft_D.Y) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X)) then
      --      DecY0_N <= '1';
      --  end if;


    --  if TopLeft_D.Y > MiddleYOfScreen then
        --    TopLeft_N.Y <= TopLeft_D.Y - 1;
        --  elsif TopLeft_D.Y < MiddleYOfScreen then
        --    TopLeft_N.Y <= TopLeft_D.Y + 1;
        --  end if;
        --end if;

        ---- If no valid pixel is found, gravitate back to middle
        --if (LineCnt_D = BottomRight_D.Y) and (PixelCnt_D = BottomRight_D.X) then
        --  if BottomRight_D.Y > MiddleYOfScreen then
        --    BottomRight_N.Y <= BottomRight_D.Y - 1;
        --  elsif BottomRight_D.Y < MiddleYOfScreen then
        --    BottomRight_N.Y <= BottomRight_D.Y + 1;
        --  end if;
        --end if;

        ---- If no valid pixel is found, gravitate back to middle
        --if (PixelCnt_D = BottomRightLeft_D.X) and (LineCnt_D = BottomRightLeft_D.Y) then
        --  if BottomRightLeft_D.X > MiddleXOfScreen then
        --    BottomRightLeft_N.X <= BottomRightLeft_D.X - 1;
        --  elsif BottomRightLeft_D.X < MiddleXOfScreen then
        --    BottomRightLeft_N.X <= BottomRightLeft_D.X + 1;
        --  end if;
        --end if;

        --if (PixelCnt_D = TopRight_D.X) and (LineCnt_D = TopRight_D.Y) then
        --  if TopRight_D.X > MiddleXOfScreen then
        --    TopRight_N.X <= TopRight_D.X - 1;
        --  elsif TopRight_D.X < MiddleXOfScreen then
        --    TopRight_N.X <= TopRight_D.X + 1;
        --  end if;
        --end if;
      -- end if;

      if PixelIn >= Threshold and OnEdge = '0' then
        -- Try to grow upper boundary, y0
        if ((LineCnt_D = TopLeft_D.Y-1) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X))) then          
          TopLeft_N.Y <= LineCnt_D;
        end if;
        
        -- Try to grow lower boundary, y1
        if ((LineCnt_D = BottomRight_D.Y+1) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X))) then
          BottomRight_N.Y <= LineCnt_D;
        end if;
        
        -- Try to grow left boundary, x0
        if ((PixelCnt_D = TopLeft_D.X-1) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)))  then
          TopLeft_N.X <= PixelCnt_D;
        end if;
        
        -- Try to grow right boundary, x1
        if ((PixelCnt_D = BottomRight_D.X+1) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)))  then
          BottomRight_N.X <= PixelCnt_D;
        end if;
      end if;
    end if;

    -- Draw rectangle
    -- Top, y0 line
    if (LineCnt_D = TopLeft_D.Y) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X)) then
      RectAct <= '1';
    end if;

    -- Bottom, y1 line
    if (LineCnt_D = BottomRight_D.Y) and ((PixelCnt_D >= TopLeft_D.X) and (PixelCnt_D <= BottomRight_D.X)) then
      RectAct <= '1';
    end if;

    -- Left, x0 line
    if (PixelCnt_D = TopLeft_D.X) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)) then
      RectAct <= '1';
    end if;

    -- Right, x1 line
    if (PixelCnt_D = BottomRight_D.X) and ((LineCnt_D >= TopLeft_D.Y) and (LineCnt_D <= BottomRight_D.Y)) then
      RectAct <= '1';
    end if;
  end process;

  PixelOutAssign    : PixelOut    <= PixelOut_D;
  PixelOutValAssign : PixelOutVal <= PixelOutVal_D;  
end architecture rtl;
