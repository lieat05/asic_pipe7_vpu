#ifndef __MEMORY_H__
#define __MEMORY_H__

#include "common.h"

uint64_t host_read(void *addr, int len);

void host_write(void *addr, int len, uint64_t data);

uint8_t* guest_to_host(uint32_t paddr);

uint32_t host_to_guest(uint8_t *haddr);

void out_of_bound(uint32_t addr);

static inline bool in_pmem(uint32_t addr) {
  return (0 <= addr - CONFIG_MBASE) & (addr - CONFIG_MBASE <= CONFIG_MSIZE);
}

extern char *img_file;

long load_img();

void init_mem();

#endif
