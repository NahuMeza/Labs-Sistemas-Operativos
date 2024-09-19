#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>

#include "command.h"
#include "execute.h"
#include "parser.h"
#include "parsing.h"
#include "builtin.h"
#include "obfuscated.h"


static void show_prompt(void) {
    char user[256];
    // consigue nombre de usuario
    gethostname(user, 256); 
    char directory[256];
    // consigue directorio
    getcwd(directory, 256);
    printf ("%s:%s$>", user, directory);
    fflush (stdout);
}

int main(int argc, char *argv[]) {
    pipeline pipe;
    Parser input;
    bool quit = false;

    input = parser_new(stdin);
    while (!quit) {
        show_prompt();
        pipe = parse_pipeline(input);
        if (pipe != NULL){
            execute_pipeline(pipe);
            pipeline_destroy(pipe);
        }
        quit = parser_at_eof(input);
        
    }
    input = parser_destroy(input);
    input = NULL;
    return EXIT_SUCCESS;
}

