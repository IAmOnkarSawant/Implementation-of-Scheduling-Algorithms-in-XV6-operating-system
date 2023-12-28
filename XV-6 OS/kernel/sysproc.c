#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_strace(void)
{
  int trace_mask;

  argint(0, &trace_mask);
  if (trace_mask < 0)
    return -1;

  struct proc *p = myproc();
  p->mask = trace_mask;

  return 0;
}
uint64	
sys_waitx(void)	
{	
  uint64 addr, addr1, addr2;	
  uint wtime, rtime;	
  if(argaddr(0, &addr) < 0)	
    return -1;	
  if(argaddr(1, &addr1) < 0) // user virtual memory	
    return -1;	
  if(argaddr(2, &addr2) < 0)	
    return -1;	
  int ret = waitx(addr, &wtime, &rtime);	
  struct proc* p = myproc();	
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)	
    return -1;	
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)	
    return -1;	
  return ret;	
}	
uint64	
sys_set_priority(void)	
{	
  int priority, pid;	
  if (argint(0, &priority) < 0)	
    return -1;	
  if (argint(1, &pid) < 0)	
    return -1;	
  return set_priority(priority, pid);	
}
uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
	

