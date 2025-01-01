#ifndef __UTILS_H__
#define __UTILS_H__
enum { NPC_RUNNING, NPC_STOP, NPC_END, NPC_ABORT, NPC_QUIT };

typedef struct{
  int state;
  uint32_t halt_pc;
  uint32_t halt_ret;
} NPC_State;

extern NPC_State npc_state;
#endif