
FILES=../Lib/Types.vhd \
      ../Lib/Debounce.vhd


MODELSIMINI_PATH=/home/erik/Development/FPGA/OV76X0/modelsim.ini
CC=vcom
FLAGS=-work /tmp/work -93 -modelsimini $(MODELSIMINI_PATH)

all: vhdlfiles

clean:
	rm -rf *~ rtl_work *.wlf transcript

vhdlfiles:
	$(CC) $(FLAGS) $(FILES)
