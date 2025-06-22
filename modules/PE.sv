
`timescale 1ns/1ps
module PE #(parameter int WIDTH = 16) 
(
	input  logic clk,
	input  logic rst,

	input  logic signed [WIDTH-1:0] weight,     // Peso del PE
	input  logic signed [WIDTH-1:0] in_left,    // Entrada desde la izquierda
	input  logic signed [WIDTH-1:0] in_up,      // Entrada desde arriba
	input  logic enable,

	output logic signed [WIDTH-1:0] out_right,  // Salida hacia el PE de la derecha
	output logic signed [WIDTH-1:0] out_down,   // Salida hacia el PE de abajo
	output logic [31:0] int_op_count, // contador de INT_OPS
	output logic enable_out, // salida de enable (entrada del siguiente PE)

	output logic overflow // detección de overflow
);
	logic signed [WIDTH-1:0] calc;
	logic signed [2*WIDTH-1:0] calc_full;
	logic [31:0] int_op_counter; // registro para contar INT_OPS

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			calc_full      <= 0;
			calc      <= 0;
			int_op_counter <= 0;
		end else begin
			if (enable) begin // Solo si realiza el calculo si enable es 1
				calc_full      <= (in_up * weight) + in_left;
                calc           <= (in_up * weight) + in_left;
                int_op_counter <= int_op_counter + 2;
         end else begin
				calc_full      <= 0;
                calc           <= 0;
                int_op_counter <= int_op_counter;
			end
		end
	end

	assign out_right = calc;
	assign out_down  = in_up; // Propaga hacia abajo
	assign int_op_count = int_op_counter; // asignar el contador local al output
	assign enable_out = enable; 

	assign overflow = (calc_full > $signed({1'b0, {(WIDTH-1){1'b1}}})) ||
                      (calc_full < $signed({1'b1, {(WIDTH-1){1'b0}}}));

endmodule
