#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h> // el chdir esta aca!

#include "builtin.h"
#include "strextra.h"
#include "command.h"
#include "tests/syscall_mock.h"

#define B_AMOUNT 3

static const char* buildins[] = {"cd", "help", "exit"};

bool builtin_is_internal(scommand cmd){
    assert(cmd != NULL);
    char* command = scommand_front(cmd);
    bool internal = false;

    // Comparamos el comando con los buildins
    for (unsigned int i = 0; i < B_AMOUNT && !internal; i++){

        // Si son iguales, strcmp devuelve 0
        internal = internal || (strcmp(buildins[i], command) == 0);
    }
    return internal;
}

bool builtin_alone(pipeline p){
    assert(p != NULL);

    return ((pipeline_length(p) == 1) && builtin_is_internal(pipeline_front(p)));
}


void builtin_run(scommand cmd){
    assert(builtin_is_internal(cmd));
    char* command = scommand_front(cmd);
    
    // Si el comando es cd
    if (strcmp(command,buildins[0])==0){

        // Nos quedamos con el path
        scommand_pop_front(cmd);
        
        // Si no se ingresa directorio se envia al home
        if(scommand_length(cmd)==0){
            char* home = strmerge("/home/",getlogin());
            scommand_push_back(cmd,home);
        }
       
        char* directory = scommand_front(cmd);
        int error = chdir(directory);
        
        if (error != 0){
                printf("mybash: cd: The following directory>%s does not exist\n", directory);
                return;
        }
        
    }

    // Si el comando es help
    else if (strcmp(command, buildins[1])==0){
        printf("«CATGPT shell»\n"
            "Shell made by Group 06 >> Salvador Amor, Franco Aredes, Sara Ferreyra and Gastón Meza\n"
            "CATGPT has the following built-in commands:\n"
            "\t-cd — Changes the working directory.\n"
            "\tcd <path>\n"
            "\t<path> is the directory that shall become the new working directory.\n"
            "\t-help — Displays information about built-in commands (This message).\n"
            "\t-exit — Causes normal process termination.\n");
    }

    // Si el comando es exit
    else if (strcmp(command, buildins[2])==0){
        printf("Bye!\n");
        exit(EXIT_SUCCESS);
    }
}
