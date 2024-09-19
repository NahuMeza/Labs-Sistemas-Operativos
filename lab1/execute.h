/* Ejecuta comandos simples y pipelines.
 * No toca ningún comando interno.
 */

#ifndef EXECUTE_H
#define EXECUTE_H

#include "command.h"
/*
 * Ejecuta un pipeline, identificando comandos internos, forkeando, y
 *   redirigiendo la entrada y salida. puede modificar `apipe' en el proceso
 *   de ejecución.
 *   apipe: pipeline a ejecutar
 * Requires: apipe!=NULL
 */
void execute_pipeline(pipeline apipe);
/* Establece las direcciones de entrada y salida del comando.
 *   apipe: pipeline a ejecutar
 *   Es una función interna para el execute_pipeline
 */
void redirection(scommand cmd);
/*
 * Ejecuta un scommmand que no esté en el builtin, separandolo en un arreglo para
 *   que lo ejecute el sistema.
 *   cmd: scommand a ejecutar
 *   Es una función interna para el execute_pipeline
 */
void execute_command(scommand cmd);

#endif /* EXECUTE_H */
