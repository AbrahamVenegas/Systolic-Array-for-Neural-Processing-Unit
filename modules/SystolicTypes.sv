`timescale 1ns/1ps

package SystolicTypes;
    typedef enum logic [2:0] {
        IDLE,
        MEMORY,
        WAITING_MEMORY_A,
        WAITING_MEMORY_B,
        EXECUTE,
        WRITEBACK
    } state_t;
endpackage