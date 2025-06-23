

import SystolicTypes::*;

module FPGA_Controller #(parameter WIDTH = 16, parameter N = 4) 
(	
		input logic clk, rst,
        input logic start,
        input logic stepping_enable, step,
        input logic ReLU_activation,

        // Para interactuar con la memoria
        input logic right, left,
        input logic switch_mem_access,
        output logic signed [WIDTH - 1:0] mem_read,

        // Para ver en que dirección se está accediendo
        output logic unsigned [11:0] addr_FPGA
);
    system_status_t system_status;
    memory_status_t memory_status;
    error_code_t error_code;
    state_t fsm_state;
    state_t fsm_state_next_stepping;
    logic unsigned [15:0] total_cycles;
    logic unsigned [31:0] int_ops;
    logic signed [WIDTH - 1:0] matrix_C [N - 1:0][N - 1:0];
    logic unsigned [11:0] act_addr;

    // Quemar los valores de memoria
    logic unsigned [11:0] addr_A, addr_B, addr_C;
    logic unsigned [8:0] n;
    assign n = 4;
    assign addr_A = 0;
    assign addr_B = 16;
    assign addr_C = 32;
  
    // Moverse a la derecha o izquierda en la dirección de memoria FPGA
    always_ff @(posedge left or posedge right or posedge rst) begin
        if (rst) begin
            addr_FPGA <= 12'd0; // Valor default al reset
        end else if (left) begin
            addr_FPGA <= addr_FPGA - 1;
        end else if (right) begin
            addr_FPGA <= addr_FPGA + 1;
        end
    end

    // Instancia de SystolicTemp
    SystolicTemp #(.N(N), .WIDTH(WIDTH)) systolic_temp_inst (
        .clk(clk),
        .rst(rst),
        .new_data(start),
        .stepping_enable(stepping_enable),
        .step(step),
        .ReLU_activation(ReLU_activation),
        .addr_A(addr_A),
        .addr_B(addr_B),
        .addr_C(addr_C),
        .n(n),
        .mem_read(mem_read),
        .act_addr(act_addr),
        .matrix_C(matrix_C),
        .int_ops(int_ops),
        .total_cycles(total_cycles),
        .fsm_state(fsm_state),
        .fsm_state_next_stepping(fsm_state_next_stepping),
        .system_status(system_status),
        .memory_status(memory_status),
        // Outputs para el controlador
        .error_code(error_code),
        .act_addr_FPGA(addr_FPGA),
        .switch_mem_access(switch_mem_access)
    );



endmodule