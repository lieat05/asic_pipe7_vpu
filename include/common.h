#ifndef __COMMON_H__
#define __COMMON_H__

#include <verilated.h>
#include <verilated_dpi.h>//DPI-C
#include <verilated_vcd_c.h>//wave

#include "../obj_dir/Vlieat_top.h"
#include "isa.h"
#include "utils.h"

#include <assert.h>
#include <cstdint>
#include <cstdlib>
#include <getopt.h>
#include <stdio.h>
#include <cassert>
#include <cstring>
#include <elf.h>
// ================================================================================================================================================
// BASIC_CONFIG
// ================================================================================================================================================
#define CONFIG_ISA "riscv32"
#define CONFIG_ISA_riscv32 1
#define CONFIG_ISA32 1
#define CONFIG_MSIZE 0x08000000
#define CONFIG_MBASE 0x80000000
#define CONFIG_PCSTART 0x80000000
#define PMEM_LEFT  ((uint32_t)CONFIG_MBASE)
#define PMEM_RIGHT ((uint32_t)CONFIG_MBASE + CONFIG_MSIZE - 1)
// ================================================================================================================================================
// TRACE_CONFIG
// ================================================================================================================================================
#define CONFIG_DIFFTEST 1
//#define CONFIG_DIFFTEST_EXEC 1
#define CONFIG_DIFFTEST_SKIP 1
//#define CONFIG_DIFTRACE 1
//#define CONFIG_MTRACE 1
//#define CONFIG_WATCHPOINT 1
//#define CONFIG_DTRACE 1
#define CONFIG_WAVE
#define RECORD_CYCLE 0
#define RECORD_TIME  RECORD_CYCLE * 2
// ================================================================================================================================================
// DEVICE_CONFIG
// ================================================================================================================================================
#define CONFIG_DEVICE 1
#ifdef CONFIG_DEVICE
#define CONFIG_HAS_SERIAL 1
#define CONFIG_SERIAL_MMIO 0xa00003f8

#define CONFIG_HAS_TIMER 1
#define CONFIG_RTC_MMIO 0xa0000048

#define CONFIG_HAS_KEYBOARD 1
#define CONFIG_I8042_DATA_MMIO 0xa0000060

#define CONFIG_HAS_VGA 1
#define CONFIG_VGA_SHOW_SCREEN 1
#define CONFIG_VGA_CTL_MMIO 0xa0000100
#define CONFIG_FB_ADDR 0xa1000000

#define CONFIG_VGA_SIZE_400x300 1
#endif

// ================================================================================================================================================
// FUNCTION
// ================================================================================================================================================
//main.cpp
void isa_exec_once();
//monitor.cpp
void init_monitor(int argc, char *argv[]);
void init_device();
//log.cpp
void init_log(const char *log_file);
bool log_enable();
//sdb.cpp
void sdb_mainloop();
void sdb_set_batch_mode();
void init_regex();
void init_sdb();
//exec.cpp
uint64_t get_time();
void cpu_exec(uint64_t n);

void init_isa();
//difftest
void init_difftest(char *ref_so_file, long img_size);
void difftest_step();
// ================================================================================================================================================
// MACRO
// ================================================================================================================================================
// define of stringizing
#define str_temp(x) #x
#define str(x) str_temp(x)

// define of STRLEN: the length of str
#define STRLEN(CONST_STR) (sizeof(CONST_STR) - 1)

// define of ARRLEN: the number of arr's member
#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))

// define of concat
#define concat_temp(x, y) x ## y
#define concat(x, y) concat_temp(x, y)
#define concat3(x, y, z) concat(concat(x, y), z)
#define concat4(x, y, z, w) concat3(concat(x, y), z, w)
#define concat5(x, y, z, v, w) concat4(concat(x, y), z, v, w)

// macro testing
#define CHOOSE2nd(a, b, ...) b
#define MUX_WITH_COMMA(contain_comma, a, b) CHOOSE2nd(contain_comma a, b)
#define MUX_MACRO_PROPERTY(p, macro, a, b) MUX_WITH_COMMA(concat(p, macro), a, b)
// define placeholders for some property
#define __P_DEF_0  X,
#define __P_DEF_1  X,
#define __P_ONE_1  X,
#define __P_ZERO_0 X,
// define of MUXDEF
#define MUXDEF(macro, X, Y)  MUX_MACRO_PROPERTY(__P_DEF_, macro, X, Y)
#define MUXNDEF(macro, X, Y) MUX_MACRO_PROPERTY(__P_DEF_, macro, Y, X)
#define MUXONE(macro, X, Y)  MUX_MACRO_PROPERTY(__P_ONE_, macro, X, Y)
#define MUXZERO(macro, X, Y) MUX_MACRO_PROPERTY(__P_ZERO_,macro, X, Y)

