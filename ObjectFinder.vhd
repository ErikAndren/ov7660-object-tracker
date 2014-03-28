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
  
  signal Top_N, Top_D       : Cord;
  signal Left_N, Left_D     : Cord;
  signal Bottom_N, Bottom_D : Cord;
  signal Right_N, Right_D   : Cord;

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
      Top_D         <= MiddleOfScreen;
      Left_D        <= MiddleOfScreen;
      Bottom_D      <= MiddleOfScreen;
      Right_D       <= MiddleOfScreen;
      PixelCnt_D    <= (others => '0');
      LineCnt_D     <= (others => '0');
      PixelOutVal_D <= '0';
      PixelOut_D    <= (others => '0');
    elsif rising_edge(Clk) then
      Top_D         <= Top_N;
      Left_D        <= Left_N;
      Bottom_D      <= Bottom_N;
      Right_D       <= Right_N;
      PixelCnt_D    <= PixelCnt_N;
      LineCnt_D     <= LineCnt_N;
      PixelOut_D    <= PixelOut_N;
      PixelOutVal_D <= PixelOutVal_N;

      if Vsync = '1' then
        PixelCnt_D <= (others => '0');
        LineCnt_D  <= (others => '0');
      end if;      
    end if;
  end process;

  OnEdge <= '1' when LineCnt_D = 0 or LineCnt_D = FrameH-1 or
                     PixelCnt_D = 0 or PixelCnt_D = FrameW-1 else '0';

  PixelOut_N    <= PixelIn;
  PixelOutVal_N <= PixelInVal;
  
  AsyncProc : process (Top_D, Left_D, Bottom_D, Right_D, PixelIn, PixelInVal, PixelCnt_D, LineCnt_D, OnEdge)
  begin
    Top_N      <= Top_D;
    Left_N     <= Left_D;
    Bottom_N   <= Bottom_D;
    Right_N    <= Right_D;
    PixelCnt_N <= PixelCnt_D;
    LineCnt_N  <= LineCnt_D;
    RectAct    <= '0';
    --

    if PixelInVal = '1' then
      -- Pixel counting
      PixelCnt_N <= PixelCnt_D + 1;
      if PixelCnt_D + 1 = FrameW then
        PixelCnt_N <= (others => '0');
        LineCnt_N <= LineCnt_D + 1;
        if LineCnt_D + 1 = FrameH then
          LineCnt_N <= (others => '0');
        end if;
      end if;

      if PixelIn >= Threshold and OnEdge = '0' then
        -- If no valid pixel is found, gravitate back to middle
        if Top_D.X > MiddleXOfScreen then
          Top_N.X <= Top_D.X - 1;
        elsif Top_D.X < MiddleXOfScreen then
          Top_N.X <= Top_D.X + 1;
        end if;

        if Top_D.Y > MiddleYOfScreen then
          Top_N.Y <= Top_D.Y - 1;
        elsif Top_D.Y < MiddleYOfScreen then
          Top_N.Y <= Top_D.Y + 1;
        end if;
        
        -- Grow top if valid pixel is next to current
        -- Prefer up to any other direction
        if LineCnt_D = (Top_D.Y-1) and PixelCnt_D = Top_D.X then
          Top_N.Y <= LineCnt_D;
        elsif LineCnt_D = Top_D.Y and (PixelCnt_D = Top_D.X-1 or PixelCnt_D = Top_D.X+1) then
          Top_N.X <= PixelCnt_D;          
        end if;

        -- If no valid pixel is found, gravitate back to middle
        if Bottom_D.X > MiddleXOfScreen then
          Bottom_N.X <= Bottom_D.X - 1;
        elsif Bottom_D.X < MiddleXOfScreen then
          Bottom_N.X <= Bottom_D.X + 1;
        end if;

        if Bottom_D.Y > MiddleYOfScreen then
          Bottom_N.Y <= Bottom_D.Y - 1;
        elsif Bottom_D.Y < MiddleYOfScreen then
          Bottom_N.Y <= Bottom_D.Y + 1;
        end if;
        
        -- Grow bottom if valid pixel is next to current
        -- Prefer up to any other direction
        if LineCnt_D = (Bottom_D.Y+1) and PixelCnt_D = Bottom_D.X then
          Bottom_N.Y <= LineCnt_D;
        elsif LineCnt_D = Bottom_D.Y and (PixelCnt_D = Bottom_D.X-1 or PixelCnt_D = Bottom_D.X+1) then
          Bottom_N.X <= PixelCnt_D;          
        end if;

        -- If no valid pixel is found, gravitate back to middle
        if Left_D.X > MiddleXOfScreen then
          Left_N.X <= Left_D.X - 1;
        elsif Left_D.X < MiddleXOfScreen then
          Left_N.X <= Left_D.X + 1;
        end if;

        if Left_D.Y > MiddleYOfScreen then
          Left_N.Y <= Left_D.Y - 1;
        elsif Left_D.Y < MiddleYOfScreen then
          Left_N.Y <= Left_D.Y + 1;
        end if;
        
        -- Grow left if valid pixel is next to current
        -- Prefer left to any other direction
        if LineCnt_D = Left_D.Y and PixelCnt_D = Left_D.X-1 then
          Left_N.X <= PixelCnt_D;
        elsif PixelCnt_D = Left_D.X and (LineCnt_D = Left_D.Y-1 or LineCnt_D = Left_D.Y+1) then
          Left_N.Y <= LineCnt_D;
        end if;

        if Right_D.X > MiddleXOfScreen then
          Right_N.X <= Right_D.X - 1;
        elsif Right_D.X < MiddleXOfScreen then
          Right_N.X <= Right_D.X + 1;
        end if;

        if Right_D.Y > MiddleYOfScreen then
          Right_N.Y <= Right_D.Y - 1;
        elsif Right_D.Y < MiddleYOfScreen then
          Right_N.Y <= Right_D.Y + 1;
        end if;
        
        -- Grow right if valid pixel is next to current
        -- Prefer right to any other direction
        if LineCnt_D = Right_D.Y and PixelCnt_D = Right_D.X+1 then
          Right_N.X <= PixelCnt_D;
        elsif PixelCnt_D = Right_D.X and (LineCnt_D = Right_D.Y-1 or LineCnt_D = Right_D.Y+1) then
          Right_N.Y <= LineCnt_D;
        end if;
      end if;
    end if;

    -- Draw rectangle
    -- Top line 
    if LineCnt_D = Top_D.Y and PixelCnt_D > Left_D.X and PixelCnt_D < Right_D.X then
      RectAct <= '1';
    end if;

    -- Bottom line
    if LineCnt_D = Bottom_D.Y and PixelCnt_D > Left_D.X and PixelCnt_D < Right_D.X then
      RectAct <= '1';
    end if;

    -- Left line
    if PixelCnt_D = Left_D.X and LineCnt_D > Top_D.Y and LineCnt_D < Bottom_D.Y then
      RectAct <= '1';
    end if;

    -- Right line
    if PixelCnt_D = Right_D.X and LineCnt_D > Top_D.Y and LineCnt_D < Bottom_D.Y then
      RectAct <= '1';
    end if;
  end process;

  PixelOutAssign    : PixelOut    <= PixelOut_D;
  PixelOutValAssign : PixelOutVal <= PixelOutVal_D;  
end architecture rtl;
