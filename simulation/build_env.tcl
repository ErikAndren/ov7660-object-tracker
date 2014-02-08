# Build the simulation environment

set path_to_quartus /opt/altera/13.0sp1/quartus

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlib altera_mf
vmap altera_mf altera_mf
vcom -work altera_mf -2002 -explicit $path_to_quartus/eda/sim_lib/altera_mf_components.vhd
vcom -work altera_mf -2002 -explicit $path_to_quartus/eda/sim_lib/altera_mf.vhd

vlib altera
vmap altera altera
vcom -work altera -2002 -explicit $path_to_quartus/eda/sim_lib/altera_primitives_components.vhd
vcom -work altera -2002 -explicit $path_to_quartus/eda/sim_lib/altera_primitives.vhd

# required for gate-level simulation of CYCLONEII designs
vlib cycloneii
vmap cycloneii cycloneii
vcom -work cycloneii -2002 -explicit $path_to_quartus/eda/sim_lib/cycloneii_atoms.vhd
vcom -work cycloneii -2002 -explicit $path_to_quartus/eda/sim_lib/cycloneii_components.vhd

vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/AsyncFifo.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/Lib/Types.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/Lib/Debounce.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/output_files/Pll.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/OV76X0Pack.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/VGAGenerator.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/VideoCompressor.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/SramTest-IS61LV25616AL/SramController.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/Lib/ResetSync.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/SccbCtrl.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/OV7660Init.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/Lib/BcdPack.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/VideoController.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/VideoPacker.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/SramArbiter.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/VideoCapturer.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/SccbMaster.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/Lib/BcdDisp.vhd}
vcom -93 -work work {/home/erik/Development/FPGA/OV76X0/OV76X0Top.vhd}

vcom -93 {/home/erik/Development/FPGA/OV76X0/tb.vhd}

vsim tb -novopt -t 1ps
log -r /*
# run 10 ms
