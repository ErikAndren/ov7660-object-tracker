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
		DataToSccb   : in word(DataW-1 downto 0);
		DataFromSccb : out word(DataW-1 downto 0);
		Valid        : out bit1;
		--
		SIO_C        : out bit1;
		SIO_D        : inout bit1
	);
end entity;	

architecture fpga of SccbMaster is
	-- 7 bit, OV7670 W:0x42, R:0x43
	constant DeviceAddr : word(7 downto 1) := "0100001";
	
	constant SccbClkFreq : positive := 100000;
	constant ClkWrap    : positive := ((ClkFreq / SccbClkFreq) / 2) -1;
	-- Data is to be output 90 degrees before 
	constant DataWrap   : positive := ClkWrap / 2;
	
	constant WriteBit : bit1 := '0';
	constant ReadBit  : bit1 := '1';
	
	signal ClkCnt_N, ClkCnt_D         : word(bits(ClkWrap)-1 downto 0);
	signal ClkFlop_N, ClkFlop_D       : bit1;
	
	signal LocStateCnt_N, LocStateCnt_D : word(4-1 downto 0);
	
	signal Re_N, Re_D : bit1;
	signal Ack_N, Ack_D : word3;
	signal ClkGate_N, ClkGate_D : bit1;
	signal Addr_N, Addr_D : word(8-1 downto 0);
	signal OpenClkGate_N, OpenClkGate_D : bit1;
	
	type SccbStates is (IDLE,
                       WRITE_PHASE_1, WRITE_PHASE_2, WRITE_PHASE_3, 
                       READ_PHASE_1, READ_PHASE_2);
	signal SccbState_N, SccbState_D : SccbStates; 
	
begin		
	ClkDivSync : process (Clk, Rst_N)
	begin
		if Rst_N = '0' then
			ClkCnt_D  <= (others => '0');
			ClkFlop_D <= '0';
			SccbState_D <= IDLE;
			Re_D <= '0';
			LocStateCnt_D <= (others => '0');
			ClkGate_D <= '1';
			Ack_D <= (others => '1');
			Addr_D <= (others => '0');
			OpenClkGate_D <= '0';
		elsif rising_edge(Clk) then
			ClkCnt_D  <= ClkCnt_N;
			ClkFlop_D <= ClkFlop_N;
			SccbState_D <= SccbState_N;
			Re_D <= Re_N;
			LocStateCnt_D <= LocStateCnt_N;
			ClkGate_D <= ClkGate_N;
			Ack_D <= Ack_N;
			Addr_D <= Addr_N;
			OpenClkGate_D <= OpenClkGate_N;
		end if;
	end process;
	
	SIO_C <= ClkFlop_D when ClkGate_D = '0' else '1';
	Valid <= Ack_D(0);
	DataFromSccb <= (others => '0');

	FSMAsync : process (ClkCnt_D, ClkFlop_D, We, Re, Re_D, LocStateCnt_D, ClkGate_D, Ack_D, SccbState_D, SIO_D, Addr_D, Addr, OpenClkGate_D)
		variable SccbEvent : boolean;
	begin		
		ClkFlop_N <= ClkFlop_D;
		ClkCnt_N  <= ClkCnt_D + 1;
		SccbState_N <= SccbState_D;
		SccbEvent := false;
		Re_N <= Re_D;
		LocStateCnt_N <= LocStateCnt_D;
		SIO_D <= 'Z';
		ClkGate_N <= ClkGate_D;
		Ack_N  <= Ack_D;
		Addr_N <= Addr_D;
		OpenClkGate_N <= OpenClkGate_D;

		if (ClkCnt_D = ClkWrap) then
			ClkCnt_N  <= (others => '0');
			ClkFlop_N <= not ClkFlop_D;
			if OpenClkGate_D = '1' then
				OpenClkGate_N <= '0';
				ClkGate_N <= '0';
			end if;
		end if;
		
		if (ClkFlop_D = '0' and ClkCnt_D = DataWrap) then
			SccbEvent := true;
		end if;

		case SccbState_D is
		when IDLE =>
			Re_N <= '0';
			LocStateCnt_N <= (others => '0');
			ClkGate_N <= '1';

			if (Re = '1') then
				ClkCnt_N <= (others => '0');
				Addr_N <= Addr;
				SccbState_N <= WRITE_PHASE_1;
				Re_N <= '1';
			end if;

		when WRITE_PHASE_1 =>
			case LocStateCnt_D is
			when "0000" =>
				SIO_D <= '1';

			when "0001" =>
				SIO_D <= '1';

			when "0010" =>
				SIO_D <= '0';
				OpenClkGate_N <= '1';

			when "0011" =>
				SIO_D <= DeviceAddr(7);
				
			when "0100" =>
				SIO_D <= DeviceAddr(6);

			when "0101" =>
				SIO_D <= DeviceAddr(5);

			when "0110" =>
				SIO_D <= DeviceAddr(4);
			
			when "0111" =>
				SIO_D <= DeviceAddr(3);

			when "1000" =>
				SIO_D <= DeviceAddr(2);

			when "1001" =>
				SIO_D <= DeviceAddr(1);

			when "1010" =>
				SIO_D <= WriteBit;

			when "1011" =>
				-- SIO_D <= '0'; -- N/A
				Ack_N(0) <= SIO_D;
	
			when others =>
				SIO_D <= '0';

			end case;
	
			if SccbEvent then
				LocStateCnt_N <= LocStateCnt_D + 1;
				if (LocStateCnt_D > "1011") then
					SccbState_N <= IDLE;
					LocStateCnt_N <= (others => '0');
				end if;
			end if;
			
		when WRITE_PHASE_2 =>
			case LocStateCnt_D is
			when "0000" =>
				SIO_D <= Addr_D(7);
			
			when "0001" =>
				SIO_D <= Addr_D(6);
				
			when "0010" =>
				SIO_D <= Addr_D(5);
				
			when "0011" =>
				SIO_D <= Addr_D(4);
				
			when "0100" =>
				SIO_D <= Addr_D(3);
				
			when "0101" =>
				SIO_D <= Addr_D(2);
				
			when "0110" =>
				SIO_D <= Addr_D(1);
				
			when "0111" =>
				SIO_D <= Addr_D(0);
				
			when "1000" =>
				Ack_N(1) <= SIO_D;
	
			when others =>
				SIO_D <= '0';

			end case;
			
			if SccbEvent then 
				if LocStateCnt_D > "1000" then
					if Re_D = '1' then
						SccbState_N <= READ_PHASE_1;
					else
						SccbState_N <= WRITE_PHASE_2;
					end if;
				end if;
			end if;
				
		when others =>
			null;
			
		end case;
	end process;
end architecture;
