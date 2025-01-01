#include "include/sdb.h"
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ, TK_NEQ, TK_AND, TK_OR, TK_NUM, TK_HEX, TK_REG, TK_NEGA, TK_DEREF

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"\\-", '-'},
  {"\\*", '*'},
  {"\\/", '/'},
  {"\\(", '('},
  {"\\)", ')'},
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},
  {"&&", TK_AND},
  {"\\|\\|", TK_OR},
  {"!", '!'},
  {"0x[1-9A-Fa-f][0-9A-Fa-f]*", TK_HEX},
  {"0|[1-9][0-9]*", TK_NUM},
  {"\\$($0|ra|sp|gp|tp|t0|t1|t2|s0|s1|a0|a1|a2|a3|a4|a5|a6|a7|s2|s3|s4|s5|s6|s7|s8|s9|s10|s11|t3|t4|t5|t6|pc|mstatus|mtvec|mepc|mcause)", TK_REG},
  
};

#define NR_REGEX ARRLEN(rules)//规则的数量

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;
        if(substr_len>32){
          assert(0);
          }
        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        if(rules[i].token_type == TK_NOTYPE) break;
        tokens[nr_token].type=rules[i].token_type;
        switch (rules[i].token_type) {
          case TK_NUM:strncpy(tokens[nr_token].str,substr_start,substr_len);
                      *(tokens[nr_token].str+substr_len)='\0';
                      break;
          case TK_HEX:strncpy(tokens[nr_token].str,substr_start+2,substr_len-2);
                      *(tokens[nr_token].str+substr_len-2)='\0';
                      break;
          case TK_REG:strncpy(tokens[nr_token].str,substr_start+1,substr_len-1);
                      *(tokens[nr_token].str+substr_len-1)='\0';
                      break;
        }
        nr_token+=1;
        break;
      }
    }

    if (i == NR_REGEX) {
      printf(ANSI_FG_RED "no match at position %d\n%s\n%*.s^\n" ANSI_NONE, position, e, position, "");
      return false;
    }
  }

  return true;
}

bool check_parentheses(int p, int q){
  if(p >= q){
    printf("Error: p >= q\n");
    return false;
  }
  if(tokens[p].type != '(' || tokens[q].type != ')'){
    return false;
  }
  int left = 0, right = 0, i;
  for(i = p + 1; i < q && left >= right; i++){
    if(tokens[i].type == '(')  left++;
    if(tokens[i].type == ')')  right++;
    }
    if (left != right) return false;
    else return true;
  }
  
int main_op(int p, int q){
  if(p >= q){
    printf("Error: p >= q\n");
    return false;
  }
  int left = 0, right = 0, i;
  int a[5] = {-1,-1,-1,-1,-1};
  for(i = p; i <= q; i++){
    if(tokens[i].type == '(')  left++;
    if(tokens[i].type == ')')  right++;
    if(left > right)  continue;
    else if(tokens[i].type=='!'||tokens[i].type==TK_DEREF||tokens[i].type==TK_NEGA)
    a[4] = i;
    else if(tokens[i].type=='*'||tokens[i].type=='/')
    a[3] = i;
    else if(tokens[i].type=='+'||tokens[i].type=='-')
    a[2] = i;
    else if(tokens[i].type==TK_EQ||tokens[i].type==TK_NEQ)
    a[1] = i;
    else if(tokens[i].type==TK_AND||tokens[i].type==TK_OR)
    a[0] = i;
    }
    for(int b = 0;b < 5; b++){
      if(a[b] != -1) return a[b];
    }
    printf("Error!\n");
    assert(0);
}

uint32_t eval(int p, int q){
  if(p > q){
    printf("Error: p > q\n");
    assert(0);
  }
  else if(p == q){
    if(tokens[p].type ==TK_NUM){
    char *num;
    uint32_t r = strtoul(tokens[p].str,&num,10);
    return r;
    }
    else if(tokens[p].type == TK_HEX){
    char *nex;
    uint32_t r = strtoul(tokens[p].str,&nex,16);
    return r;
    }
    else if(tokens[p].type == TK_REG){
      uint32_t r = 0;
      for(int i = 0; i < 32; i++){
        if(strcmp(tokens[p].str,regs[i])==0)
        r = cpu.gpr[i];
        if(strcmp(tokens[p].str,"mstatus")==0)
        r = cpu.csr[0];
        if(strcmp(tokens[p].str,"mtvec")==0)
        r = cpu.csr[1];
        if(strcmp(tokens[p].str,"mepc")==0)
        r = cpu.csr[2];
        if(strcmp(tokens[p].str,"mcause")==0)
        r = cpu.csr[3];
      }
      if(strcmp(tokens[p].str,"pc")==0)
        r = cpu.pc;
      return r;
    }
    else{
      printf("Error: in single token in p=%d,q=%d.\n",p,q);
      assert(0);
    }
  }
  else if (check_parentheses(p, q) == true) {
    return eval(p + 1, q - 1);
  }
  else{
    int op = main_op(p,q);
    uint32_t addr;uint32_t result;
    int op_type=tokens[op].type;
    switch(op_type){
      case TK_NEGA:
        result = -eval(p+1,q);
        printf("Operator= -.\n");
        printf("Value=%d.\n",result);
        return result;
      case TK_DEREF:
        addr = eval(p+1, q);
        result = host_read(guest_to_host(addr), 4);
        return result;
      case '!':
        result = eval(p+1, q);
        if(result == 0) {
          printf("Value=1.\n");
          return 1;
        }
        else {
          printf("Value=0.\n");
          return 0;
        }
    }
      int val1 = eval(p, op - 1);
      int val2 = eval(op + 1, q);
    switch(op_type){
      case '+':
        return val1 + val2;
      case '-':
        return val1 - val2;
      case '*':
        return val1 * val2;
      case '/':
        if(val2 == 0) assert(0);
        return val1 / val2;
      case TK_EQ:
        return val1 == val2;
      case TK_NEQ:
        return val1 != val2;
      case TK_AND:
        return val1 && val2;
      case TK_OR:
        return val1 || val2;
      default:  assert(0);  
    }  
  }
}

uint32_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  for(int i = 0; i<nr_token; i++){
    if(tokens[i].type == '-'){
      if(i == 0) tokens[i].type = TK_NEGA;
      if(tokens[i-1].type == TK_NUM || tokens[i-1].type == TK_HEX || tokens[i-1].type == ')')
        tokens[i].type= '-';
      else tokens[i].type = TK_NEGA;
    }
    if(tokens[i].type == '*'){
      if(i == 0) tokens[i].type = TK_DEREF;
      if(tokens[i-1].type == TK_NUM || tokens[i-1].type == TK_HEX || tokens[i-1].type == ')')
      tokens[i].type =  '*';
      else tokens[i].type = TK_DEREF;
    }
  }
  *success = true;
  return eval(0,nr_token-1);
}
  

