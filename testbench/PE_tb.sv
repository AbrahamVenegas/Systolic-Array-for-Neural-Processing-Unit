`timescale 1ns/1ps

module PE_tb;

    localparam WIDTH = 16;

    logic clk, rst;
    logic signed [WIDTH-1:0] weight, in_left, in_up;
    logic enable;
    logic signed [WIDTH-1:0] out_right, out_down;
    logic [31:0] int_op_count;
    logic enable_out;
    logic overflow;

    // Instancia del PE
    PE #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .weight(weight),
        .in_left(in_left),
        .in_up(in_up),
        .enable(enable),
        .out_right(out_right),
        .out_down(out_down),
        .int_op_count(int_op_count),
        .enable_out(enable_out),
        .overflow(overflow)
    );

    // Generador de reloj
    initial clk = 0;
    always #5 clk = ~clk;


    initial begin
        // Inicialización
        rst = 1;
        enable = 0;
        weight = 0;
        in_left = 0;
        in_up = 0;
        #12;
        rst = 0;

        // Prueba 1: operación simple
        @(negedge clk);
        weight = 3;
        in_left = 2;
        in_up = 4;
        enable = 1;
        @(posedge clk);
        #1;
        if (out_right == (4*3+2))
            $display("OK: out_right expected=%0d, obtained=%0d", (4*3+2), out_right);
        else
            $display("ERROR: out_right expected=%0d, obtained=%0d", (4*3+2), out_right);

        if (int_op_count == 2)
            $display("OK: int_op_count expected=2, obtained=%0d", int_op_count);
        else
            $display("ERROR: int_op_count expected=2, obtained=%0d", int_op_count);

        if (out_down == 4)
            $display("OK: out_down expected=4, obtained=%0d", out_down);
        else
            $display("ERROR: out_down expected=4, obtained=%0d", out_down);

        if (enable_out == 1)
            $display("OK: enable_out expected=1, obtained=%0d", enable_out);
        else
            $display("ERROR: enable_out expected=1, obtenido=%0d", enable_out);

        if (!overflow)
            $display("OK: overflow expected=0, obtained=%0d", overflow);
        else
            $display("ERROR: overflow expected=0, obtained=%0d", overflow);

        // Prueba 2: deshabilitar enable
        @(negedge clk);
        enable = 0;
        @(posedge clk);
        #1;
        if (out_right == 0)
            $display("OK: out_right expected=0, obtained=%0d", out_right);
        else
            $display("ERROR: out_right expected=0, obtained=%0d", out_right);

        if (int_op_count == 2)
            $display("OK: int_op_count expected=2, obtained=%0d", int_op_count);
        else
            $display("ERROR: int_op_count expected=2, obtained=%0d", int_op_count);

        // Prueba 3: overflow positivo
        @(negedge clk);
        enable = 1;
        weight = 2**(WIDTH-1)-1;
        in_left = 2**(WIDTH-1)-1;
        in_up = 2;
        @(posedge clk);
        #1;
        if (overflow)
            $display("OK: overflow expected=1, obtained=%0d", overflow);
        else
            $display("ERROR: overflow expected=1, obtained=%0d", overflow);

        // Prueba 4: reset
        @(negedge clk);
        rst = 1;
        @(posedge clk);
        #1;
        if (out_right == 0)
            $display("OK: out_right expected=0 after reset, obtained=%0d", out_right);
        else
            $display("ERROR: out_right expected=0 after reset, obtained=%0d", out_right);

        if (int_op_count == 0)
            $display("OK: int_op_count expected=0 after reset, obtained=%0d", int_op_count);
        else
            $display("ERROR: int_op_count expected=0 after reset, obtained=%0d", int_op_count);

        rst = 0;

        $display("TEST PE FINALIZADO");
        $finish;
    end
endmodule