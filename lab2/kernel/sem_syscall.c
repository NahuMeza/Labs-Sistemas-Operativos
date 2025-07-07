// #include "syscall.h"
// #include "sem_syscall.h"
// #include "defs.h"
// #include "spinlock.h"
// #include "types.h"
// #include "param.h"
// #include "riscv.h"

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"

#define EMPTY_SEM -1
#define ERR 0
#define SUCCESS 1
#define MAX_SEM 512

struct semaphore {
    int value;           
    struct spinlock lock;
};

// Global variable 
struct semaphore semaphore_array[MAX_SEM];

void make_sem_array() {

    for (unsigned int i = 0; i < MAX_SEM; ++i) {

        semaphore_array[i].value = EMPTY_SEM;

        // Inicializa la estructura del lock del semaphore (lock = 0, cpu = 0)
        initlock(&(semaphore_array[i].lock), "semaphore"); 
    }
}

int sem_open(int sem, int value){

    // Corroboramos el rango
    if (value < 0|| sem < 0 || sem > MAX_SEM){

        printf("ERROR: semaphore out of range.\n");
        return ERR;
    }

    acquire(&semaphore_array[sem].lock);
    // Nos fijamos si el semaforo ya esta abierto 
    if (semaphore_array[sem].value != EMPTY_SEM){
        release(&semaphore_array[sem].lock);
        return ERR;
    }
    
    
    semaphore_array[sem].value = value;

    // Hay que liberarlo 
    release(&semaphore_array[sem].lock);

    return SUCCESS;
}

int sem_close(int sem){
    
    // Corroboramos el rango
    if (sem < 0 || sem > MAX_SEM){

        printf("ERROR: semaphore out of range.\n");
        return ERR;
    }
    
    acquire(&semaphore_array[sem].lock);

    semaphore_array[sem].value = EMPTY_SEM;

    // Hay que liberarlo 
    release(&semaphore_array[sem].lock);

    return SUCCESS;
}

int sem_up(int sem){

    acquire(&semaphore_array[sem].lock);
    
    int sem_value = semaphore_array[sem].value;

    if(sem_value == EMPTY_SEM){

        release(&semaphore_array[sem].lock);
        printf("ERROR: closed semaphore.\n");
        return ERR;
    }
    
    if (sem_value == 0){

        //desbloqueo
        wakeup(&semaphore_array[sem]);
    }
    semaphore_array[sem].value++;
    
    release(&semaphore_array[sem].lock);
    
    return SUCCESS;
}
int sem_down(int sem){
   acquire(&semaphore_array[sem].lock);
   
   int sem_value = semaphore_array[sem].value;
   
    if(sem_value == EMPTY_SEM){

        release(&semaphore_array[sem].lock);
        printf("ERROR: closed semaphore.\n");
        return ERR;
    }
    
    while(semaphore_array[sem].value == 0){

        sleep(&(semaphore_array[sem]), &(semaphore_array[sem].lock));
    }
    
    (semaphore_array[sem].value)--;

    release(&semaphore_array[sem].lock);
    return SUCCESS;
}
