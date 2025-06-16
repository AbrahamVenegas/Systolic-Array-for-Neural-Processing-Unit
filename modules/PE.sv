module PE #(parameter int WIDTH = 16) 
(
	input  logic clk,
	input  logic rst,

	input  logic signed [WIDTH-1:0] weight,     // Peso del PE
	input  logic signed [WIDTH-1:0] in_left,    // Entrada desde la izquierda
	input  logic signed [WIDTH-1:0] in_up,      // Entrada desde arriba

	output logic signed [WIDTH-1:0] out_right,  // Salida hacia el PE de la derecha
	output logic signed [WIDTH-1:0] out_down   // Salida hacia el PE de abajo
);
	logic signed [WIDTH-1:0] calc;

	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			calc      <= 0;
		end else begin
			calc      <= (in_up * weight) + in_left;
		end
	end

	assign out_right = calc;
	assign out_down  = in_up; // Propaga hacia abajo

endmodule
