#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <sys/time.h>
#include <signal.h>

#define TIMER_HZ 60
typedef void (*alarm_handler_t) ();
void add_alarm_handle(alarm_handler_t h);

#endif
