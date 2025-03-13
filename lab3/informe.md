
# Primera parte: Estudiando el planificador de xv6-riscv

## Pregunta 1: ¿Qué política de planificación utiliza `xv6-riscv` para elegir el próximo proceso a ejecutarse?

El planificador que usa `xv6-riscv` es el **Round Robin(RR)**, lo vemos en el archivo [proc.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/proc.c), citando:

```c

void
scheduler(void)
{
  struct proc p;
  struct cpuc = mycpu();

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}

```
El planificador **Round Robin** se caracteriza por ejecutar y turnar procesos por tiempo máximo definido *(Quantum)*, en este caso iterando sobre un arreglo de procesos y comprobando que estos estén listos para correr.

En esta implementación, un proceso que llegó despues podría ejecutarse antes que uno que ya estaba esperando. 

## Pregunta 2: ¿Cúales son los estados en los que un proceso puede permanecer en xv6-riscv y qué los hace cambiar de estado?

Si nos fijamos en el archivo [proc.h](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/proc.h), encontramos el siguiente conjunto numerado:

```c
enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };
```
Los procesos se pueden modificar a los siguientes estados con estas funciones:

- UNUSED - freeproc() - Cuando un proceso puede ser liberado de la tabla.
- USED - allocproc() - Un proceso recién creado, aún no listo para ejecutarse.
- SLEEPING - sleep() - Un proceso en espera.
- RUNNABLE - fork(), kill(), yield(), userinit(), wakeup() - Un proceso listo para ejecutar.
- RUNNING - scheduler() - Un proceso en ejecución.
- ZOMBIE - exit() - Un proceso finalizado esperando a su padre. 

## Pregunta 3: ¿Qué es un *quantum*? ¿Dónde se define en el código? ¿Cuánto dura un *quantum* en `xv6-riscv`?

Un Quantum **es un intervalo de tiempo fijo** que se le asigna a cada proceso con el fin de turnarlos entre sí a la hora de su ejecución. **Lo podemos ver en [start.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/start.c)** dentro de timerinit():

Dentro de `timerinit()` tenemos este fragmento de código.
```c
  int interval = 1000000; // cycles; about 1/10th second in qemu.
```

Los comentarios del código especifican que un intervalo es un **millón de ciclos**, es decir aproximadamente 0.1 segundos en qemu (dependiendo del cpu).

## Pregunta 4: ¿En qué parte del código ocurre el cambio de contexto en `xv6-riscv`? ¿En qué funciones un proceso deja de ser ejecutado? ¿En qué funciones se elige el nuevo proceso a ejecutar?

Dentro de [proc.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/proc.c) tenemos una función scheduler() que se encarga de **elegir el nuevo proceso a ejecutar**, que cuando **requiere un cambio de contexto utiliza otra función llamada swtch()**, definida en [swtch.S](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/swtch.S) por código assembler, que intercambia el contexto anterior (c->context) por el correspondiente (p->context)

```s

.globl swtch
swtch:
        sd ra, 0(a0)
        sd sp, 8(a0)
        sd s0, 16(a0)
        sd s1, 24(a0)
        sd s2, 32(a0)
        sd s3, 40(a0)
        sd s4, 48(a0)
        sd s5, 56(a0)
        sd s6, 64(a0)
        sd s7, 72(a0)
        sd s8, 80(a0)
        sd s9, 88(a0)
        sd s10, 96(a0)
        sd s11, 104(a0)

        ld ra, 0(a1)
        ld sp, 8(a1)
        ld s0, 16(a1)
        ld s1, 24(a1)
        ld s2, 32(a1)
        ld s3, 40(a1)
        ld s4, 48(a1)
        ld s5, 56(a1)
        ld s6, 64(a1)
        ld s7, 72(a1)
        ld s8, 80(a1)
        ld s9, 88(a1)
        ld s10, 96(a1)
        ld s11, 104(a1)
        
        ret

```

También se puede hacer un cambio de contexto con `sched()`. Cuando un proceso llama esta función (voluntariamente o por el fín de su quantum), el planificador selecciona otro proceso para ejecutarse. El proceso actual deja de ser ejecutado, y su estado cambia según la situación (esperando al cpu, E/S, etc.)

