module main #(parameter WIDTH = 16) 
(
	input  logic clk,
	input  logic rst,
	input  logic signed [WIDTH-1:0] in_left [4],
	input  logic signed [WIDTH-1:0] in_up   [4],
	input  logic signed [WIDTH-1:0] weights [4][4],
	output logic signed [WIDTH-1:0] out_right [4],
	output logic signed [WIDTH-1:0] out_down  [4]
);

	logic signed [WIDTH-1:0] link_h [4][5]; // Enlaces horizontales entre PEs
	logic signed [WIDTH-1:0] link_v [5][4]; // Enlaces verticales entre PEs

	assign link_h[0][0] = in_left[0];
	assign link_h[1][0] = in_left[1];
	assign link_h[2][0] = in_left[2];
	assign link_h[3][0] = in_left[3];

	assign link_v[0][0] = in_up[0];
	assign link_v[0][1] = in_up[1];
	assign link_v[0][2] = in_up[2];
	assign link_v[0][3] = in_up[3];

	genvar i, j;
	generate
		for (i = 0; i < 4; i++) begin : row
			for (j = 0; j < 4; j++) begin : col
				PE #(.WIDTH(WIDTH)) pe_inst 
				(
					.clk(clk),
				   .rst(rst),
				   .weight(weights[i][j]),
					.in_left(link_h[i][j]),
				   .in_up(link_v[i][j]),
				   .out_right(link_h[i][j+1]),
				   .out_down(link_v[i+1][j]),
				   .ready()
				 );
			end
		end
	endgenerate

	// Asignar salidas finales
	assign out_right[0] = link_h[0][4];
	assign out_right[1] = link_h[1][4];
	assign out_right[2] = link_h[2][4];
	assign out_right[3] = link_h[3][4];

	assign out_down[0] = link_v[4][0];
	assign out_down[1] = link_v[4][1];
	assign out_down[2] = link_v[4][2];
	assign out_down[3] = link_v[4][3];

endmodule
