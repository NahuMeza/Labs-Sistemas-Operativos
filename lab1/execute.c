#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <check.h>
#include <fcntl.h>   // Para open() y las banderas O_RDONLY, O_WRONLY, O_RDWR, etc.
#include <unistd.h>  // Para close() y otras funciones de manejo de archivos
#include <sys/wait.h>
#include <string.h>
#include "command.h"
#include "execute.h"
#include "builtin.h"
#include "strextra.h"
#include "tests/syscall_mock.h"
#include <signal.h>
#define ERROR_MSG "mybash error!\n"

void redirection(scommand cmd){
    // Obtenemos la redireccion
    char* filename_in = scommand_get_redir_in(cmd);
    char* filename_out = scommand_get_redir_out(cmd);
    int redir;

    if(filename_in != NULL){
        // Abrimos el file descriptor apuntando a nuestro archivo
        redir = open(filename_in, O_RDONLY,S_IRWXU);

        if (redir == -1){
            
            fprintf(stderr, "%s\n", ERROR_MSG);
            exit(EXIT_FAILURE);
        }
        
        // Usamos como stdin nuestra redirecci�n
        dup2(redir,STDIN_FILENO);
        // Cerramos el file descriptor ya que no lo necesitamos mas
        close(redir);
    }

    if(filename_out != NULL){
        // Abrimos el file descriptor apuntando a nuestro archivo
        redir = open(filename_out,O_CREAT|O_WRONLY|O_TRUNC,S_IRWXU);

        if (redir == -1){
            
            fprintf(stderr, "%s\n", ERROR_MSG);
            exit(EXIT_FAILURE);
        }
        // Usamos como stdout nuestra redirecci�n
        dup2(redir,STDOUT_FILENO);
        // Cerramos el file descriptor ya que no lo necesitamos mas
        close(redir);
    }
}

void execute_command(scommand cmd){

    // Redireccionamos los file descriptors para que vayan a stdin y stdout
    redirection(cmd);

    unsigned int length_scommand = scommand_length(cmd);

    // Reservamos memoria para cada argumento del scommand y uno mas para el NULL
    char **args = calloc(length_scommand + 1, sizeof(char *)); 
        
    for(unsigned int i = 0; i < length_scommand; i++){

        // Obtenemos el largo del argumento seleccionado del comando
        unsigned int arg_length = strlen(scommand_front(cmd)) + 1;
        // Reservamos la memoria para guardar ese argumento
        args[i] = malloc(arg_length * sizeof(char));   

        // Guardamos el argumento en nuestro arreglo
        strcpy(args[i], scommand_front(cmd));
        scommand_pop_front(cmd);
    }
    
    // El ultimo elemento del arreglo como NULL para que execvp lo interprete como fin del arreglo
    args[length_scommand] = NULL;
    execvp(args[0], args);
        
    // En caso de error
    perror(strmerge("mybash: ",args[0]));
    exit(EXIT_FAILURE);
}

void execute_pipeline(pipeline apipe){

    assert(apipe!=NULL);

    unsigned int pipe_length = pipeline_length(apipe);
    
    int pipe0[2], pipe1[2];
    int fork_id;
    __pid_t children_pids[pipe_length];
    scommand cmd;

    // En caso de ser un builtin solo  
    if (builtin_alone(apipe)){
        builtin_run(pipeline_front(apipe));
        return;
    }
    //para no dejar procesos zombies
    if (!pipeline_get_wait(apipe)){
        signal(SIGCHLD,SIG_IGN);
    }

    for(unsigned int i = 1; i <= pipe_length; i++){

        // A partir del segundo ciclo se hace el intercambio
        cmd = pipeline_front(apipe);

        // Guardamos en pipe0 nuestro file descriptor anterior
        if(i > 1){
            
            pipe0[0] = pipe1[0];
            pipe0[1] = pipe1[1];
        }

        // Creamos el nuevo buffer y los id del file descriptor que apuntan a el los guardamos en pipe1
        if(i != pipe_length){

            pipe(pipe1);
        }

        // Creamos el proceso hijo
        fork_id = fork();

        if(fork_id == -1){
           
            // Caso de error
            printf("Fork did not work!\n");
            return;
        }

        // Proceso Hijo
        else if(fork_id == 0){
            
            // Caso hijo unico
            if(pipe_length == 1){
                
                execute_command(cmd);
            }

            // Caso primer hijo pero con mas hermanos
            else if(i == 1){
                
                // Cierra lectura
                close(pipe1[0]);
                // Redirigimos nuestra salida al proximo pipe
                dup2(pipe1[1],STDOUT_FILENO);
                // Cerramos el file descriptor ya que no lo utilizaremos mas
                close(pipe1[1]);
            }

            // Caso ultimo hijo
            else if(i == pipe_length){

                // Cierra lectura
                close(pipe0[1]);
                // Redirigimos nuestra entrada al proximo pipe
                dup2(pipe0[0],STDIN_FILENO);
                // Cerramos el file descriptor ya que no lo utilizaremos mas
                close(pipe0[0]);
            }
    
            // Caso hijo del medio
            else{

                close(pipe0[1]);
                dup2(pipe0[0],STDIN_FILENO);
                close(pipe0[0]);

                close(pipe1[0]);
                dup2(pipe1[1],STDOUT_FILENO);
                close(pipe1[1]);
            }

            // Ejecutamos el comando en el proceso hijo y termina
            execute_command(cmd);
        }

        // Proceso Hijo
        else if(fork_id > 0){

            // En caso de haber creado un hijo que no sea el primero,
            // cerramos el file descriptor del proceso anterior que no utiliza el padre.
            if(i > 1){

            close(pipe0[0]);
            close(pipe0[1]);
            }

            // Vamos eliminando el primer elemento del pipeline con cada iteracion
            pipeline_pop_front(apipe);

            // Almacenamos el id del hijo que acaba de crear
            children_pids[i-1] = fork_id; 
        }
    }

    // Esperamos a cada hijo en caso de ser necesario
    if(pipeline_get_wait(apipe)){
        
         for (unsigned int i = 0; i < pipe_length; ++i){

             waitpid(children_pids[i], NULL, 0);
         }
    }
}
