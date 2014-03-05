library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity PrewittFilter is 
	port (
	AsyncRst : in bit1;
	Clk      : in bit1;
	--
	Rst_N    : out bit1
	);
end entity;

architecture rtl of PrewittFilter is
begin
end architecture rtl;
