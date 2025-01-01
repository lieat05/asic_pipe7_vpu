#include "common.h"
static Vlieat_top* top;
VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;

int flush_times = 0;
int icache_hit_times = 0;
int icache_miss_times = 0;
int dcache_hit_times = 0;
int dcache_miss_times = 0;

void cpu_init() {
  top -> reset = 1;
  for(int a = 0; a < 10; a++){
  top -> clock = 0;
  top -> eval();
  contextp->timeInc(1);
  top -> clock = 1;
  top -> eval();
  contextp->timeInc(1);
  }
  top -> reset = 0;
  top -> clock = 0;
  top -> eval();
  contextp->timeInc(1);
}

void isa_exec_once() {
  top -> clock = 1;
  top -> eval();
  #ifdef CONFIG_WAVE
  if(contextp->time() > RECORD_TIME) tfp -> dump(contextp->time()-RECORD_TIME);
  #endif
  contextp->timeInc(1);
  top -> clock = 0;
  top -> eval();
  #ifdef CONFIG_WAVE
  if(contextp->time() > RECORD_TIME) tfp -> dump(contextp->time()-RECORD_TIME);
  #endif
  contextp->timeInc(1);
}

int main(int argc, char* argv[]) {
  Verilated::commandArgs(argc, argv);
  contextp = new VerilatedContext;
  contextp -> commandArgs(argc,argv);
  top = new Vlieat_top{contextp};
  tfp = new VerilatedVcdC;
  #ifdef CONFIG_WAVE
  Verilated::traceEverOn(true);
  top->trace(tfp,0);
  tfp->open("wave.vcd");
  #endif
  init_monitor(argc,argv);
  cpu_init();
  sdb_mainloop();
  printf("Flush : %d times\n",flush_times);
  printf("Icache: %d times total, %d times hit, %d times miss\n",icache_hit_times+icache_miss_times,icache_hit_times,icache_miss_times);
  printf("Dcache: %d times total, %d times hit, %d times miss\n",dcache_hit_times+dcache_miss_times,dcache_hit_times,dcache_miss_times);
  tfp -> close();
  delete top;
  delete contextp;
  exit(0);
}

// ================================================================================================================================================
// DPI-C
// ================================================================================================================================================
extern "C" void ebreak(int halt_pc, int halt_ret){
  npc_state.halt_pc = halt_pc;
  npc_state.halt_ret = halt_ret;
  npc_state.state = NPC_END;
}
extern "C" void flush_dpic(int flush_count){
  flush_times = flush_count;
}
extern "C" void icache_dpic(int hit_count,int miss_count){
  icache_hit_times = hit_count;
  icache_miss_times = miss_count;
}

extern "C" void dcache_dpic(int hit_count,int miss_count){
  dcache_hit_times = hit_count;
  dcache_miss_times = miss_count;
}
