#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include <stdlib.h>
#include <glib.h>
#include <string.h>

#include "strextra.h"
#include "command.h"
#include <check.h>

struct scommand_s {

    GQueue* comm;
    // Redirector de entrada
    char* in;
    // Redirector de salida
    char* out;      
};

struct pipeline_s {

    GQueue* pipe;
    // Tiene que esperar o no?
    bool waiting;
};

scommand scommand_new(void){
    
    // Reservamos memoria 
    scommand self = malloc(sizeof(struct scommand_s));              

    // Inicializamos los parametros
    self->comm = g_queue_new();                                     
    self->in = NULL;   
    self->out = NULL;

    assert(self != NULL && g_queue_is_empty(self->comm));
    
    return self;
}

scommand scommand_destroy(scommand self){
    assert(self != NULL);

    // Liberamos la memoria de todos los elementos del comando
    g_queue_free_full(self->comm, free);                            
    free(self->in);                                                 
    free(self->out);
    free(self);
    self = NULL;
    
    assert(self == NULL);
    
    return self;
}

void scommand_push_back(scommand self, char * argument){
    assert(self != NULL && argument!=NULL);

    // Agregamos el elemento al final de la cola 
    g_queue_push_tail(self->comm, argument);

    assert(!g_queue_is_empty(self->comm));
} 

void scommand_pop_front(scommand self){
    assert(self != NULL && !g_queue_is_empty(self->comm));
    
    // Apuntamos el elemento que queremos eliminar
    char* first = g_queue_peek_head(self->comm);

    // Eliminamos el primer elemento del comando
    g_queue_pop_head(self->comm);
    
    // Liberamos la memoria utilizada en el primer elemento
    free(first);     
}

void scommand_set_redir_in(scommand self, char* filename){
    assert(self != NULL);

    // Liberamos la redireccion anterior, en caso de NULL la funcion free no hace nada por defecto
    free(self->in);

    self->in = filename;
}

void scommand_set_redir_out(scommand self, char * filename){
    assert(self != NULL);

    // Liberamos la redireccion anterior, en caso de NULL la funcion free no hace nada por defecto
    free(self->out);

    self->out = filename;
}

bool scommand_is_empty(const scommand self){
    assert(self != NULL);
    
    return (g_queue_get_length(self->comm) == 0);
}

unsigned int scommand_length(const scommand self){
    assert(self != NULL);

    // Obtenemos el largo de la cola con la libreria GLib
    unsigned length = g_queue_get_length(self->comm);

    assert((length==0) == g_queue_is_empty(self->comm));

    return (length);
}

char * scommand_front(const scommand self){
    assert(self != NULL && !g_queue_is_empty(self->comm));
    
    // Obtenemos el primer elemento de la cola usando la libreria GLib
    char* front = g_queue_peek_head(self->comm);

    assert(front != NULL);
    
    return front;
}

char * scommand_get_redir_in(const scommand self){
    assert(self!=NULL);
    
    return self->in;
}

char * scommand_get_redir_out(const scommand self){
    assert(self!=NULL);
    
    return self->out;
}

char * scommand_to_string(const scommand self){
    assert(self != NULL);
    
    //Obtenemos la cantidad de elementos del comando
    unsigned int length = g_queue_get_length(self->comm);

    char * result = strdup(""), *tmp_result = NULL, *tmp_string = NULL;
    
    for(unsigned int i = 0; i < length; i++){
        
        tmp_string = g_queue_peek_nth(self->comm, i);
        tmp_result = result; 
        
        result = strmerge(result, tmp_string);
        
        //Liberamos la memoria ya que strmerge reserva memoria extra
        free(tmp_result);
        
        //Agregamos los espacios
        if (i < (length - 1)){
            
            tmp_result = result;
            result = strmerge(result," ");
            free(tmp_result);
        }

    } 

    if (self->in != NULL){
        
        //En caso de haber redireccion la agregamos
        tmp_result = result; 
        result = strmerge(result, " < ");
        free(tmp_result);
        
        tmp_result = result; 
        result = strmerge(result, self->in);
        free(tmp_result);
    }
    
    if (self->out != NULL){
        
        //En caso de haber redireccion la agregamos
        tmp_result = result; 
        result = strmerge(result, " > ");
        free(tmp_result);

        tmp_result = result; 
        result = strmerge(result, self->out);
        free(tmp_result);
    }
    
    assert(g_queue_is_empty(self->comm) || self->in==NULL || self->out==NULL || strlen(result)>0);

    return result;
}

