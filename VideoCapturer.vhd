library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

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
		PixelVal : out bit1
	);

end entity;

architecture rtl of VideoCapturer is 
	signal RstNPClk : bit1;
	
	signal ValData_N, ValData_D : bit1;
	signal PixelData_N, PixelData_D : word(DataW-1 downto 0);
	signal SeenVsync_N, SeenVsync_D : bit1;
	--
	signal FifoEmpty : bit1;
	signal RdFifo : bit1;
	signal FifoRdVal_N, FifoRdVal_D : bit1;
	signal RdData : word(DataW-1 downto 0);
	
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
			PixelData_D <= (others => '0');
			ValData_D <= '0';
			SeenVsync_D <= '0';
		elsif rising_edge(PCLK) then
			PixelData_D <= PixelData_N;
			ValData_D   <= ValData_N;
			SeenVsync_D <= SeenVsync_N;
		end if;
	end process;
	
	PClkAsync : process (PixelData, PixelData_D, Href, Vsync, SeenVsync_D)
	begin
		PixelData_N <= PixelData_D;
		ValData_N <= '0';
		SeenVsync_N <= SeenVsync_D;

		if (Vsync = '1' ) then
			SeenVsync_N <= '1';
		end if;

		if Href = '1' and SeenVsync_D = '1' then
			ValData_N <= '1';
			PixelData_N <= PixelData;
		end if;
	end process;
	
	ClkCrossingFifo : entity work.AsyncFifo
	port map (
		data    => PixelData_D,
		wrclk   => PClk,
		wrreq   => ValData_D,
		--
		rdclk   => Clk,
		rdempty => FifoEmpty,
		rdreq   => RdFifo,
		q       => RdData
	);
	RdFifo <= not FifoEmpty;

	ClkAsync : process (FifoRdVal_D, RdFifo)
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
		elsif rising_edge(Clk) then
			FifoRdVal_D <= FifoRdVal_N;
		end if;
	end process;	
	
	PixelOut <= RdData;
	PixelVal <= FifoRdVal_D;
end architecture;