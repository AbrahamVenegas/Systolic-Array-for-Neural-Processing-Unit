module ReLU #(parameter int WIDTH = 16)
(
	input  logic signed [WIDTH-1:0] in_val,
	output logic signed [WIDTH-1:0] out_val
);

always_comb begin

	if (in_val > 0)
		out_val = in_val;
	else
		out_val = 0;
	end
	
endmodule