pipeline pipeline_new(void){

    // Reservamos memoria para la estructura
    pipeline self = malloc(sizeof(struct pipeline_s));

    // Inicializamos los parametros
    self->pipe = g_queue_new();
    self->waiting = true;

    assert (self!= NULL && g_queue_is_empty(self->pipe) && self->waiting);
    
    return self;
}

pipeline pipeline_destroy(pipeline self){
    assert (self != NULL);

    scommand first;
    // Me aseguro de eliminar cada elemento del pipeline
    while(!pipeline_is_empty(self)){
        first =g_queue_peek_head(self->pipe);
        scommand_destroy(first);    
        g_queue_pop_head(self->pipe);
    }

    free(self);
    self = NULL;

    assert (self == NULL);

    return self;
}

void pipeline_push_back(pipeline self, scommand sc){

    assert(self!=NULL && sc!=NULL);
    
    // Utilizamos la libreria Glib
    g_queue_push_tail(self->pipe, sc);
    
    assert(!g_queue_is_empty(self->pipe));
}

void pipeline_pop_front(pipeline self){

    assert(self!=NULL && !g_queue_is_empty(self->pipe));
    
    // Obtenemos el primer elemento  
    scommand first =g_queue_peek_head(self->pipe);            
    
    // Lo liberamos
    scommand_destroy(first);
    
    g_queue_pop_head(self->pipe);
}

void pipeline_set_wait(pipeline self, const bool w){
    
    assert (self != NULL);
    
    self->waiting = w;
}

bool pipeline_is_empty(const pipeline self){

    assert(self != NULL);

    return g_queue_is_empty(self->pipe);
}

unsigned int pipeline_length(const pipeline self){

    assert(self!=NULL);

    // Utilizamos la libreria Glib
    unsigned length = g_queue_get_length(self->pipe);

    assert((length==0) == g_queue_is_empty(self->pipe));

    return length;
}

scommand pipeline_front(const pipeline self){

    assert(self!=NULL && !g_queue_is_empty(self->pipe));

    scommand comm = g_queue_peek_head(self->pipe);

    assert(comm != NULL);

    return comm;
}

bool pipeline_get_wait(const pipeline self){

    assert(self != NULL);

    return self->waiting;
}

char * pipeline_to_string(const pipeline self){

    assert(self!=NULL);

    // Inicializo el string vacio
    char* result=strdup("");
    unsigned int length = g_queue_get_length(self->pipe);
    char *tmp_result=NULL, *tmp_string = NULL;
    
    //Recorro la cola de comandos
    for(unsigned int i = 0; i < length; i++){
        
        scommand tmp_comm = g_queue_peek_nth(self->pipe, i);
        tmp_string = scommand_to_string(tmp_comm);
        tmp_result = result;                        
        result = strmerge(tmp_result, tmp_string);

        free(tmp_string);
        free(tmp_result);
        
        // Colocamos pipes entre cada commando excepto el ultimo
        if (i + 1 < length){
            
            tmp_result = result;
            result = strmerge(tmp_result, " | ");                           
            free(tmp_result);
        }
    };

    tmp_result = result;
    result = self->waiting ? strmerge(tmp_result, "") : strmerge(tmp_result, "&");
    free(tmp_result);

    assert(g_queue_is_empty(self->pipe) || self->waiting || strlen(result)>0);

    return result;
}