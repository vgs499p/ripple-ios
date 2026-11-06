/* SPDX-License-Identifier: GPL-2.0-or-later */
/* Test helper: stops only the RippleLegacy development application. */
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/proc.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
int main(void){int mib[]={CTL_KERN,KERN_PROC,KERN_PROC_ALL,0};size_t size=0;if(sysctl(mib,4,NULL,&size,NULL,0))return 1;struct kinfo_proc *p=malloc(size);if(!p)return 2;if(sysctl(mib,4,p,&size,NULL,0)){free(p);return 3;}for(size_t i=0;i<size/sizeof(*p);i++)if(!strcmp(p[i].kp_proc.p_comm,"RippleLegacy")){printf("Stopping Ripple PID %d\n",p[i].kp_proc.p_pid);kill(p[i].kp_proc.p_pid,SIGTERM);}free(p);return 0;}
