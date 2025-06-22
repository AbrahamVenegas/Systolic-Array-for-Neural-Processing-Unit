`timescale 1ns/1ps

import SystolicTypes::*;

module SystolicTemp #(parameter N = 4, parameter int WIDTH = 16) (
    // Inputs
    input logic clk, rst, new_data,
    input logic stepping_enable, step,
	input logic ReLU_activation,
    input logic unsigned [11:0] addr_A, addr_B, addr_C, 
    input logic unsigned [8:0] n,

    // Control / Debug / Status
    output system_status_t system_status,
    output memory_status_t memory_status,
    output error_code_t error_code,
    output state_t fsm_state,
    output state_t fsm_state_next_stepping,
    output logic unsigned [15:0] total_cycles,
    output logic unsigned [31:0] int_ops,
    output logic [31:0] reads_count,
    output logic [31:0] writes_count,
    output logic signed [WIDTH - 1:0] matrix_C [N - 1:0][N - 1:0],
    output logic unsigned [11:0] act_addr,
    output logic signed [WIDTH - 1:0] mem_read


    // Temporales
    // output logic mem_write,
    // output logic signed [WIDTH - 1:0] mem_data_write,
    // output logic [11:0] act_addr,
	// output logic signed [WIDTH - 1:0] mem_read,
    // output logic signed [WIDTH - 1:0] weight_output [N - 1:0][N - 1:0],
    // output logic signed [WIDTH - 1:0] data_up [N - 1:0],
	// output logic signed [WIDTH - 1:0] result_col [N - 1:0],
	// output logic [7:0] cycle_count,
    // output logic enable_out [4],
	// output state_t fsm_state_next,
    // output state_t fsm_state_next_stepping_next,
	// output logic done,
	// output logic overflow_out
);		

    // Registros y señales internas
	logic signed [WIDTH - 1:0] out_down [N - 1:0];
    logic enable [N];
    logic overflow; 
    logic new_data_controller;

    logic mem_write;
    logic signed [WIDTH - 1:0] mem_data_write;
    // logic [11:0] act_addr;
	// logic signed [WIDTH - 1:0] mem_read;
    logic signed [WIDTH - 1:0] weight_output [N - 1:0][N - 1:0];
    logic signed [WIDTH - 1:0] data_up [N - 1:0];
	logic signed [WIDTH - 1:0] result_col [N - 1:0];
	logic [7:0] cycle_count;
    logic enable_out [4];
	state_t fsm_state_next;
    state_t fsm_state_next_stepping_next;
	logic done;
	logic overflow_out;
    


    assign enable_out = enable;

    // Implementación de la lógica del controlador aquí
    SystolicController #(.N(N), .WIDTH(WIDTH)) controller_inst (
        .clk(clk),
        .rst(rst),
        .new_data(new_data_controller),
        .mem_read(mem_read),
        .result_col(result_col),
        .addr_A(addr_A),
        .addr_B(addr_B),
        .addr_C(addr_C),
        .n(n),
        .mem_write(mem_write),
        .mem_data_write(mem_data_write),
        .act_addr(act_addr),
        .weight_output(weight_output),
        .data_up(data_up),
        .fsm_state(fsm_state),
		  .cycle_count(cycle_count),
          .enable(enable),
          .reads_count(reads_count),
          .writes_count(writes_count),
			 
			// Implementando 
          .fsm_state_next(fsm_state_next),
        .fsm_state_next_stepping(fsm_state_next_stepping),
        .fsm_state_next_stepping_next(fsm_state_next_stepping_next),
			.stepping_enable(stepping_enable),
			.step(step),
			.done(done),
			.total_cycles(total_cycles),
            .overflow_in(overflow),
            .overflow_out(overflow_out),
            .matrix_C(matrix_C)
	
    );

    
    

    ControlModule #(.WIDTH(WIDTH)) control_module_inst (
        .start(new_data),
        .matrix_N(n),
        .fsm_state_controller(fsm_state),
        .fsm_state_controller_stepping(fsm_state_next_stepping),
        .stepping_enable(stepping_enable),
        .op_done(done),
        .overflow(overflow_out),
        .system_status(system_status),
        .memory_status(memory_status),
        .error_code(error_code),
        .new_data_out(new_data_controller),
		  .addr_A(addr_A),
		  .addr_B(addr_B),
		  .addr_C(addr_C)

    );
	 
    logic signed [WIDTH - 1:0] in_left [0:N - 1];
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen
            assign in_left[i] = '0;
        end
    endgenerate
	 
	 

    PEMatrix #(.WIDTH(WIDTH)) pe_matrix_inst (
        .clk(clk),
        .rst(rst),
        .in_left(in_left),
        .in_up(data_up),
        .weights(weight_output),
        .enable(enable),
        .out_right(result_col),
        .out_down(out_down),
        .int_ops(int_ops),
        .overflow(overflow),
		  .ReLU_activation(ReLU_activation)
    );
	 
	 Memory mem_inst (
		  .address(act_addr),
        .clock(~clk),
        .data(mem_data_write),
        .wren(mem_write),
        .q(mem_read)
	 );
	 

endmodule 


