#ifndef __ISA_H__
#define __ISA_H__

#include "common.h"

typedef struct 
{
  uint32_t gpr[32];
  uint32_t pc;
  uint32_t vpr[32];
  uint32_t csr[11];
  uint32_t difftest_valid;
} CPU_state;

extern const char *regs[];

extern CPU_state cpu;

void init_isa();

void isa_reg_display();

uint32_t isa_reg_str2val(const char *name, bool *success);

bool isa_difftest_checkregs(CPU_state *ref_r, uint32_t pc);

#endif