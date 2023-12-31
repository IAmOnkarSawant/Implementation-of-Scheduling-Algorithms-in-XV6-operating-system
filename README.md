﻿# Report to README Conversion

## Steps to Add Scheduler Functionality

1. **Integration of 'user/schedulertest' Program:**
   - The 'user/schedulertest' program has been seamlessly incorporated into the 'UPROGS' directory.
   - A configuration flag ('CFLAG') has been introduced, allowing users to specify their preferred scheduler for kernel execution.

2. **Default Scheduler Configuration:**
   - In the absence of user-defined preferences, a default scheduling algorithm (RoundRobin) has been established to ensure smooth kernel operation.

3. **Enhanced 'procdump' Functionality:**
   - Two crucial variables, 'runtime' (as 'rtime') and 'endtime' (as 'etime'), have been introduced to enhance the 'procdump' function.
   - The 'endtime' variable is now initialized within the 'exit' function, residing in 'proc.c,' and triggers when a process transitions into the 'zombie' state.

4. **Refinement of the 'procdump' Function:**
   - The 'procdump' function has undergone further refinement to improve its overall performance and functionality.

5. **Display of Scheduler Performance Metrics:**
   - Detailed performance metrics of the scheduler are now presented, offering valuable insights into its operational efficiency.
   
   Schedulers and their output:
   - FCFS:
     - PID (processID)
     - State (state of process)
     - Rtime (Runtime)
     - Wtime (waiting time)
     - Nrun (The number of times the process has been scheduled)
   - Priority-Based Scheduler:
     - PID (processID)
     - Prio (priority of the current process in the range 0 to 100)
     - State (state of process)
     - Rtime (runtime time)
     - Wtime
     - Nrun (The number of times the process has been scheduled)
   - Multilevel Feedback Queue Scheduling:
     - PID (Process ID)
     - Prio (priority)
     - State (state of the process)
     - Rtime (runtime)
     - Wtime (waiting time)
     - Nrun (The number of times the process has been scheduled)
     - Q0 to Q4 (Number of ticks done in each queue)

## Benchmark Testing

A new file created in the `user/schedulertest.c` was added to test the implemented schedulers.

- **RoundRobin:**
  - Average runtime: 219
  - Average waiting time: 30

- **FirstComeFirstServe:**
  - Average runtime: 256
  - Average waiting time: 56

- **PriorityBasedScheduling:**
  - Average runtime: 173
  - Average waiting time: 28

- **Multilevel Feedback Queue:**
  - Average runtime: 203
  - Average waiting time: 26

## Conclusion

Certainly, when analyzing the performance of different scheduling algorithms, it becomes evident that FCFS (First-Come-First-Serve) tends to deliver the least favorable results. This is primarily due to the possibility of extended waiting times for other processes if a CPU-bound task with an extended execution duration is prioritized first. In comparison, MLFQ (Multi-Level Feedback Queue) stands out as the top-performing scheduling algorithm, with PBS (Priority-Based Scheduling) coming in as a strong runner-up. Meanwhile, Round Robin trails behind in terms of performance.

These conclusions were drawn based on an evaluation conducted using the benchmark program found in `user/schedulertest.c`.