**Para que un proceso deje de ser ejecutado**, se utilizan las siguientes funciones dentro de [proc.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/proc.c):

- `yield()` es llamada con un trap por un proceso para ceder la CPU. El proceso pasa de RUNNING a RUNNABLE.
- `sleep()` suspende la ejecución de un proceso cuando este está esperando algún E/S o un recurso ya utilizado.  El proceso pasa de RUNNING a SLEEPING.
- `exit()` termina la ejecución de un proceso. El proceso cambia su estado a ZOMBIE y el padre debe encargarse de él.
- `trap()` si hay interrupción se puede pasar un proceso a SLEEPING o RUNNABLE por kernel ([trap.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/kernel/trap.c))
- `wait()` si hay hijos no ZOMBIES, el padre pasa a SLEEPING. 

## Pregunta 5: ¿El cambio de contexto consume tiempo de un *quantum*?

El quantum en este caso es global. Mientras se realiza el cambio de contexto, este intervalo de tiempo sigue corriendo.


# Segunda Parte: Medir operaciones de cómputo y de entrada/salida

## Experimento 1: ¿Cómo son planificados los programas iobound y cpubound?

### 1) Describa los parámetros de los programas cpubench e iobench para este experimento (o sea, los define al principio y el valor de N. Tener en cuenta que podrían cambiar en experimentos futuros, pero que si lo hacen los resultados ya no serán comparables).

- CPUBENCH

Para este primer archivo elegimos la siguiente métrica en [cpubench.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/user/cpubench.c)

```c

metric = total_cpu_kops/(elapsed_ticks);

```

Esta métrica nos asegura una proporción entre la cantidad de ciclos de cpu y cuantos se realizan por tick. De esta forma podemos hacer varios test y tener datos comparables para evaluar el rendimiento del cpu.

- IOBENCH

 En [iobench.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/master/user/iobench.c) podemos ver otra métrica:

```c

metric = (total_iops * 100) / (elapsed_ticks);

```

Es muy similar a la que se utiliza en cpubench.c, sin embargo la multiplicamos por una constante para no perder información con los numeros enteros que no reflejan la diferencia de centésimas. Esto se debe a que, en nuestro caso, la relación entre cantidad de operaciones realizadas por tick es menor a la del programa previo, por lo que la métrica era mucho menor y nos otorgaba menos datos.

- VALOR DE N

Para ambos casos valuamos N en 20, para que la prueba sea lo suficiente larga y obtener un promedio acertado. 

### 2) ¿Los procesos se ejecutan en paralelo? ¿En promedio, qué proceso o procesos se ejecutan primero? Hacer una observación cualitativa.

