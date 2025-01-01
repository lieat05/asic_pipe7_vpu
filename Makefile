include /usr/local/share/verilator/include/verilated.mk
OBJ_PATH = ./obj_dir/
CC   = g++
C_SCRS = *.cpp
SOC_SCRS = $(shell find /home/lieat/Desktop/ysyx-workbench/ysyxSoC/perip -name "*.v")
SCRS = $(C_SCRS) $(SOC_SCRS)
TOP_NAME = ysyxSoCFull
TOP = $(WORKBENCH)/ysyxSoC/build/ysyxSoCFull.v

WAVE = wave.vcd

VERI_PATH += -I$(WORKBENCH)/npc/vsrc
VERI_PATH += -I$(WORKBENCH)/npc/dpic
VERI_PATH += -I$(WORKBENCH)/ysyxSoC/perip
VERI_PATH += -I$(WORKBENCH)/ysyxSoC/perip/uart16550/rtl
VERI_PATH += -I$(WORKBENCH)/ysyxSoC/perip/spi/rtl
VERI_PATH += -I$(WORKBENCH)/ysyxSoC/build
VERILAGS = -O3 -Wall --trace --cc --exe --build --timescale "1ns/1ns" --no-timing $(VERI_PATH) -lint --unroll-count 256
VERILAGS += -CFLAGS -I$(NPC_HOME)/include

LINK = -LDFLAGS "-lreadline  --no-pie  -ldl -lLLVM-14 -lSDL2" 
LLVM = -CFLAGS "-I/usr/lib/llvm-14/include -std=c++14   -fno-exceptions -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS   -D__STDC_LIMIT_MACROS -fPIE"

NPCTOP_NAME = lieat_top
NPCTOP = dpic/$(NPCTOP_NAME).v
NPCSCRS = $(C_SCRS)
NPCVERI_PATH += -I$(WORKBENCH)/npc/vsrc
NPCVERI_PATH += -I$(WORKBENCH)/npc/dpic
NPCVERI_PATH += -I$(WORKBENCH)/npc/vpu
NPCVERI_PATH += -I$(WORKBENCH)/npc/fpu
NPCVERI_PATH += -I$(WORKBENCH)/ysyxSoC/build
NPCVERILAGS = -O3 -Wall --trace --cc --exe --build --timescale "1ns/1ns" --timing $(NPCVERI_PATH) -autoflush --unroll-count 256
NPCVERILAGS += -CFLAGS -I$(NPC_HOME)/include

.PHONY:clean soc sim npcsim git
git:
$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
sim:git
	@verilator $(VERILAGS) $(LINK) $(LLVM) $(SCRS) $(TOP) --top-module $(TOP_NAME)
	$(OBJ_PATH)V$(TOP_NAME) $(NPC_FLAGS) $(NPC_IMG)
npcsim:git
	@verilator $(NPCVERILAGS) $(LINK) $(LLVM) $(NPCSCRS) $(NPCTOP) --top-module $(NPCTOP_NAME)
	$(OBJ_PATH)V$(NPCTOP_NAME) $(NPC_FLAGS) $(NPC_IMG)
soc:
	@cat vsrc/*.v vpu/*.v fpu/*.* > ~/Desktop/ysyx_22040000.v
clean:
	@rm -rf obj_dir $(WAVE)
include ../Makefile
