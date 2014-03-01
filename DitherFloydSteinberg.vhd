library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0pack.all;

entity DitherFloydSteinberg is
	generic (
		DataW : positive := 8;
		CompDataW : positive := 3
	);
	port (
	RstN     : in bit1;
	Clk      : in bit1;
	--
	Vsync    : in bit1;
	--
	ToggleEnable : in bit1;
	--
	PixelInVal : in bit1;
	PixelIn    : in word(DataW-1 downto 0);
	--
	PixelOutVal : out bit1;
	PixelOut    : out word(CompDataW-1 downto 0)
	);
end entity;

architecture rtl of DitherFloydSteinberg is
	constant TruncBits : positive := DataW-CompDataW;
	constant MaxTruncErr : positive := 2**TruncBits-1;
	constant MaxError : positive := 7 * MaxTruncErr + 3 * MaxTruncErr + 5 * MaxTruncErr + 1 * MaxTruncErr;
	constant MaxErrorW : positive := bits(MaxError);
	constant RightErrFact : positive := 7;
	--
	signal ClosestPixelVal : word(CompDataW-1 downto 0);
	signal Error : word(TruncBits-1 downto 0);
	--
	signal RightErr_N, RightErr_D : word(MaxErrorW-1 downto 0);
	signal AdjPixelIn : word(DataW-1 downto 0);
	--
	signal PixelOutVal_N, PixelOutVal_D : bit1;
	signal PixelOut_N, PixelOut_D : word(CompDataW-1 downto 0);
	--
	constant LookAheadBufs : positive := 3;
	type ErrorVector is array (natural range <>) of word(MaxErrorW-1 downto 0);
	signal ErrorVect_N, ErrorVect_D : ErrorVector(LookAheadBufs-1 downto 0);
	
	signal LineCnt_N, LineCnt_D : word(FrameHW-1 downto 0);
	signal PixelCnt_N, PixelCnt_D : word(bits(FrameW)-1 downto 0);

	signal FromErrMem, ToErrMem : word(MaxErrorW-1 downto 0);
	signal WrAddr, RdAddr : word(bits(FrameW)-1 downto 0);
	
	signal Enabled_N, Enabled_D : bit1;
	
	--Pixel 1, 0
	--1. Add error from right error to pixel (contains prev. right err and error_vector error)
	--2. Round pixel
	--3. Calculate error
	--4. Propagate error
	--     7/16 East, OK, read error_vector[1], low,  and add the result and push right
	--     3/16 South west, N/A [n-1], ok to set anyways?
	--     5/16 South, OK, error vector [0], Set new error value
	--     1/16 South East, OK, error vector [1], write new error
	--[n-1][0][1]
	--5. Write upper slice to memory address PixelCnt_D -1 = n-1
	--6. Shift slices one step (9 bits to the right): [0] [1] [X]
	--7. Read next bits PixelCnt_D + 2 = 2: [0] [1] [2]
	--5. Output truncated pixel
	
	signal IncPixelPlusErr : word(DataW downto 0);
	signal PixelInExt : word(DataW downto 0);
