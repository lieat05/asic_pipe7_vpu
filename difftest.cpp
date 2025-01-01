#include "include/isa.h"
#include <dlfcn.h>
#include "include/memory.h"
#include "include/utils.h"
#ifdef CONFIG_DIFFTEST

int diff_skip  = 0;
int diff_sync  = 0;
int diff_syncrd = 0;
uint32_t diff_dnpc = 0;
uint32_t diff_syncdata = 0;

static size_t diff_img_size = 0;
void (*ref_difftest_memcpy)(uint32_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_skip)(uint64_t n) = NULL;
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

static bool diff_onemoreskip = false;
bool is_diff_on = true;
CPU_state ref_nemu;

void ref_difftest_regset(CPU_state *ref){
  CPU_state ref_r;
  ref_difftest_regcpy(&ref_r,DIFFTEST_TO_DUT);
  for(int i = 0; i < 32; i++){
    ref->gpr[i] = ref_r.gpr[i];
  }
  ref->gpr[diff_syncrd] = diff_syncdata;
}

void init_difftest(char *ref_so_file, long img_size)
{
  assert(ref_so_file != NULL);
  
  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);
  
  ref_difftest_memcpy = (void (*)(uint32_t addr, void *buf, size_t n, bool direction))(dlsym(handle, "difftest_memcpy"));
  assert(ref_difftest_memcpy);
  
  ref_difftest_regcpy = (void (*)(void *dut, bool direction))(dlsym(handle, "difftest_regcpy"));
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t n))(dlsym(handle, "difftest_exec"));
  assert(ref_difftest_exec);

  ref_difftest_skip = (void (*)(uint64_t n))(dlsym(handle, "difftest_skip"));
  assert(ref_difftest_skip);

  void (*ref_difftest_init)() = (void (*)())(dlsym(handle, "difftest_init"));
  assert(ref_difftest_init);
  
  ref_difftest_init();
  ref_difftest_memcpy(CONFIG_MBASE, guest_to_host(CONFIG_MBASE), CONFIG_MSIZE, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
  diff_img_size = img_size;
}

static void checkregs(CPU_state *ref, uint32_t pc) {
  if (!isa_difftest_checkregs(ref, pc)) {
    npc_state.state = NPC_ABORT;
    npc_state.halt_pc = pc;
    isa_reg_display();
  }
}

#ifdef CONFIG_DIFFTEST_SKIP
void difftest_step() {
  if(is_diff_on){
  CPU_state ref_r;
    if (diff_skip){
      diff_onemoreskip = false;
      ref_difftest_skip(1);
      if(diff_sync){
        ref_difftest_regset(&ref_r);
        ref_difftest_regcpy(&ref_r, DIFFTEST_TO_REF);
      }
      IFDEF(CONFIG_DIFTRACE,ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);printf("nemu.pc = %x npc.pc = %x\n",ref_r.pc,cpu.pc););
      return;
    }
    if(diff_onemoreskip){
      diff_onemoreskip = false;
      ref_difftest_skip(1);
      IFDEF(CONFIG_DIFTRACE,ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);printf("nemu.pc = %x npc.pc = %x\n",ref_r.pc,cpu.pc););
      return;
    }
    ref_difftest_skip(1);
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    IFDEF(CONFIG_DIFTRACE,printf("nemu.pc = %x npc.pc = %x no skip\n",ref_r.pc,cpu.pc););
    checkregs(&ref_r, cpu.pc);
    }
}
#endif
#ifdef CONFIG_DIFFTEST_EXEC
void difftest_step() {
  if(is_diff_on){
    if (diff_skip){
      diff_onemoreskip = false;
      ref_difftest_exec(1);
      IFDEF(CONFIG_DIFTRACE,ref_difftest_regcpy(&ref_nemu, DIFFTEST_TO_DUT);printf("nemu.pc = %x npc.pc = %x\n",ref_nemu.pc,cpu.pc););
      return;
    }
    if(diff_onemoreskip){
      diff_onemoreskip = false;
      ref_difftest_exec(1);
      IFDEF(CONFIG_DIFTRACE,ref_difftest_regcpy(&ref_nemu, DIFFTEST_TO_DUT);printf("nemu.pc = %x npc.pc = %x\n",ref_nemu.pc,cpu.pc););
      return;
    }
    ref_difftest_exec(1);
    ref_difftest_regcpy(&ref_nemu, DIFFTEST_TO_DUT);
    IFDEF(CONFIG_DIFTRACE,printf("nemu.pc = %x npc.pc = %x no skip\n",ref_nemu.pc,cpu.pc););
    checkregs(&ref_nemu, cpu.pc);
    }
}
#endif
#endif
// ================================================================================================================================================
// DIFFTEST DPI-C
// ================================================================================================================================================
extern "C" void difftest_dut_csrs(uint32_t mstatus, uint32_t mtvec, uint32_t mepc, uint32_t mcause){
    cpu.csr[0] = mstatus; cpu.csr[1] = mtvec; cpu.csr[2] = mepc; cpu.csr[3] = mcause;
}

extern "C" void difftest_dut_regs(uint32_t pc, uint32_t Z0,uint32_t ra, uint32_t sp, uint32_t gp, uint32_t tp, uint32_t t0, uint32_t t1, uint32_t t2,
uint32_t fp, uint32_t s1, uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5,
uint32_t a6, uint32_t a7, uint32_t s2, uint32_t s3, uint32_t s4, uint32_t s5, uint32_t s6, uint32_t s7,
uint32_t s8, uint32_t s9, uint32_t s10, uint32_t a11, uint32_t t3, uint32_t t4, uint32_t t5, uint32_t t6){
  cpu.pc = pc;
  cpu.gpr[0] = Z0;  cpu.gpr[1] = ra;  cpu.gpr[2]  = sp; cpu.gpr[3]  = gp; cpu.gpr[4]  = tp; cpu.gpr[5]  = t0; cpu.gpr[6]  = t1; cpu.gpr[7]  = t2;
  cpu.gpr[8] = fp;  cpu.gpr[9] = s1;  cpu.gpr[10] = a0; cpu.gpr[11] = a1; cpu.gpr[12] = a2; cpu.gpr[13] = a3; cpu.gpr[14] = a4; cpu.gpr[15] = a5;
  cpu.gpr[16] = a6; cpu.gpr[17] = a7; cpu.gpr[18] = s2; cpu.gpr[19] = s3; cpu.gpr[20] = s4; cpu.gpr[21] = s5; cpu.gpr[22] = s6; cpu.gpr[23] = s7;
  cpu.gpr[24] = s8; cpu.gpr[25] = s9; cpu.gpr[26] = s10;cpu.gpr[27] = a11;cpu.gpr[28] = t3; cpu.gpr[29] = t4; cpu.gpr[30] = t5; cpu.gpr[31] = t6;
}

extern "C" void difftest_dut_sync(uint32_t diff_tag, uint32_t sync_data){
	cpu.difftest_valid = (diff_tag % 256 - diff_tag % 128)/128;
  #ifdef CONFIG_DIFFTEST
  diff_skip          = (diff_tag % 128 - diff_tag % 64 )/64;
  diff_sync          = (diff_tag % 64  - diff_tag % 32 )/32;
  diff_syncrd        = diff_tag % 32;
  diff_syncdata      = sync_data;
  #endif
}
