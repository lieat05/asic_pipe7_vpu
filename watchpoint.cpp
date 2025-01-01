#include "include/sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].change_time = 0;
    wp_pool[i].last_result = 0;
  }

  head = NULL;
  free_ = wp_pool;
}

bool new_wp(char *args){
	WP* wp = NULL;
	if (free_ == NULL){
		printf("Error:Too much Watchpoingts!\n");
		assert(0);
		return false;
	}
	else {
		wp = free_;
		free_ = free_ -> next;
		strcpy(wp -> EXPR, args);
		wp -> change_time = 0;
		bool success;
		wp -> last_result = expr(wp -> EXPR,&success);
		if(success == false) {		
		  printf("Error:Wrong exprs\n");
		  return false;
		}
		wp -> next = head;
		head = wp;
		
	}
	printf("Now watchpoint NO.%d	result=%d.\n",wp ->NO, wp -> last_result);
	return true;
}


void free_wp(int N){
	WP *wp = NULL;
	for(int i = 0;i < NR_WP; i ++){
		if(wp_pool[i].NO == N){
			wp = &wp_pool[i];
		}
	}
	if (head == NULL){
		printf("no watchpoints!\n");
		return;
	}
	else {
		if(wp == head){
			head = wp -> next;
			wp -> next = free_;
			free_ = wp;
			printf("NO.%d watchpoint has been deleted.\n",N);
			return;
		}
		else{
			WP *pre_wp;
			for(pre_wp = head;pre_wp;pre_wp = pre_wp -> next){
				if(pre_wp -> next == wp){
					pre_wp -> next = wp -> next;
					printf("NO.%d watchpoint has been deleted.\n",N);
					wp -> next = free_;
					free_ = wp;
					return;
				}
			}
		}
		printf("NO.%d watchpoint doesn't exist!.\n",N);
		return;
	}
}


void print_wp(){
	if(head == NULL){
		printf("Error: No watchpoint.\n");
		return;
	}
	WP *wp = head;
	while(wp != NULL){
		printf("Watchpoints:\n");
		printf("NO.%d EXPR = %s change times = %d\n",wp->NO, wp-> EXPR, wp-> change_time);
		wp = wp -> next;
	}
}

bool watch_wp(){
	bool success;
	int result;
	if(head == NULL) return true;
	WP *wp = head;
	while( wp != NULL){
		result = expr(wp -> EXPR,&success);
		if(result != wp->last_result){
			wp -> change_time++;
			printf("The value of NO.%d watchpoint has changed.\n",wp -> NO);
			printf("EXPR=%s	last_result = %d;	result = %x\n",wp-> EXPR,wp -> last_result,result);
			wp -> last_result = result;
			return false;
		}
		wp = wp -> next;
	}
	return true;
}


