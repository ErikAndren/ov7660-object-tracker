#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition
#
#************************************************************

# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.

set_false_path -from [get_ports {AsyncRstN}] -to *
set_false_path -from [get_ports {Button1}] -to *
set_false_path -from [get_ports {Button2}] -to *
set_false_path -from [get_ports {Button3}] -to *

# Clock constraints

create_clock -name "Clk" -period 20.000ns [get_ports {Clk}]

create_generated_clock -name PixelClk -source Clk -divide_by 2 [get_registers {VGAGenerator:VgaGen|PixelClk}]

# create_clock -name "PCLK" -period 40.000ns [get_ports {PCLK}]

create_generated_clock -name Clk64kHz -source Clk [get_registers {ClkDiv:Clk64kHzGen|divisor}] -divide_by 32000 

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# set_input_delay -clock { Pll|altpll_component|pll|clk[0] } -max 15 -min 8 [get_ports {D[0] D[1] D[2] D[3] D[4] D[5] D[6] D[7] HREF VSYNC}]

# Automatically calculate clock uncertainty to jitter and other effects.

derive_clock_uncertainty

# Not supported for family Cyclone II
# tsu/th constraints

# tco constraints

# tpd constraints

