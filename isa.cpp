#include "include/isa.h"
#include "include/memory.h"
//---------------------------------regs----------------------
CPU_state cpu;

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
	for( int i=0; i<32;i++){
		printf(ANSI_FG_CYAN "%s	: %x \n", regs[i],cpu.gpr[i]);
	}
	printf("mstatus : %x \n",cpu.csr[0]);
	printf("mtvec : %x \n",cpu.csr[1]);
	printf("mepc : %x \n",cpu.csr[2]);
	printf("mcause : %x \n",cpu.csr[3]);
	printf("pc is %x \n" ANSI_NONE,cpu.pc);
}

uint32_t isa_reg_str2val(const char *s, bool *success) {
  *success=true;
  for(int i=0 ; i < 32 ; i++){
    if(strcmp(s + 1, regs[i])==0){
      return cpu.gpr[i];
    }
  }
  if(strcmp(s,"$pc")==0){
    return cpu.pc;
  }
  *success=false;
  
  return 0;
}

bool isa_difftest_checkregs(CPU_state *ref_r, uint32_t pc) {
  bool check = true;
  for (int i = 0; i < 32; ++i){
    if (ref_r->gpr[i]!= cpu.gpr[i]){
      Log("for [%s], expected %x, but got %x.", regs[i], ref_r->gpr[i], cpu.gpr[i]);
      check = false;
    }
  }
  if (ref_r->pc == pc){
    return check;
  }
  else {
    Log("PC expected %x but got %x", ref_r->pc, pc);
    return false;
  }
}

//---------------------------------regs----------------------
//-------------------------isa_init--------------------------
const static uint32_t img [] = {
  0x00000413,          	//li	s0,0
  0x00009117,          	//auipc	sp,0x9
  0xffc10113,          	//addi	sp,sp,-4 # 80009000 <_end>
  0x00c000ef,          	//jal	ra,80000018 <_trm_init>
  0x00000513,          	//li	a0,0
  0x00008067,          	//ret
  0xff410113,          	//addi	sp,sp,-12
  0x00000517,          	//auipc	a0,0x0
  0x01c50513,          	//addi	a0,a0,28 # 80000038 <_etext>
  0x00112423,          	//sw	ra,8(sp)
  0xfe9ff0ef,          	//jal	ra,80000010 <main>
  0x00050513,          	//mv	a0,a0
  0x00100073,          	//ebreak
  0x0000006f,          	//j	80000034 <_trm_init+0x1c>
};

void init_isa() {
  memcpy(guest_to_host(CONFIG_PCSTART), img, sizeof(img));
}