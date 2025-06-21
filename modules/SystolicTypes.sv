`timescale 1ns/1ps

package SystolicTypes;
    // Estados de la máquina de estados finita (FSM)
    typedef enum logic [2:0] {
        IDLE,
        MEMORY,
        WAITING_MEMORY_A,
        WAITING_MEMORY_B,
        EXECUTE,
        WRITEBACK,
        WAITING_STEP
    } state_t;

    // Estados de control
    typedef enum logic [1:0] {
        WAITING,
        BUSY,
        DONE_AND_WAITING
    } system_status_t;

    // Estados para la memoria
    typedef enum logic [2:0] {
        READING,
        WRITING,
        IDLE_MEMORY
    } memory_status_t;

    // Errores posibles en el sistema
    typedef enum logic [2:0] {
        OUT_OF_BOUNDS,      // Problema de acceso a memoria fuera de los límites
        OVERFLOW,           // Desbordamiento de datos
        UNEXPECTED_ERROR,   // Error inesperado
        INVALID_N_VALUE,    // Valor de N inválido
        NO_ERROR            // Sin errores
    } error_code_t;

    
endpackage