Análisis de acuerdo a las siguientes [tablas](https://docs.google.com/spreadsheets/d/1NOF3BPnh1ZzkyHHN4DFf6lLO8uciOs_GQgPA_3SJhmY/edit?gid=0#gid=0).

Mientras sean del mismo tipo (Es decir, CPU o IO) los procesos se ejecutan en pararelo en diferentes núcleos, consiguiendo métricas (rendimiento) similares siempre y cuando hayan nucleos disponibles. Cuando esto no ocurre, la cantidad de operaciones por ticks disminuye en proporción a los núcleos.

- ` iobench 20 &; cpubench 20 &; cpubench 20 &; cpubench 20 & `

Todas las veces que probamos este experimento, comienza trabajando con cpubench hasta finalizar las instrucciones relacionadas al mismo y luego se encarga de las iobench hasta finalizarlas también.

Creemos que esto ocurre pues los procesos iobounds se bloquean muchas veces al hacer sus correspondientes E/S y esto provoca que "pierdan oportunidades" para ser ejecutados dentro de scheduler(). 

- ` cpubench 20 &; iobench 20 &; iobench 20 &; iobench 20 & `

Después de varias ejecuciones notamos que, mientras haya intrucciones de cada tipo, estas se ejecutan intercarladamente. Al acabarse las cpubench, pasan a intercalarse las instrucciones de iobench que quedan, dejando un único programa trabajando por sí solo al final.

### 3) ¿Cambia el rendimiento de los procesos iobound con respecto a la cantidad y tipo de procesos que se estén ejecutando en paralelo? ¿Por qué?

Si cambia el rendimiento. Cuando trabajamos ` iobench 20 & `, notamos que la métrica es mucho menor que cuando trabajamos con ` iobench 20 &; iobench 20 &; iobench 20 & `. Esto quiere decir que tenemos un peor rendimiento cuando hay un solo proceso pues los ticks son mayores y en consecuencia, el programa termina su ejecución más tarde. En el caso contrario, cuando los procesos trabajan en pararelo, los ticks son menores y así nuestro programa termina antes. 

Ahora, cuando trabajamos varios iobench con cpubench (`cpubench 20 &; iobench 20 &; iobench 20 &; iobench 20 &`) notamos que, mientras haya instrucciones de cpu, los iobench tienen el mismo rendimiento que ` iobench 20 & `, por más de que hayan mas iobench activos.

En el ultimo caso, `iobench 20 &; cpubench 20 &; cpubench 20 &; cpubench 20 &`, como ya dijimos, se trabajan primero los cpubench. Luego, el primer iobench entrará con una gran cantidad de ticks, para estabilizarse despues a la misma métrica que un iobench solitario.

### 4) ¿Cambia el rendimiento de los procesos cpubound con respecto a la cantidad y tipo de procesos que se estén ejecutando en paralelo? ¿Por qué?

No cambia el rendimiento, en todos los casos. Como ya dijimos, mientras haya núcleos disponibles cada proceso trabaja en paralelo con el mismo rendimiento, y lo mismo sucede cuando se ejecutan junto con procesos iobench. 

### 5) ¿Es adecuado comparar la cantidad de operaciones de cpu con la cantidad de operaciones iobound?

No, son procesos distintos. Ambos procesos tienen un impacto diferente en el sistema operativo.

Las operaciones iobound generalmente implican mucho más tiempo de espera debido a la naturaleza de las entradas y salidas, por ejemplo, la latencia del disco. Por otro lado, las operaciones cpubound realizan ciclos de cpu activamente, sin depender de recursos externos. 

## Experimento 2: ¿Qué sucede cuando cambiamos el largo del quantum?

ANÁLISIS DE LOS [GRAFICOS](https://docs.google.com/spreadsheets/d/1X_z22mkusuG10WG-IyVlRsNinolY0wfagJzcijZ2UCE/edit?gid=370018408#gid=370018408)

ANÁLISIS DE LAS TABLAS:
- [quantum 100000](https://docs.google.com/spreadsheets/d/1NOF3BPnh1ZzkyHHN4DFf6lLO8uciOs_GQgPA_3SJhmY/edit?gid=0#gid=0)
- [quantum 10000](https://docs.google.com/spreadsheets/d/1NOF3BPnh1ZzkyHHN4DFf6lLO8uciOs_GQgPA_3SJhmY/edit?gid=1015145003#gid=1015145003)
- [quantum 1000](https://docs.google.com/spreadsheets/d/1NOF3BPnh1ZzkyHHN4DFf6lLO8uciOs_GQgPA_3SJhmY/edit?gid=1170064068#gid=1170064068)

### 1) ¿Fue necesario modificar las métricas para que los resultados fueran comparables? ¿Por qué?

Si, fue necesario modificar, ya que al aumentar el quantum aumenta la cantidad de ticks y en los casos de iobound nos quedaban métricas de pocos dígitos, perdiendo así mucha información y haciendo incomparables las métricas.

En el caso del cpubound no había tanta pérdida de información pues contabamos con bastantes dígitos pero la modificamos, ya que nos pareció lo más apropiado para la comparación mantener la misma exactitud. 

			
- QUANTUM 1000		
```c
metric = (total_cpu_kops * 100)/(elapsed_ticks)	 //cpubench
metric = (total_iops * 10000) / (elapsed_ticks)  //iobench
```		

- QUANTUM 10000		
```c
metric = (total_cpu_kops * 10)/(elapsed_ticks)	 //cpubench
metric = (total_iops * 1000) / (elapsed_ticks)  //iobench
```		
### 2) ¿Qué cambios se observan con respecto al experimento anterior? ¿Qué comportamientos se mantienen iguales?

Las métricas bajaron, lo cual implica que el rendimiento fue peor en todos los casos. Sin embargo, se comportaron de manera análoga.

Notamos que en `iobench 20 &; cpubench 20 &; cpubench 20 &; cpubench 20 &` ahora no se ejecutan todos los cpubound primero, sino que se intercalan un poco más frecuentemente con las instrucciones de iobench.

### 3) ¿Con un quantum más pequeño, se ven beneficiados los procesos iobound o los procesos cpubound?

Si bien no se benefician en rendimiento, con el quantum más chico, el scheduler() detecta más rápido la disponibilidad de los procesos iobound, que se aprovechan de este nuevo tiempo para trabajar más rápidamente entre cada bloqueo. Esto no beneficia a los procesos cpubound, sino que los perjudica, ya que son interrumpidos con más frecuencia. 


# Tercera Parte: Asignar prioridad a los procesos

### 1)

- Modificamos la estructura en [proc.h](https://bitbucket.org/sistop-famaf/so24lab3g06/src/mlfq/kernel/proc.h)

```c
int priority;                // Define process priority
int picked_times;            // Times the proccess has been selected by the CPU
```
- Inicializamos dentro de la función fork() en [proc.c](https://bitbucket.org/sistop-famaf/so24lab3g06/src/mlfq/kernel/proc.c) (Regla 3)
```c
np->priority = NPRIO-1;  // Initialize priority
np->picked_times = 0;   // initialize run times
```
- Bajamos la prioridad en `yield` (Regla 4)
```c
  if(p->priority > 0){
    p->priority--;

```
- Y subimos la prioridad cuando el proceso se bloquea, en `sleep` (Regla 4)
```c
  // If priority is not the maxium, increase it
  if(p->priority < NPRIO-1){
    p->priority++;
  }
}
```
- Agregamos el contador en la función de `scheduler`
```c
        p->picked_times++; 
```
### 2)

Modificamos `procdump` para que nos muestre la prioridad de los procesos en ejecución
```c
printf("%d %s %s %d \n", p->pid, state, p->name, p->priority);
```
# Cuarta Parte: Implementar MLFQ

### 1)
En la función [scheduler()](https://bitbucket.org/sistop-famaf/so24lab3g06/src/mlfq/kernel/proc.c#lines-446) dentro de proc.c, hicimos los cambios necesarios para implementar la regla 1 y regla 2 de MLFQ. 

### 2) Repita las mediciones de la segunda parte para ver las propiedades del nuevo planificador.
Repetimos las mediciones, detalladas en [TABLAS](https://docs.google.com/spreadsheets/d/12Ky4o-Q1f7w1JnqcGg_UAGU5Xng-Ay6a4CkW7HPuwy0/edit?gid=0#gid=0), hay una hoja para cada quantum. [GRAFICOS](https://docs.google.com/spreadsheets/d/1X_z22mkusuG10WG-IyVlRsNinolY0wfagJzcijZ2UCE/edit?gid=0#gid=0), hay una hoja para cada tipo de proceso.

- En cuanto a rendimiento, es análogo entre los planificadores con quantums mayores.
 
- Sin embargo, en los quantum chicos, los procesos se perjudican exponencialmente en el planificador MLFQ. Esto se debe ya que al tardar más en elegir un proceso, se destinan mas ciclos de cpu a la elección y no a la ejecución del mismo.

- No obstante, el planificador MLFQ demuestra que es más pareja la distribución del tiempo de ejecución, especialmente para los procesos iobound. 

### 3) Para análisis responda: ¿Se puede producir starvation en el nuevo planificador? Justifique su respuesta.

Si se puede producir starvation. Esto se debe a que los procesos en niveles bajos de prioridad pueden terminar rezagados por procesos nuevos que comienzan con máxima prioridad, o por procesos iobound.

Por ejemplo, pueden ocurrir programas maliciosos que abusen de este problema, como una bomba fork:

```c
while(1){
  fork();
}
```
En este laboratorio resolvemos la starvation en una [branch aparte.](https://bitbucket.org/sistop-famaf/so24lab3g06/src/Regla5/)