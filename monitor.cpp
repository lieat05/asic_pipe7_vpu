#include "include/memory.h"
#include "include/trace.h"
#include <time.h>
// ================================================================================================================================================
// PARSE_ARGS
// ================================================================================================================================================
static char *diff_so_file = NULL;
static char *log_file = NULL;
char *img_file = NULL;

#ifdef CONFIG_FTRACE
static char *elf_file =NULL;

void init_ftrace(){
	elf_file = optarg;
      	parse_elf(elf_file);
	printf("Num:       Value       Size Name\n");
    		for (int i = 0; i < 1024; ++i) {
        		if (elf_func[i].func_name[0] == '\0') {
            			break;
        		}
        		printf("%3d: %016lx %5ld %s\n", i, elf_func[i].start, elf_func[i].size, elf_func[i].func_name);
    		}
}
#endif

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"ftrace"   , required_argument, NULL, 'f'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:f:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'd': diff_so_file = optarg; break;
      case 'l': log_file = optarg; break;
      case 'f': 
      		#ifdef CONFIG_FTRACE
    		init_ftrace();
    		#endif
    		break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-f,--elf=FILE           open elf and enable ftrace\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

// ================================================================================================================================================
// MONITOR_INIT
// ================================================================================================================================================
void init_rand() {
  srand(time(0));
}

void welcome() {
  Log("Itrace: %s", MUXDEF(CONFIG_ITRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  Log("Mtrace: %s", MUXDEF(CONFIG_MTRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  Log("Ftrace: %s", MUXDEF(CONFIG_FTRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  Log("Difftest: %s", MUXDEF(CONFIG_DIFFTEST, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  Log("Watchpoint: %s", MUXDEF(CONFIG_WATCHPOINT, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf(ANSI_FG_GREEN "Welcome to riscv32e-NPC!\n");
  printf("For help, type \"help\"\n" ANSI_NONE);
  assert(1);
}

void init_monitor(int argc, char *argv[]) {

  parse_args(argc, argv);
    
  init_rand();
  
  init_log(log_file);
  
  init_mem();
  
  IFDEF(CONFIG_DEVICE, init_device());
  
  init_isa();
  
  long img_size = load_img();
  
  #ifdef CONFIG_DIFFTEST
  init_difftest(diff_so_file, img_size);
  #endif
  
  init_sdb();
  
  welcome();
}
