library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity PrewittFilter is
  generic (
    DataW     : positive := 8;
    CompDataW : positive := 3
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
    PixelOutVal : out bit1;
    PixelOut    : out word(CompDataW-1 downto 0)
    );
end entity;

architecture rtl of PrewittFilter is
    function MaxValue(OldVal : word; NewVal : word; Mul : integer := 1) return word is
    variable tmp : word(OldVal'length downto 0);
    variable NewValExt : word(NewVal'length-1+(Mul-1) downto 0);
    variable val1, val2 : integer;
    variable sum : integer;
  begin
    val1 := conv_integer(OldVal);
    val2 := conv_integer(NewVal) * Mul;
    
    sum := minval(val1 + val2, 255);
    return conv_word(sum, OldVal'length);
  end function;

  function MinValue(OldVal : word; NewVal : word; Mul : natural := 1) return word is
    variable tmp       : word(OldVal'length downto 0);
    variable NewValExt : word(NewVal'length-1+(Mul-1) downto 0);
    variable val1, val2 : integer;
    variable dif : integer;
  begin
    val1 := conv_integer(OldVal);
    val2 := conv_integer(NewVal) * Mul;
    dif := val1 - val2;
    if (dif < 0) then
      return conv_word(0, OldVal'length);
    end if;
    return conv_word(dif, OldVal'length);
  end function;

  function CalcValue(OldVal : word; PixelIn : word; Mult : integer) return word is
  begin
    if (Mult = 0) then
      return OldVal;
    elsif (Mult > 0) then
      return MaxValue(OldVal, PixelIn, Mult);
    else
      return MinValue(OldVal, PixelIn, Mult);
    end if;
  end function;
    
  signal PixelCnt_D, PixelCnt_N : word(bits(FrameW)-1 downto 0);
  signal LineCnt_D, LineCnt_N : word(bits(FrameH)-1 downto 0);

  type PixelArray is array (natural range <>) of word(8-1 downto 0);
  type PixelArray2D is array (natural range <>) of PixelArray(3-1 downto 0);
  type IntArray is array (natural range <>) of integer;
  type IntArray2D is array (natural range <>) of IntArray(3-1 downto 0);

  -- The following matrix is used:
  --  0  1  2
  -- -1  X  1
  -- -2 -1  0

  -- In a software implementation you would look at all surrounding pixels and
  -- calculate a new value. This is hard to implement in hardware as we do not
  -- know all surrounding pixels until all have passed.
  -- Then the first pixels are all long gone.
  -- Instead, flip the concept:
  -- Upon each arriving pixel, calculate its impact upon all surround pixels
  -- according to the weights chosen
  -- This means that from the perspective of p(0, 0)
  -- the incoming pixel is p(2, 2);
  -- For p(0, 1) = p(2, 1)
  -- For p(0, 2) = p(2, 0)
    
  constant PrewittWeights    : IntArray2D := (( 0,  1,  2),
                                              (-1,  0,  1),
                                              (-2, -1,  0));
    
  constant InvPrewittWeights : IntArray2D := (( 0, -1, -2),
                                              ( 1,  0, -1),
                                              ( 2,  1,  0));

  -- Create 3x3 array
  signal PixArr_N, PixArr_D : PixelArray2D(3-1 downto 0);
  
  signal WriteToMem, ReadFromMem : PixelArray(3-1 downto 0);
  signal WriteAddr, ReadAddr : word(bits(FrameW)-1 downto 0);

  signal LastLine : bit1;
  
  function CalcMem(LineCnt : word; Offs : integer) return natural is
    variable Cnt, AdjOffs : integer;
  begin
    -- Offset offset by one. We want to calculate -1, 0, 1
    AdjOffs := Offs - 1;
    
    Cnt := conv_integer(LineCnt) + AdjOffs;

    return Cnt mod 3;
  end function;
begin
  SyncProc : process (RstN, Clk)
  begin
    if RstN = '0' then
      PixelCnt_D <= (others => '0');
      LineCnt_D  <= (others => '0');
      PixArr_D   <= (others => (others => (others => '0')));
    elsif rising_edge(Clk) then
      PixelCnt_D <= PixelCnt_N;
      LineCnt_D  <= LineCnt_N;
      PixArr_D   <= PixArr_N;
    end if;
  end process;

  LastLine <= '1' when LineCnt_D = FrameH else '0';
  
  AsyncProc : process (PixelCnt_D, LineCnt_D, PixelInVal, Vsync, PixArr_D, LastLine)
    variable PixArr : PixelArray2D(3-1 downto 0);
  begin
    PixelCnt_N  <= PixelCnt_D;
    LineCnt_N   <= LineCnt_D;
    PixArr_N    <= PixArr_D;
    PixArr      := PixArr_D;
    --
    PixelOutVal <= '0';
    PixelOut    <= (others => '0');

    -- Need to run the line after the last
    if (PixelInVal = '1' or LastLine = '1') then
      -- Calculate the impact on all surround pixels according to the
      -- predefined weights
      for i in 0 to 3-1 loop
        for j in 0 to 3-1 loop
          PixArr(i)(j) := CalcValue(PixArr_D(i)(j), PixelIn, InvPrewittWeights(i)(j));
        end loop;
      end loop;
      
      -- Shift data
      for i in 0 to 3-1 loop
        -- On line 0 mapping is:
        -- 0 -> 2 -- ignored
        -- 1 -> 0
        -- 2 -> 1
 
        -- On line 1 mapping is:
        -- 0 -> 0 -- pixel out 
        -- 1 -> 1
        -- 2 -> 2

        -- On line 2 mapping is:
        -- 0 -> 1 -- pixel out
        -- 1 -> 2
        -- 2 -> 0
        
        -- On line 3 mapping is:
        -- 0 -> 2 -- pixel out 
        -- 1 -> 0
        -- 2 -> 1
       
        -- On line 479 mapping is:
        -- 0 -> 2 -- pixel out 
        -- 1 -> 0
        -- 2 -> 1

        -- Flush out left column of pixels to memory
        -- WriteToMem(CalcMem(LineCnt_D, i)) <= PixArr(i)(0);
        WriteToMem(CalcMem(LineCnt_D, i)) <= PixArr(i)(0);
        --
        -- Shift pixel memory one step
        PixArr_N(i)(0) <= PixArr(i)(1);
        PixArr_N(i)(1) <= PixArr(i)(2);
        --
        -- Calculate which memory that maps where
        PixArr_N(i)(2) <= ReadFromMem(CalcMem(LineCnt_D, i));
      end loop;

      -- Start to output data on the second line
      if (LineCnt_D > 0) then
        PixelOutVal <= '1';

        -- FIXME: Thresholding function here?
        -- Slice out the 3 MSBs for now. (Dithering?)
        PixelOut    <= WriteToMem(CalcMem(LineCnt_D, 0))(WriteToMem(0)'high downto WriteToMem(0)'high-PixelOut'high);
        -- Clear pixel memory
        WriteToMem(0) <= (others => '0');
      end if;  

      PixelCnt_N <= PixelCnt_D + 1;
      if (PixelCnt_D = FrameW-1) then
        PixelCnt_N <= (others => '0');
        LineCnt_N <= LineCnt_D + 1;
        -- Run one line more than the image height to flush out the result of
        -- the last line
        if (LineCnt_D = FrameH) then
          LineCnt_N <= (others => '0');
        end if;
      end if;
    end if;

    if (Vsync = '1') then
      PixelCnt_N <= (others => '0');
      LineCnt_N  <= (others => '0');
    end if;
  end process;

  AddrCalc : process (PixelCnt_D) is
  begin
    ReadAddr <= PixelCnt_D + 2;
    if (PixelCnt_D = FrameW-2) then
      ReadAddr <= (others => '0');
    elsif (PixelCnt_D = FrameW-1) then
      ReadAddr <= conv_word(1, ReadAddr'length);
    end if;

    WriteAddr <= PixelCnt_D-1;
    if (PixelCnt_D = 0) then
      WriteAddr <= conv_word(FrameW-1, WriteAddr'length);
    end if;
  end process;

  RAMGen : for i in 0 to 3-1 generate
    R : entity work.PrewittFilter2PRAM
      port map (
        clock     => Clk,
        data      => WriteToMem(i),
--        wren      => PixelIn,
        rdaddress => ReadAddr,
        wraddress => WriteAddr,
        q         => ReadFromMem(i)
        );
  end generate;
  
end architecture rtl;
