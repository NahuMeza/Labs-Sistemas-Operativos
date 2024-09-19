#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include "parsing.h"
#include "parser.h"
#include "command.h"

static scommand parse_scommand(Parser p) {
    scommand command = scommand_new();
    arg_kind_t argtype;

    // Limpiamos espacios en blancos al principio de cada comando
    parser_skip_blanks(p); 
    char* next_comm = parser_next_argument(p, &argtype);
    
    while(next_comm != NULL){

        // Verificamos el tipo de argumento detectado por el parser
        if(argtype == ARG_NORMAL){
            scommand_push_back(command, next_comm);
        }
        else if(argtype == ARG_INPUT){
            scommand_set_redir_in(command, next_comm);
        }      
        else if(argtype == ARG_OUTPUT){
            scommand_set_redir_out(command, next_comm);
        }

        next_comm = parser_next_argument(p, &argtype); 

        // Limpiamos espacios en blancos al principio de cada comando
        parser_skip_blanks(p); 
    }
    
    // Caso de error de parseo en que el comando sea nulo y haya declarado tipos
    if(argtype == ARG_INPUT || argtype == ARG_OUTPUT){
        command = scommand_destroy(command);
    }
    
    // Devuelve NULL cuando hay un error de parseo
    return command;
}

pipeline parse_pipeline(Parser p) {
    pipeline result = pipeline_new();
    scommand cmd = NULL;
    bool error = false, another_pipe=true, isbackground, garbage;
    
    cmd = parse_scommand(p);

    // Verificamos si hay error de parseo en el comando
    error = (cmd==NULL); 
    
    // Agregamos el comando al pipeline y hacemos parsing del siguiente comando
    while(another_pipe && !error){ 
        
        pipeline_push_back(result,cmd);
        
        parser_op_pipe(p,&another_pipe); 
        
        cmd = parse_scommand(p);
        
        // Volvemos a verificar si hubo algun error de parseo en el comando  
        error = (cmd==NULL); 
    }

    parser_op_background(p, &isbackground);
    
    // Si hay un "&", le dice al pipeline que no debe esperar
    pipeline_set_wait(result, !isbackground); 

    // Verificamos errores
    if(error){

        printf("No input/output directory especified. \n");
        result = pipeline_destroy(result);
    }
    
    else if(pipeline_length(result) == 1 && scommand_length(pipeline_front(result)) == 0) {

        result = pipeline_destroy(result);
    }

    // Verificamos si hay basura en el comando, de haberla, avisamos del error
    parser_garbage(p, &garbage);

    if(garbage){

        printf("Error: invalid command.\n");
        result = pipeline_destroy(result);
    }

    return result;
}






