#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define MAX_SEM 512

int get_empty_sem(int value){
    int res = 0, tmp=0;

    while(res < MAX_SEM && !tmp){

        tmp = sem_open(res,value);
        res++;
    }

    res = (res == MAX_SEM && tmp == 0) ? -1 : res-1; 

    return res;
}

int main(int argc, char const *argv[]){

    // Nos generaba problemas comparar un int con char const*
    // La funcion atoi transforma un char const* a int
    int n = atoi(argv[1]);

    // Verificamos
    if(argc != 2){
        
        printf("ERROR: Not exactly 1 argument.\n");
        exit(1);
    }

    if(n <= 0){

        printf("ERROR: Invalid argument.\n");
        exit(1);
    }

    
    // Buscamos un semaforo disponible para el padre
    int father_sem = get_empty_sem(0);

    if (father_sem == -1){

        printf("ERROR: No empty semaphore.\n");
        exit(1);
    }

    // Buscamos un semaforo disponible para el hijo
    int child_sem = get_empty_sem(0);

    if (child_sem == -1){

        printf("ERROR: No empty semaphore.\n");
        exit(1);
    }

    int child_id = fork();
    
    if(child_id == -1){

        printf("ERROR: fork failed.\n");
        exit(1);
    }

    // Caso hijo
    else if(child_id == 0){
        
        for (unsigned int i = 0; i < n;i++){

            // Iniciamos el hijo bloqueado
            sem_down(child_sem);
            // Una vez que el padre lo desbloquea
            printf("\tpong\n");
            // Desbloqueamos al padre
            sem_up(father_sem);
        }

        return 0;
    }
    
    // Caso padre
    else{
        
        for (unsigned int i = 0; i < n;i++){

            printf("ping\n");
            // Desbloqueamos al hijo
            sem_up(child_sem);
            // Bloqueamos al padre
            sem_down(father_sem);
        }
    }
    
    // Espera al hijo
    wait(0);

    // Cerramos ambos semaforos
    sem_close(child_sem);
    sem_close(father_sem);

    return 0;
}
