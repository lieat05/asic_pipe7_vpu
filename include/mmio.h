#ifndef __MMIO_H__
#define __MMIO_H__

#include "memory.h"

#ifdef CONFIG_DIFFTEST
void difftest_skip_ref();
#endif

#define PAGE_SHIFT        12
#define PAGE_SIZE         (1ul << PAGE_SHIFT)
#define PAGE_MASK         (PAGE_SIZE - 1)

typedef void(*io_callback_t)(uint32_t, int, bool);

uint8_t* new_space(int size);

typedef struct {
  const char *name;
  uint32_t  low;
  uint32_t  high;
  void *space;
  io_callback_t callback;
} IOMap;

static inline bool map_inside(IOMap *map, uint32_t  addr) {
  return (addr >= map->low && addr <= map->high);
}

static inline int find_mapid_by_addr(IOMap *maps, int size, uint32_t  addr) {
  int i;
  for (i = 0; i < size; i ++) {
    if (map_inside(maps + i, addr)) {
      return i;
    }
  }
  return -1;
}

void add_mmio_map(const char *name, uint32_t  addr,
        void *space, uint32_t len, io_callback_t callback);

uint32_t  map_read(uint32_t  addr, int len, IOMap *map);
void map_write(uint32_t  addr, int len, uint32_t  data, IOMap *map);

uint32_t  mmio_read(uint32_t  addr, int len);
void mmio_write(uint32_t  addr, int len, uint32_t  data);

#endif
