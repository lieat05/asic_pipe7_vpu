#ifndef __SDB_H__
#define __SDB_H__

#include "isa.h"
#include "memory.h"
typedef struct watchpoint {
  int NO;
  char EXPR[32];
  uint32_t last_result;
  int change_time;
  struct watchpoint *next;

} WP;

uint32_t expr(char *e, bool *success);
void init_wp_pool();
bool new_wp(char *args);
void free_wp(int N);
void print_wp();
bool watch_wp();

#endif
