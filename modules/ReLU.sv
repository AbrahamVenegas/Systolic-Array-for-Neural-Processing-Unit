
`timescale 1ns/1ps

module ReLU #(parameter int WIDTH = 16)
(
	input  logic signed [WIDTH-1:0] in_val,
	input  logic ReLU_activation,
	output logic signed [WIDTH-1:0] out_val
	
);

always_comb begin

	if (ReLU_activation) begin
			if (in_val > 0)
				out_val = in_val;
			else
				out_val = 0;
		end else begin
			out_val = in_val;	
		end

	end
	
endmodule