// test if a boolean macro is defined
#define ISDEF(macro) MUXDEF(macro, 1, 0)
// test if a boolean macro is undefined
#define ISNDEF(macro) MUXNDEF(macro, 1, 0)
// test if a boolean macro is defined to 1
#define ISONE(macro) MUXONE(macro, 1, 0)
// test if a boolean macro is defined to 0
#define ISZERO(macro) MUXZERO(macro, 1, 0)
// test if a macro of ANY type is defined
// NOTE1: it ONLY works inside a function, since it calls `strcmp()`
// NOTE2: macros defined to themselves (#define A A) will get wrong results
#define isdef(macro) (strcmp("" #macro, "" str(macro)) != 0)

// simplification for conditional compilation
#define __IGNORE(...)
#define __KEEP(...) __VA_ARGS__
// keep the code if a boolean macro is defined
#define IFDEF(macro, ...) MUXDEF(macro, __KEEP, __IGNORE)(__VA_ARGS__)
// keep the code if a boolean macro is undefined
#define IFNDEF(macro, ...) MUXNDEF(macro, __KEEP, __IGNORE)(__VA_ARGS__)
// keep the code if a boolean macro is defined to 1
#define IFONE(macro, ...) MUXONE(macro, __KEEP, __IGNORE)(__VA_ARGS__)
// keep the code if a boolean macro is defined to 0
#define IFZERO(macro, ...) MUXZERO(macro, __KEEP, __IGNORE)(__VA_ARGS__)

// functional-programming-like macro (X-macro)
// apply the function `f` to each element in the container `c`
// NOTE1: `c` should be defined as a list like:
//   f(a0) f(a1) f(a2) ...
// NOTE2: each element in the container can be a tuple
#define MAP(c, f) c(f)

#define BITMASK(bits) (((__uint128_t)1 << (bits)) - 1)
#define BITS(x, hi, lo) (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog
#define SEXT(x, len) ({ struct { int64_t n : len; } __x = { .n = x }; (uint64_t)__x.n; })

#define ROUNDUP(a, sz)   ((((uintptr_t)a) + (sz) - 1) & ~((sz) - 1))
#define ROUNDDOWN(a, sz) ((((uintptr_t)a)) & ~((sz) - 1))

#define PG_ALIGN __attribute((aligned(4096)))

#if !defined(likely)
#define likely(cond)   __builtin_expect(cond, 1)
#define unlikely(cond) __builtin_expect(cond, 0)
#endif

// ================================================================================================================================================
// LOG_MACRO
// ================================================================================================================================================
#define ANSI_FG_BLACK   "\33[1;30m"
#define ANSI_FG_RED     "\33[1;31m"
#define ANSI_FG_GREEN   "\33[1;32m"
#define ANSI_FG_YELLOW  "\33[1;33m"
#define ANSI_FG_BLUE    "\33[1;34m"
#define ANSI_FG_MAGENTA "\33[1;35m"
#define ANSI_FG_CYAN    "\33[1;36m"
#define ANSI_FG_WHITE   "\33[1;37m"
#define ANSI_BG_BLACK   "\33[1;40m"
#define ANSI_BG_RED     "\33[1;41m"
#define ANSI_BG_GREEN   "\33[1;42m"
#define ANSI_BG_YELLOW  "\33[1;43m"
#define ANSI_BG_BLUE    "\33[1;44m"
#define ANSI_BG_MAGENTA "\33[1;35m"
#define ANSI_BG_CYAN    "\33[1;46m"
#define ANSI_BG_WHITE   "\33[1;47m"
#define ANSI_NONE       "\33[0m"
#define ANSI_FMT(str, fmt) fmt str ANSI_NONE

#define log_write(...)  \
  do { \
    extern FILE* log_fp; \
    extern bool log_enable(); \
    if (!log_enable()) { \
      fprintf(log_fp, __VA_ARGS__); \
      fflush(log_fp); \
    } \
  } while (0) 


#define _Log(...) \
  do { \
    printf(__VA_ARGS__); \
    log_write(__VA_ARGS__); \
  } while (0)

#define Log(format, ...) \
    _Log(ANSI_FMT("[%s:%d %s] " format, ANSI_FG_GREEN) "\n", \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__)

#define Assert(cond, format, ...) \
  do { \
    if (!(cond)) { \
      MUXDEF(CONFIG_TARGET_AM, printf(ANSI_FMT(format, ANSI_FG_RED) "\n", ## __VA_ARGS__), \
        (fflush(stdout), fprintf(stderr, ANSI_FMT(format, ANSI_FG_RED) "\n", ##  __VA_ARGS__))); \
      assert(cond); \
    } \
  } while (0)

#define panic(format, ...) Assert(0, format, ## __VA_ARGS__)

#define TODO() panic("please implement me")
#endif
