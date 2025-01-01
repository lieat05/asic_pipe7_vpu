#include "include/trace.h"
// ================================================================================================================================================
// STATISTIC
// ================================================================================================================================================
NPC_State npc_state = { .state = NPC_QUIT };
uint32_t g_timer;
uint32_t g_nr_exec_cycle = 0;
uint32_t g_nr_inst_num = 0;

void step_trace(){
    printf( ANSI_FG_CYAN "pc: %08x\n" ANSI_NONE,cpu.pc);
}

void statistic() {
    Log("host time spent =  %d  us", g_timer);
    Log("total guest instructions = %d, total take %d cycles" , g_nr_inst_num , g_nr_exec_cycle);
    if (g_timer > 0) Log("simulation frequency = %d inst/s", g_nr_inst_num * 1000 / g_timer * 1000);
    else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}
// ================================================================================================================================================
// MTRACE
// ================================================================================================================================================
void print_read_mtrace(uint32_t raddr, uint64_t rdata,char rlen){
    printf(ANSI_FG_CYAN "Mtrace read   addr:%08x    data:%lx    len:%d\n" ANSI_NONE,raddr,rdata,rlen);
}

void print_write_mtrace(uint32_t waddr, uint64_t wdata,char wlen){
    printf(ANSI_FG_CYAN "Mtrace write  addr:%08x    data:%lx    len:%d\n" ANSI_NONE,waddr,wdata,wlen);
}
// ================================================================================================================================================
// ETRACE DPI-C
// ================================================================================================================================================
void print_etrace(uint32_t mstatus, uint32_t mtvec, uint32_t mepc, uint32_t mcause){
    printf("ETRACE: mepc = %x, mcause = %d, mtvec = %x, mstatus = %d\n",mepc,mcause,mtvec,mstatus);
}

extern "C" void etrace(uint32_t mstatus, uint32_t mtvec, uint32_t mepc, uint32_t mcause){
    IFDEF(CONFIG_ETRACE,print_etrace(mstatus,mtvec,mepc,mcause));
}