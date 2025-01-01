#include "include/trace.h"
#include <readline/readline.h>
#include <readline/history.h>
#include "include/sdb.h"
static int is_batch_mode = false;

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) {
  return -1;
}

static int cmd_si(char *args) {
  int N = 0;
  int flag;
  if(args == NULL) N = 1;
  else{
    flag = sscanf(args,"%d", &N);
    if (flag == 0) {
      printf("failed sccanf\n");
      return 0;
    }
  }
  if(N != 1) printf(ANSI_FG_CYAN "execute for %d times\n" ANSI_NONE,N);
  cpu_exec(N);

  return 0;
}

static int cmd_info(char *args) {
  char SUBCMD;
  if(args == NULL){
    printf(ANSI_FG_RED "Error:No args!\n" ANSI_NONE);
    return 0;
    }
  sscanf(args,"%c",&SUBCMD);
  if(SUBCMD == 'r'){
    isa_reg_display();
    return 0;
    }
  else if(SUBCMD == 'w'){
    print_wp();
    return 0;
    }
  else printf(ANSI_FG_RED "Error:Wrong args!\n" ANSI_NONE);
  return 0;
}

static int cmd_x(char *args) {
  int N;
  char ARGS[100];
  uint32_t EXPR;
  if(args == NULL){
    printf("Error:No args!\n");
    return 0;
  }
  sscanf(args,"%d %s",&N,ARGS);
  bool success = false;
  EXPR = expr(ARGS,&success);
  if(success == false){
    printf("Error input.\n");
    return 0;
  }  
  int i1,i2;
  for(i1 = 0; i1 < N ; i1++){
    printf("0x%x:\t",EXPR+i1*4);
    for(i2 = 0; i2 < 4; i2++){
    printf("0x%02lx\t",host_read(guest_to_host(EXPR+i1*4+i2),1));
    }
    printf("\n");
  }
  return 0;
}

static int cmd_p(char *args) {
  bool success = false;
  uint32_t r = expr(args,&success);
  if(success == false){
    printf("Error input.\n");
    return 0;
  }
  else{
    printf("The value is %u.\n",r);
    return 0;
  }
}

static int cmd_w(char *args){
	if(args == NULL){
		printf("Error:No args!\n");
		return 0;
	}
	new_wp(args);
	return 0;
}

static int cmd_d(char *args){
	int N;
	if(args == NULL){
		printf("Error:No args!\n");
		return 0;
	}
	int flag = sscanf(args,"%d",&N);
	if( flag == 0 ){
		printf("Error:Wrong args!\n");
		return 0;
	}
	free_wp(N);
	return 0;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Step once",cmd_si },
  { "info", "Print Register Status or Print monitoring point information", cmd_info },
  { "x", "Find the value of the expression EXPR, take the result as the starting memory address, and output N consecutive 4 bytes in hexadecimal form", cmd_x },
  { "p", "Find the value of the expression", cmd_p },
  { "w", "Set new watchpoints", cmd_w },
  { "d", "delete watchpoints", cmd_d },

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {

  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_mainloop() {
  if(is_batch_mode){
    cpu_exec(-1);
    return;
  }
  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }
    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }
    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();
    
  /* Initialize the watchpoint pool. */
  init_wp_pool();
}   

