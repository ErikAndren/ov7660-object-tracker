# Build the simulation environment

vsim tb -novopt -t 1ps -lib /tmp/work  

source simulation/run_tb.tcl
