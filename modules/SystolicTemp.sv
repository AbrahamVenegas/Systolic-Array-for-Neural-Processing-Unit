`timescale 1ns/1ps

import SystolicTypes::*;

module SystolicTemp #(parameter N = 4, parameter int WIDTH = 16) (
    // Inputs
    input logic clk, rst, new_data,
    
	 
    input logic [11:0] addr_A, addr_B, addr_C, 
    input logic [3:0] n,

    // Outputs (temporales para memoria)
    output logic mem_write,
    output logic signed [WIDTH - 1:0] mem_data_write,
    output logic [11:0] act_addr,

    // Outputs (temporales para ver funcionamiento de PEs, CU y mem)
	 output logic signed [WIDTH - 1:0] mem_read,
    output logic signed [WIDTH - 1:0] weight_output [N - 1:0][N - 1:0],
    output logic signed [WIDTH - 1:0] data_up [N - 1:0],
	 output logic signed [WIDTH - 1:0] result_col [N - 1:0],

    // Temporales
	 output logic [7:0] cycle_count,
    output state_t fsm_state,

    // outputs performance counters
    output logic [31:0] int_ops,
    output logic enable_out [4]
);	
	
	logic signed [WIDTH - 1:0] out_down [N - 1:0];
    logic enable [N];

    assign enable_out = enable;

    // Implementación de la lógica del controlador aquí
    SystolicController #(.N(N), .WIDTH(WIDTH)) controller_inst (
        .clk(clk),
        .rst(rst),
        .new_data(new_data),
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
          .enable(enable)
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
        .int_ops(int_ops)
    );
	 
	 Memory mem_inst (
		  .address(act_addr),
        .clock(~clk),
        .data(mem_data_write),
        .wren(mem_write),
        .q(mem_read)
	 );
	 

endmodule 


