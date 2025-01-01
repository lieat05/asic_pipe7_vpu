#include "include/memory.h"
#include "include/isa.h"
#include "include/mmio.h"
// ================================================================================================================================================
// MAP
// ================================================================================================================================================
#define IO_SPACE_MAX (2 * 1024 * 1024)

static uint8_t *io_space = NULL;
static uint8_t *p_space = NULL;

uint8_t* new_space(int size) {
  uint8_t *p = p_space;
  size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
  p_space += size;
  assert(p_space - io_space < IO_SPACE_MAX);
  return p;
}

static void check_bound(IOMap *map, uint32_t addr) {
  if (map == NULL) {
    Assert(map != NULL, "address ( 0x%08x ) is out of bound at pc = 0x%08x", addr, cpu.pc);
  } else {
    Assert(addr <= map->high && addr >= map->low,
        "address ( 0x%08x ) is out of bound {%s} [ 0x%08x , 0x%08x ] at pc = 0x%08x",
        addr, map->name, map->low, map->high, cpu.pc);
  }
}

static void invoke_callback(io_callback_t c, uint32_t offset, int len, bool is_write) {
  if (c != NULL) { c(offset, len, is_write); }
}

void init_map() {
  io_space = (uint8_t*)malloc(IO_SPACE_MAX);
  assert(io_space);
  p_space = io_space;
}

uint32_t map_read(uint32_t addr, int len, IOMap *map) {
  assert(len >= 1 && len <= 8);
  check_bound(map, addr);
  uint32_t offset = addr - map->low;
  invoke_callback(map->callback, offset, len, false); // prepare data to read
  uint32_t ret = host_read((uint32_t *)map->space + offset, len);
  return ret;
}

void map_write(uint32_t addr, int len, uint32_t data, IOMap *map) {
  assert(len >= 1 && len <= 8);
  check_bound(map, addr);
  uint32_t offset = addr - map->low;
  host_write((uint32_t *)map->space + offset, len, data);
  invoke_callback(map->callback, offset, len, true);
  }
// ================================================================================================================================================
// MMIO
// ================================================================================================================================================
#define NR_MAP 16

static IOMap maps[NR_MAP] = {};
static int nr_map = 0;

static IOMap* fetch_mmio_map(uint32_t addr) {
  int mapid = find_mapid_by_addr(maps, nr_map, addr);
  return (mapid == -1 ? NULL : &maps[mapid]);
}

static void report_mmio_overlap(const char *name1, uint32_t l1, uint32_t r1,
    const char *name2, uint32_t l2, uint32_t r2) {
  panic("MMIO region %s@[ 0x%08x , 0x%08x ] is overlapped "
               "with %s@[ 0x%08x , 0x%08x ]", name1, l1, r1, name2, l2, r2);
}

/* device interface */
void add_mmio_map(const char *name, uint32_t addr, void *space, uint32_t len, io_callback_t callback) {
  assert(nr_map < NR_MAP);
  uint32_t left = addr, right = addr + len - 1;
  if (in_pmem(left) || in_pmem(right)) {
    report_mmio_overlap(name, left, right, "pmem", PMEM_LEFT, PMEM_RIGHT);
  }
  for (int i = 0; i < nr_map; i++) {
    if (left <= maps[i].high && right >= maps[i].low) {
      report_mmio_overlap(name, left, right, maps[i].name, maps[i].low, maps[i].high);
    }
  }

  maps[nr_map] = (IOMap){ .name = name, .low = addr, .high = addr + len - 1,
    .space = space, .callback = callback };
  Log("Add mmio map '%s' at [ 0x%08x , 0x%08x ]",
      maps[nr_map].name, maps[nr_map].low, maps[nr_map].high);

  nr_map ++;
}

uint32_t mmio_read(uint32_t addr, int len) {
  #ifdef CONFIG_DTRACE
  printf("map_read addr = %x, len = %d, data = %d\n",addr,len,map_read(addr, len, fetch_mmio_map(addr)));
  #endif
  return map_read(addr, len, fetch_mmio_map(addr));
}

void mmio_write(uint32_t addr, int len, uint32_t data) {
  #ifdef CONFIG_DTRACE
  printf("map_write addr = %x, len = %d, data = %d\n",addr,len,data);
  #endif
  map_write(addr, len, data, fetch_mmio_map(addr));
}
