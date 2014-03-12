FILES=OV76X0Pack.vhd \
	AsyncFifo.vhd \
	FakeVgaCam.vhd \
	FloydSteinberg2PRAM.vhd \
	DitherFloydSteinberg.vhd \
	OV7660Init.vhd \
	OV76X0Filter.vhd \
	OV76X0Pack.vhd \
	Pll.vhd \
	PixelAligner.vhd \
	PrewittFilter2PRAM.vhd \
	PrewittFilter.vhd \
	SccbAddrReader.vhd \
	SccbCtrl.vhd \
	SccbMasterNextGen.vhd \
	SccbMaster.vhd \
	SramArbiter.vhd \
	tb.vhd \
	VGAGenerator.vhd \
	VideoCapturer.vhd \
	VideoController.vhd \
	VideoPacker.vhd \
	OV76X0Top.vhd \
	tb.vhd

QUARTUS_PATH=/opt/altera/13.0sp1/quartus

VMAP=vmap
VLIB=vlib
WORK_DIR=/tmp/work
MODELSIMINI_PATH=/home/erik/Development/FPGA/OV76X0/modelsim.ini
CC=vcom
FLAGS=-work /tmp/work -93 -modelsimini $(MODELSIMINI_PATH)

all: work altera_mf altera lib sramcontroller vhdlfiles

clean:
	rm -rf *~ rtl_work *.wlf transcript

lib:
	@$(MAKE) -C ../Lib -f ../Lib/Makefile

sramcontroller:
	@$(MAKE) -C ../SramTest-IS61LV25616AL -f ../SramTest-IS61LV25616AL/Makefile

work:
	$(VLIB) $(WORK_DIR)

altera:
	$(VLIB) /tmp/altera
	$(VMAP) altera /tmp/altera
	$(CC) -work altera -2002 \
		-explicit $(QUARTUS_PATH)/eda/sim_lib/altera_primitives_components.vhd \
		-explicit $(QUARTUS_PATH)/eda/sim_lib/altera_primitives.vhd

.PHONY: altera_mf
altera_mf:
	$(VLIB) /tmp/altera_mf
	$(VMAP) altera_mf /tmp/altera_mf
	$(CC) -work altera_mf -2002 \
		-explicit $(QUARTUS_PATH)/eda/sim_lib/altera_mf_components.vhd \
		-explicit $(QUARTUS_PATH)/eda/sim_lib/altera_mf.vhd


vhdlfiles:
	$(CC) $(FLAGS) $(FILES)

