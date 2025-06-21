import SystolicTypes::*;



module ControlModule #(parameter WIDTH = 16) (
    // input logic clk, ??
    // Inputs --------------------------------
    input logic start, reset, write_mem, read_mem,
    input logic unsigned [WIDTH - 1:0] mem_data_write, // Datos a escribir en memoria
    input logic unsigned [11:0] addr_ctrl, // Dirección de memoria a escribir
   
    input logic unsigned [11:0] addr_A, addr_B, addr_C, 
    input logic unsigned [8:0] matrix_N, // Verificar el tamaño máximo de n
    input logic ReLU_enable, stepping_enable, step,

    // Para obtener estados del controlador
    input logic mem_write_controller,
    input logic unsigned [15:0] cycle_count_controller,
    input state_t fsm_state_controller,
    input logic unsigned [31:0] int_ops_in,
    input logic op_done,
    input logic overflow,

    // Outputs -------------------------------
    output system_status_t system_status,
    output memory_status_t memory_status,
    output state_t fsm_state,
    output error_code_t error_code,
    output logic unsigned [15:0] cycle_count,
    output logic unsigned [WIDTH - 1:0] mem_data_read, // Datos leidos de memoria

    // Outputs para intensidad aritmética
    output logic unsigned [31:0] int_ops,
    // faltaria uno como este: output logic [31:0] mem_ops

    // Para controlar el arreglo sistólico
    output logic new_data_out, rst_out,
    output logic unsigned [11:0] addr_A_out, addr_B_out, addr_C_out,
    output logic unsigned [8:0] matrix_N_out // Verificar el tamaño máximo de n
);

    // Assignaciones
    assign new_data_out = start && (error_code == NO_ERROR || error_code == OVERFLOW);
    assign rst_out = reset;
    assign addr_A_out = addr_A;
    assign addr_B_out = addr_B;
    assign addr_C_out = addr_C;
    assign matrix_N_out = matrix_N;
    assign fsm_state = fsm_state_controller;
    assign int_ops = int_ops_in;
    assign cycle_count = cycle_count_controller;
    assign system_status = (fsm_state_controller != IDLE) ? BUSY :       
                           (fsm_state_controller == IDLE && op_done) ? DONE_AND_WAITING : WAITING; 
    
    assign memory_status = (fsm_state_controller == WAITING_MEMORY_A || 
                            fsm_state_controller == WAITING_MEMORY_B) ? READING :
                           (fsm_state_controller == WRITEBACK) ? WRITING : IDLE_MEMORY;

    // Implementar logica en el controlador
    assign error_code = (matrix_N == 0 || matrix_N > 128) ? INVALID_N_VALUE :
                     (addr_A + (matrix_N * matrix_N)  >= 4096 || addr_B + (matrix_N * matrix_N) >= 4096 || addr_C + (matrix_N * matrix_N) >= 4096) ? OUT_OF_BOUNDS :
                     (overflow) ? OVERFLOW : // Implementar bit overflow
                     NO_ERROR;



endmodule 