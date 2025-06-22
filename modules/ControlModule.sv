import SystolicTypes::*;

module ControlModule #(parameter WIDTH = 16) (
    // Inputs --------------------------------
    input logic start, //reset, // write_mem, read_mem
   
    input logic unsigned [11:0] addr_A, addr_B, addr_C, 
    input logic unsigned [8:0] matrix_N, // Verificar el tamaño máximo de n
    // input logic ReLU_enable, stepping_enable, step,

    // Para obtener estados del controlador
    input state_t fsm_state_controller_stepping,
    input state_t fsm_state_controller,
    input logic stepping_enable, // Para el modo stepping
    input logic op_done,
    input logic overflow,

    // Outputs -------------------------------
    output system_status_t system_status,
    output memory_status_t memory_status,
    // output state_t fsm_state,
    output error_code_t error_code,
    output logic new_data_out 
);

    // Assignaciones
    assign new_data_out = start && (error_code == NO_ERROR || error_code == OVERFLOW);
    logic fsm_state_analyze;
    assign fsm_state_analyze = (stepping_enable) ? fsm_state_controller_stepping : fsm_state_controller;
    assign system_status = (fsm_state_analyze != IDLE) ? BUSY :       
                           (fsm_state_analyze == IDLE && op_done) ? DONE_AND_WAITING : WAITING; 
    
    assign memory_status = (fsm_state_controller == WAITING_MEMORY_A || 
                            fsm_state_controller == WAITING_MEMORY_B) ? READING :
                           (fsm_state_controller == WRITEBACK) ? WRITING : IDLE_MEMORY;

    // Implementar logica en el controlador
    assign error_code = (matrix_N == 0 || matrix_N > 128) ? INVALID_N_VALUE :
                     (addr_A + (matrix_N * matrix_N)  >= 4096 || addr_B + (matrix_N * matrix_N) >= 4096 || addr_C + (matrix_N * matrix_N) >= 4096) ? OUT_OF_BOUNDS :
                     (overflow) ? OVERFLOW : // Implementar bit overflow
                     NO_ERROR;

endmodule 