begin
	PixelInExt <= '0' & PixelIn;
	-- Divide error by 16
	IncPixelPlusErr <= conv_word(conv_integer(PixelInExt) + (conv_integer(RightErr_D) / 16), IncPixelPlusErr'length);
	
	PixelValCalc : process  (PixelIn, IncPixelPlusErr, Enabled_D)
		variable Err : word(DataW-1 downto 0);
	begin
		-- Check for overflow
		if (IncPixelPlusErr(IncPixelPlusErr'high) = '1') then
			-- Max pixel and min error
			AdjPixelIn <= xt1(DataW-CompDataW) & xt0(CompDataW);
		else
			AdjPixelIn <= IncPixelPlusErr(DataW-1 downto 0);
		end if;
		
		if Enabled_D = '0' then
			AdjPixelIn <= PixelIn;
		end if;
	end process;

	ClosestPixelVal <= AdjPixelIn(DataW-1 downto TruncBits);
	Error           <= AdjPixelIn(TruncBits-1 downto 0);
	
	SyncProc : process (RstN, Clk)
	begin
		if RstN = '0' then
			RightErr_D    <= (others => '0');
			PixelOutVal_D <= '0';
			PixelOut_D    <= (others => '0');
			ErrorVect_D   <= (others => (others => '0'));
			PixelCnt_D    <= (others => '0');
			LineCnt_D     <= (others => '0');
			Enabled_D     <= '1';
		elsif rising_edge(Clk) then
			RightErr_D <= RightErr_N;
			PixelOutVal_D <= PixelOutVal_N;
			PixelOut_D <= PixelOut_N;
			ErrorVect_D <= ErrorVect_N;
			PixelCnt_D <= PixelCnt_N;
			LineCnt_D   <= LineCnt_N;
			Enabled_D   <= Enabled_N;
		end if;
	end process;
	
	AsyncProc : process (RightErr_D, PixelInVal, Error, PixelOut_D,
								ClosestPixelVal, PixelCnt_D, ErrorVect_D,
								FromErrMem, LineCnt_D, Vsync, Enabled_D)
	begin
		LineCnt_N <= LineCnt_D;
		RightErr_N <= RightErr_D;
		PixelOut_N <= PixelOut_D;
		PixelOutVal_N <= '0';
		PixelCnt_N <= PixelCnt_D;
		ErrorVect_N <= ErrorVect_D;
		
		Enabled_N <= Enabled_D;
		if (ToggleEnable = '0') then
			Enabled_N <= not Enabled_D;
		end if;

		ToErrMem <= ErrorVect_D(0) + conv_word(3 * conv_integer(Error), MaxErrorW);
		-- Zero out error on end of frame
		if (LineCnt_D = FrameH-1) then
			ToErrMem <= (others => '0');
		end if;

		if (PixelInVal = '1') then
			-- 7/16 East, OK, read error_vector[1], low,  and add the result and push right
			-- 3/16 South west, N/A [n-1], ok to set anyways?
			-- 5/16 South, OK, error vector [0], Set new error value
			-- 1/16 South East, OK, error vector [1], write new error
			RightErr_N        <= conv_word(7 * conv_integer(Error), MaxErrorW) + ErrorVect_D(2);
			-- Do not propagate error on the end of the line
			if (PixelCnt_D = FrameW-1) then
				RightErr_N <= (others => '0');
			end if;
			--
			ErrorVect_N(0)    <= ErrorVect_D(1) + conv_word(5 * conv_integer(Error), MaxErrorW);
			ErrorVect_N(1)    <= xt0(Error, MaxErrorW);
			ErrorVect_N(2)    <= FromErrMem;

			PixelOutVal_N <= '1';
			PixelOut_N    <= ClosestPixelVal;

			PixelCnt_N    <= PixelCnt_D + 1;
			if (PixelCnt_D = FrameW-1) then 
				PixelCnt_N <= (others => '0');
				LineCnt_N <= LineCnt_D + 1;
				if (LineCnt_D = FrameH-1) then
					LineCnt_N <= (others => '0');
				end if;
			end if;
		end if;
		
		if (Vsync = '1') then
			PixelCnt_N <= (others => '0');
			LineCnt_N <= (others => '0');
		end if;
	end process;
	
	AddrCalc : process (PixelCnt_D)
	begin
		WrAddr <= PixelCnt_D - 1;
		RdAddr <= PixelCnt_D + 2;
		
		if PixelCnt_D = 0 then
			WrAddr <= conv_word(FrameW-1, WrAddr'length);
		end if;

		if PixelCnt_D = FrameW-2 then
			RdAddr <= conv_word(0, RdAddr'length);
		elsif PixelCnt_D = FrameW-1 then
			RdAddr <= conv_word(1, RdAddr'length);
		end if;
	end process;
	
	ErrorMemory : entity work.FloydSteinberg2PRAM
	port map (
		clock     => Clk,
		data      => ToErrMem,
		rdaddress => RdAddr,
		wraddress => WrAddr,
		--
		wren      => PixelInVal,
		--
		q         => FromErrMem
	);
	
	PixelOut <= PixelOut_D;
	PixelOutVal <= PixelOutVal_D;
end architecture rtl;
