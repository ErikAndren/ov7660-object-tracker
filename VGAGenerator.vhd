library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity VGAGenerator is
	generic (
		DivideClk : boolean := true
	);
	port (
	Clk    : in bit1;
	--
	DataToDisplay : in word(3-1 downto 0);
	--
	Red    : out bit1;
	Green  : out bit1;
	Blue   : out bit1;
	HSync  : out bit1;
	VSync  : out bit1
	);
end entity;

architecture rtl of VGAGenerator is
	signal PixelClk : bit1;

	constant hsync_end: positive := 95;
	constant hdat_begin : positive := 143;
	constant hdat_end : positive := 783;
	constant hpixel_end : positive := 799;
	constant vsync_end : positive := 1;
	constant vdat_begin : positive := 34;
	constant vdat_end : positive := 514;
	constant vline_end : positive := 524;
	
	signal hCount : word(10-1 downto 0);
	signal vCount : word(10-1 downto 0);
	signal data : word(3-1 downto 0);
	signal h_dat : word(3-1 downto 0);
	signal v_dat : word(3-1 downto 0);
	signal hCount_ov : bit1;
	signal vCount_ov : bit1;
	--
	signal dat_act : bit1;
begin

	DivClkGen : if DivideClk = true generate
		ClkDiv : process (Clk)
		begin
			if rising_edge(Clk) then
				PixelClk <= not PixelClk;
			end if;
		end process;
	end generate;
	
	NoDivClkGen : if DivideClk = false generate
		PixelClk <= Clk;
	end generate;
	
	hcount_ov <= '1' when hcount = hpixel_end else '0';
	HCnt : process (PixelClk)
	begin
		if rising_edge(PixelClk) then
			if (hcount_ov = '1') then
				hcount <= (others => '0');
			else
				hcount <= hcount + 1;
			end if;
		end if;
	end process;
	
	vcount_ov <= '1' when vcount = vline_end else '0';
	VCnt : process (PixelClk)
	begin
		if rising_edge(PixelClk) then
			if (hcount_ov = '1') then
				if (vcount_ov = '1') then
						vcount <= (others => '0');
				else
					vcount <= vcount + 1;
				end if;
			end if;
		end if;
	end process;
	
	dat_act <= '1' when ((hcount >= hdat_begin) and (hcount < hdat_end)) and ((vcount >= vdat_begin) and (vcount < vdat_end)) else '0';
	Hsync <= '1' when hcount > hsync_end else '0';
	Vsync <= '1' when vcount > vsync_end else '0';
	
	Red   <= '0' when dat_act = '0' else DataToDisplay(0);
	Green <= '0' when dat_act = '0' else DataToDisplay(1);
	Blue  <= '0' when dat_act = '0' else DataToDisplay(2);
end architecture rtl;