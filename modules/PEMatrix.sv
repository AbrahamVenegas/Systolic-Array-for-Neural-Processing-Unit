`timescale 1ns/1ps

module PEMatrix #(parameter WIDTH = 16) 
(
	input  logic clk,
	input  logic rst,
	input  logic signed [WIDTH-1:0] in_left [3:0],
	input  logic signed [WIDTH-1:0] in_up   [3:0],
	input  logic signed [WIDTH-1:0] weights [3:0][3:0],
	input  logic enable [4],
	output logic signed [WIDTH-1:0] out_right [3:0],
	output logic signed [WIDTH-1:0] out_down  [3:0],
	output logic [31:0] int_ops,
	output logic overflow,
	
	input ReLU_activation

);

	logic signed [WIDTH-1:0] link_h [4][5]; // Enlaces horizontales entre PEs
	logic signed [WIDTH-1:0] link_v [5][4]; // Enlaces verticales entre PEs
	logic link_enable [5][4]; // enlaces verticales de enable
	logic [31:0] int_op_counts [3:0][3:0]; // matriz de registros para contar INT_OPS de cada PE

	logic overflow_mat [3:0][3:0];

	assign link_h[0][0] = in_left[0];
	assign link_h[1][0] = in_left[1];
	assign link_h[2][0] = in_left[2];
	assign link_h[3][0] = in_left[3];

	assign link_v[0][0] = in_up[0];
	assign link_v[0][1] = in_up[1];
	assign link_v[0][2] = in_up[2];
	assign link_v[0][3] = in_up[3];

	assign link_enable[0][0] = enable[0];
	assign link_enable[0][1] = enable[1];
	assign link_enable[0][2] = enable[2];
	assign link_enable[0][3] = enable[3]; 

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
				   .enable(link_enable[i][j]),
				   .out_right(link_h[i][j+1]),
				   .out_down(link_v[i+1][j]),
				   .int_op_count(int_op_counts[i][j]),
				   .enable_out(link_enable[i+1][j]),
				   .overflow(overflow_mat[i][j])
				 );
			end
		end
	endgenerate

	// sumar todos los contadores de los PEs
	logic [31:0] int_op_sum;
    always_comb begin
        int_op_sum = 0;
		overflow = 0;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++) begin
                int_op_sum += int_op_counts[i][j];
				overflow |= overflow_mat[i][j];
			end
    end
    assign int_ops = int_op_sum; // asignar la suma al output
	
	generate
		for (i = 0; i < 4; i++) begin : row_relu
			ReLU #(.WIDTH(WIDTH)) relu_inst
			(
				.in_val(link_h[i][4]),
				.out_val(out_right[i]),
				.ReLU_activation(ReLU_activation)
			);
		end
		
	endgenerate

	assign out_down[0] = link_v[4][0];
	assign out_down[1] = link_v[4][1];
	assign out_down[2] = link_v[4][2];
	assign out_down[3] = link_v[4][3];

endmodule
