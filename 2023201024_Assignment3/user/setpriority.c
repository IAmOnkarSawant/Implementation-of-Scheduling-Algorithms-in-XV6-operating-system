#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int
main(int argc, char ** argv)
{
    int old_sp, new_sp, pid;

    if (argc != 3) {
        fprintf(2, "%s: execution failed - insufficient number of arguments\n", argv[0]);
        exit(1);
    }

    new_sp = atoi(argv[1]);
    pid = atoi(argv[2]);

    if (new_sp < 0 || new_sp > 100) {
        fprintf(2, "%s: execution failed - static priority should be in the range 0-100\n", argv[0]);
        exit(1);
    }

    old_sp = set_priority(new_sp, pid);
    if (old_sp < 0) {
        fprintf(2, "%s: execution failed - no process with process ID %d exists\n", argv[0], pid);
        exit(1);
    }

    printf("%s: priority of process with ID %d successfully updated from %d to %d\n", argv[0], pid, old_sp, new_sp);
    exit(0);
}