import SystolicTypes::*;

`timescale 1ns/1ps
`default_nettype none

module FPGA_Controller_tb;

    parameter WIDTH = 16;
    parameter N = 4;

    // Señales
    logic clk, rst, start;
    logic stepping_enable, step;
    logic ReLU_activation;
    logic right, left, switch_mem_access;
    logic signed [WIDTH-1:0] mem_read;
    logic unsigned [11:0] addr_FPGA;

    // Instancia del DUT
    FPGA_Controller #(.WIDTH(WIDTH), .N(N)) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .stepping_enable(stepping_enable),
        .step(step),
        .ReLU_activation(ReLU_activation),
        .right(right),
        .left(left),
        .switch_mem_access(switch_mem_access),
        .mem_read(mem_read),
        .addr_FPGA(addr_FPGA)
    );

    // Generador de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Inicialización y estímulos
    initial begin
        rst = 1;
        start = 0;
        stepping_enable = 0;
        step = 0;
        ReLU_activation = 0;
        right = 0;
        left = 0;
        switch_mem_access = 0;
        mem_read = 0;

        #20;
        rst = 0;

        // Simula navegación de memoria con botones
        #20;
        right = 1;
        #10;
        right = 0;
        #10;
        right = 1;
        #10;
        right = 0;
        #10;
        right = 1;
        #10;
        right = 0;
        #10;
        left = 1;
        #10;
        left = 0;

        // Cambia acceso a memoria
        #20;
        switch_mem_access = 1;
        #10;
        switch_mem_access = 0;

        // Simula stepping
        #20;
        stepping_enable = 1;
        repeat (5) begin
            step = 1;
            #10;
            step = 0;
            #20;
        end
        stepping_enable = 0;

        #100;
        $display("Dirección actual FPGA: %0d", addr_FPGA);
        $finish;
    end

endmodule