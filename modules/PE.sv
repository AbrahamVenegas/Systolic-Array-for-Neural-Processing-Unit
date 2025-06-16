module PE #(parameter int WIDTH = 16) 
(
	input  logic clk,
	input  logic rst,

	input  logic signed [WIDTH-1:0] weight,     // Peso del PE
	input  logic signed [WIDTH-1:0] in_left,    // Entrada desde la izquierda
	input  logic signed [WIDTH-1:0] in_up,      // Entrada desde arriba

	output logic signed [WIDTH-1:0] out_right,  // Salida hacia el PE de la derecha
	output logic signed [WIDTH-1:0] out_down,   // Salida hacia el PE de abajo
	output logic ready                          // Señal de listo (true si no hay PE a la derecha)
);

	// Flip-flops (almacenan las entradas anteriores)
	logic signed [WIDTH-1:0] temp_left;
	logic signed [WIDTH-1:0] temp_up;
	logic signed [WIDTH-1:0] calc;

	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			temp_left <= 0;
			temp_up   <= 0;
			calc      <= 0;
			ready     <= 0;
		end else begin
			temp_left <= in_left;
			temp_up   <= in_up;
			calc      <= (in_up * weight) + in_left;
			// Si no hay PE a la derecha, se asume que es el final
			ready     <= (out_right === 'x);
		end
	end

	assign out_right = calc;
	assign out_down  = in_up; // Propaga hacia abajo

endmodule
