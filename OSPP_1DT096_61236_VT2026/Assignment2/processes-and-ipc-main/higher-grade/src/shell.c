#include "parser.h"    // cmd_t, position_t, parse_commands()

#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <stdbool.h>
#include <fcntl.h>     //fcntl(), F_GETFL
#include <sys/wait.h> // wait()

#define READ  0
#define WRITE 1

/**
 * For simplicitiy we use a global array to store data of each command in a
 * command pipeline .
 */
cmd_t commands[MAX_COMMANDS];

/**
 *  Debug printout of the commands array.
 */
void print_commands(int n) {
  for (int i = 0; i < n; i++) {
    printf("==> commands[%d]\n", i);
    printf("  pos = %s\n", position_to_string(commands[i].pos));
    printf("  in  = %d\n", commands[i].in);
    printf("  out = %d\n", commands[i].out);

    print_argv(commands[i].argv);
  }

}

/**
 * Returns true if file descriptor fd is open. Otherwise returns false.
 */
int is_open(int fd) {
  return fcntl(fd, F_GETFL) != -1 || errno != EBADF;
}

void fork_error() {
  perror("fork() failed)");
  exit(EXIT_FAILURE);
}

/**
 *  Fork a proccess for command with index i in the command pipeline. If needed,
 *  create a new pipe and update the in and out members for the command..
 */
void fork_cmd(int i) {
  pid_t pid;

  switch (pid = fork()) {
    case -1:
      fork_error();
    case 0:
      // Child process after a successful fork().
      if (commands[i].pos == unknown) {
        fprintf(stderr, "shell: unknown position for command %d\n", i);
        exit(EXIT_FAILURE);
      }

      if (commands[i].pos == single) {
        // printf("==== Single! ====\n");
        commands[i].in = STDIN_FILENO;
        commands[i].out = STDOUT_FILENO;
        // No need to fix a pipe, just execute the command.
      }

      if (commands[i].pos == first) {
        // printf("==== First! ====\n");

        commands[i].in = STDIN_FILENO;
        // commands[i].out = pipefd[WRITE];

        dup2(commands[i].out, STDOUT_FILENO);

        close(commands[i].out);
      }
      if (commands[i].pos == middle) {
        // printf("==== Middle! ====\n");

        // commands[i].in = pipefd[READ];
        // commands[i].out = pipefd[WRITE];

        dup2(commands[i].in, STDIN_FILENO);
        dup2(commands[i].out, STDOUT_FILENO);

        close(commands[i].in);
        close(commands[i].out);
      }
      if (commands[i].pos == last) {
        // printf("==== Last! ====\n");

        // commands[i].in = pipefd[READ];
        commands[i].out = STDOUT_FILENO;
        dup2(commands[i].in, STDIN_FILENO);

        close(commands[i].in);
      }
      // Execute the command in the context of the child process.
      execvp(commands[i].argv[0], commands[i].argv);

      // If execvp() succeeds, this code should never be reached.
      fprintf(stderr, "shell: command not found: %s\n", commands[i].argv[0]);
      exit(EXIT_FAILURE);

    default:
      // Parent process after a successful fork().


      break;
  }
}

/**
 *  Fork one child process for each command in the command pipeline.
 */
void fork_commands(int n) {
  int pipefd[2];

  for (int i = 0; i < n; i++) {
    
    if (i < n - 1) {
      if (pipe(pipefd) == -1) {
        fprintf(stderr, "pipe() failed\n");
        exit(EXIT_FAILURE);
      }
      commands[i + 1].in = pipefd[READ];
      commands[i].out = pipefd[WRITE];
    }

    fork_cmd(i);

    if (commands[i].in != STDIN_FILENO) {
      close(commands[i].in);
    }
    if (commands[i].out != STDOUT_FILENO) {
      close(commands[i].out);
    }

  }
}

/**
 *  Reads a command line from the user and stores the string in the provided
 *  buffer.
 */
void get_line(char* buffer, size_t size) {
  ssize_t len = getline(&buffer, &size, stdin);
  if (len > 0 && buffer[len - 1] == '\n') {
    buffer[len - 1] = '\0';
  }
  // buffer[strlen(buffer)-1] = '\0';
}

/**
 * Make the parents wait for all the child processes.
 */
void wait_for_all_cmds(int n) {
  for (int i = 0; i < n; i++) {
    wait(NULL);
  }
}

int main() {
  int n;               // Number of commands in a command pipeline.
  size_t size = 128;   // Max size of a command line string.
  char line[size];     // Buffer for a command line string.


  while(true) {
    printf(" >>> ");

    get_line(line, size);

    n = parse_commands(line, commands);

    fork_commands(n);

    wait_for_all_cmds(n);
  }

  exit(EXIT_SUCCESS);
}
