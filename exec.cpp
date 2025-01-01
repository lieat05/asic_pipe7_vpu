#include "include/trace.h"
#include "include/sdb.h"
void device_update();
void difftest_step();

static void trace_and_difftest(int n) {
  if((n == 1))step_trace();
  IFDEF(CONFIG_DIFFTEST,difftest_step(););
  IFDEF(CONFIG_WATCHPOINT,if(watch_wp() == false) npc_state.state = NPC_STOP;);
  g_nr_inst_num ++;
}

static void exec_once() {
  isa_exec_once();
}

static void execute(uint64_t n) {
  for (;n > 0; n --) {
    exec_once();
    if(cpu.difftest_valid)trace_and_difftest(n);
    g_nr_exec_cycle ++;
    IFDEF(CONFIG_DEVICE, device_update());
    if (npc_state.state != NPC_RUNNING) break;
  }
}

void cpu_exec(uint64_t n) {
  switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }
  
  uint64_t timer_start = get_time();
  
  execute(n);
  
  uint64_t timer_end = get_time();
  
  g_timer += timer_end - timer_start;
  
  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;
    case NPC_ABORT: 
      IFDEF(CONFIG_ITRACE,print_iringbuf(););
      IFDEF(CONFIG_FTRACE,print_ftrace(););
    case NPC_END:
      Log("npc: %s at" ANSI_FG_CYAN " pc = 0x%08x"   ANSI_NONE,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) : (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)))
          ,npc_state.halt_pc);
    case NPC_QUIT: statistic();
  }
}
