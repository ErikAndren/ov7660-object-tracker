library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SccbMaster is
	generic (
		DataW : positive := 8;
		AddrW : positive := 8;
		-- 
		ClkFreq : positive := 25000000
	);	
	port (
		Clk          : in bit1;
		Rst_N        : in bit1;
		--
		Addr         : in word(AddrW-1 downto 0);
		We           : in bit1;
		Re           : in bit1;
		Data         : in word(DataW-1 downto 0);
		DataFromSccb : out word(DataW-1 downto 0);
		Valid        : out bit1;
		--
		SIO_C        : out bit1;
		SIO_D        : inout bit1
	);
end entity;	

architecture fpga of SccbMaster is
	-- 7 bit, OV7670 W:0x42, R:0x43
	constant DeviceAddr : word(8-1 downto 0) := "01000010";
	
	constant SccbClkFreq : positive := 100000;
	constant ClkWrap    : positive := ((ClkFreq / SccbClkFreq) / 2) -1;
	-- Data is to be output 90 degrees before 
	constant DataWrap   : positive := ClkWrap / 2;
	
	signal ClkCnt_N, ClkCnt_D         : word(bits(ClkWrap)-1 downto 0);
	signal ClkFlop_N, ClkFlop_D       : bit1;
	
	signal re_n, re_d : bit1;
	
	signal DataPulse : bit1;
	signal rw_i_n, rw_i_d : bit1;
	signal Busy_N, Busy_D : bit1;
	signal data_i : word(16-1 downto 0);
	signal valid_i : bit1;
	signal trans_done : bit1;
	signal ack_err : bit1;
	
	component SCCBCtrl
	port (
		clk_i : in bit1;
		rst_i : in bit1;
		sccb_clk_i : in bit1;
		data_pulse_i : in bit1;
		addr_i : in word(8-1 downto 0);
		data_i : in word(16-1 downto 0);
		data_o : out word(8-1 downto 0);
		rw_i : in bit1;
		start_i : in bit1;
		ack_error_o : out bit1;
		done_o : out bit1;
		sioc_o : out bit1;
		siod_io : inout bit1
	);
	end component;
	
begin	
	data_i <= Addr & Data;
	
	SccbM : SCCBCtrl
	port map (
		clk_i => Clk,
		rst_i => Rst_N,
		--
		sccb_clk_i => ClkFlop_D,
		data_pulse_i => DataPulse,
		addr_i => DeviceAddr,
		data_i => x"0911",
		data_o => DataFromSccb,
		rw_i => '1',
		start_i => Busy_N,
		ack_error_o => ack_err,
		done_o => trans_done,
		sioc_o => SIO_C,
		siod_io => SIO_D
	);
	
	valid <= not ack_err;
	
	ClkDivSync : process (Clk, Rst_N)
	begin
		if Rst_N = '0' then
			ClkCnt_D  <= (others => '0');
			ClkFlop_D <= '0';
			Busy_D    <= '0';
			rw_i_d    <= '0';
			re_d      <= '0';
		elsif rising_edge(Clk) then
			ClkCnt_D  <= ClkCnt_N;
			ClkFlop_D <= ClkFlop_N;
			Busy_D    <= Busy_N;
			rw_i_d    <= rw_i_n;
			re_d      <= re_n;
		end if;
	end process;

	DataPulse <= '1' when ClkFlop_D = '0' and ClkCnt_D = DataWrap else '0';
	
	FSMAsync : process (ClkCnt_D, ClkFlop_D, trans_done, Busy_D, We, Re, rw_i_d, DataPulse, re_d)
	begin		
		ClkFlop_N <= ClkFlop_D;
		ClkCnt_N  <= ClkCnt_D + 1;
		Busy_N    <= Busy_D;
		rw_i_n    <= rw_i_d;
		re_n      <= re_d;
		
		if re = '1' then
			re_n <= '1';
		end if;

		if (ClkCnt_D = ClkWrap) then
			ClkCnt_N  <= (others => '0');
			ClkFlop_N <= not ClkFlop_D;
		end if;

		if DataPulse = '1' then
			if ((re_d = '1') and Busy_D = '0') then
				Busy_N <= '1';
				rw_i_n <= We;
			end if;

			if (Busy_D = '1' and trans_done = '1') then
				Busy_N <= '0';
			end if;
			re_n <= '0';
		end if;
	end process;
end architecture;
