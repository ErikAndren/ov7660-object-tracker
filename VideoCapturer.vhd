library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VideoCapturer is
	generic (
		DataW : positive := 8
	);
	port (
		PRstN : in bit1;
		PClk : in bit1;
		--
		RstN : in bit1;
		Clk : in bit1;
		--
		Vsync : in bit1;
		Href : in bit1;
		PixelData : in word(DataW-1 downto 0);
		--
		PixelOut : out word(DataW-1 downto 0);
		PixelVal : out bit1;
		FillLevel : out word(3-1 downto 0);
		Vsync_Clk : out bit1
	);

end entity;

architecture rtl of VideoCapturer is 
	signal RstNPClk : bit1;
	
	signal ValData_N, ValData_D : bit1;
	signal PixelData_N, PixelData_D : word(DataW-1 downto 0);
	signal SeenVsync_N, SeenVsync_D : word(4-1 downto 0);
	--
	signal FifoEmpty : bit1;
	signal RdFifo : bit1;
	signal FifoRdVal_N, FifoRdVal_D : bit1;
	signal RdData : word(DataW-1 downto 0);
	
	signal PixelOut_D : word(DataW-1 downto 0);
	signal PixelVal_D : bit1;
	
	signal Delay_N, Delay_D : word(20-1 downto 0);
	signal Href_D, Vsync_D : bit1;
	
	signal VSync_META, VSync_D_Clk : bit1;
begin
	PClkRstSync : entity work.ResetSync
	port map (
		AsyncRst => PRstN,
		Clk      => PClk,
		--
		Rst_N    => RstNPClk
	);
	
	PClkSync : process (PCLK, RstNPClk)
	begin
		if RstNPClk = '0' then
			PixelData_D  <= (others => '0');
			ValData_D    <= '0';
			SeenVsync_D  <= (others => '0');
			Href_D       <= '0';
			Vsync_D      <= '0';
			Delay_D      <= (others => '0');
		elsif rising_edge(PCLK) then
			PixelData_D  <= PixelData_N;
			ValData_D    <= ValData_N;
			SeenVsync_D  <= SeenVsync_N;
			Href_D       <= Href;
			Vsync_D      <= vsync;
			Delay_D      <= Delay_N;
		end if;
	end process;
	
	-- Only capture two first frames
	PClkAsync : process (PixelData, Href_D, Vsync_D, SeenVsync_D, Delay_D)
	begin
		PixelData_N <= PixelData;
		ValData_N   <= '0';
		SeenVsync_N <= SeenVsync_D;
		Delay_N     <= Delay_D;

		if (RedAnd(Delay_D) = '0') then
			Delay_N <= Delay_D + 1;
		end if;

		-- Initial gating to ensure that we start to capture at the start of a frame
		if (RedAnd(SeenVsync_D) = '1') then
			null;
 		elsif (Vsync_D = '1' and RedAnd(Delay_D) = '1') then
			SeenVsync_N <= SeenVsync_D + 1;
		else
			SeenVSync_N <= (others => '0');
		end if;

		if Href_D = '1' and RedAnd(SeenVsync_D) = '1' then
			ValData_N <= '1';
		end if;
	end process;
	
	ClkCrossingFifo : entity work.AsyncFifo
	port map (
		data    => PixelData_D,
		wrclk   => PClk,
		wrreq   => ValData_N,
		--
		rdclk   => Clk,
		rdempty => FifoEmpty,
		rdreq   => RdFifo,
		q       => RdData,
		--
		rdusedw => FillLevel,
		wrfull  => open
	);
	RdFifo <= not FifoEmpty;

	ClkAsync : process (RdFifo)
	begin
		FifoRdVal_N <= '0';
	
		if RdFifo = '1' then
			FifoRdVal_N <= '1';
		end if;
	end process;

	ClkSync : process (RstN, Clk)
	begin
		if RstN = '0' then
			FifoRdVal_D <= '0';
			PixelOut_D <= (others => '0');
			PixelVal_D <= '0';
			VSync_META <= '0';
			VSync_D_Clk    <= '0';

		elsif rising_edge(Clk) then
			FifoRdVal_D <= FifoRdVal_N;
			PixelOut_D <= RdData;
			PixelVal_D <= FifoRdVal_D;
			VSync_META <= VSync;
			
			-- FIXME: Add threshold?
			VSync_D_Clk    <= VSync_META;
		end if;
	end process;	
	
	PixelOut <= PixelOut_D;
	PixelVal <= PixelVal_D;
	Vsync_Clk <= Vsync_D_Clk;
end architecture;