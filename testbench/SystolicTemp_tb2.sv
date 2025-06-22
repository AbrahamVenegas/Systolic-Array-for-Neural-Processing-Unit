import SystolicTypes::*;

`timescale 1ns/1ps
`default_nettype none

module SystolicTemp_tb2;

    parameter N = 4;
    parameter WIDTH = 16;
    localparam NN = N*N;

    // Señales
    logic clk, rst, new_data;
    logic unsigned [11:0] addr_A, addr_B, addr_C;
    logic unsigned [8:0] n;
    //logic mem_write;
    //logic signed [WIDTH-1:0] mem_data_write;
    logic unsigned [11:0] act_addr;
    logic signed [WIDTH-1:0] matrix_C [N-1:0][N-1:0];
    logic [31:0] int_ops;
    logic [31:0] reads_count;
    logic [31:0] writes_count;
    logic unsigned [15:0] total_cycles;
    //logic overflow_out;
    logic stepping_enable, step;
    logic ReLU_activation;
    logic signed [WIDTH-1:0] mem_read;

    // Estados y status
    state_t fsm_state, fsm_state_next_stepping;
    system_status_t system_status;
    memory_status_t memory_status;
    error_code_t error_code;

    // Memorias de prueba
    logic signed [WIDTH-1:0] mem_A [NN-1:0];
    logic signed [WIDTH-1:0] mem_B [NN-1:0];
    logic signed [WIDTH-1:0] mem_C [NN-1:0];

    // Para el testbench
    logic signed [WIDTH-1:0] expected_C [NN-1:0]; // Resultados esperados

    // Instancia del DUT
    SystolicTemp #(.N(N), .WIDTH(WIDTH)) uut (
        .clk(clk),
        .rst(rst),
        .new_data(new_data),
        .mem_read(mem_read),
        .addr_A(addr_A),
        .addr_B(addr_B),
        .addr_C(addr_C),
        .n(n),
        //.mem_write(mem_write),
        //.mem_data_write(mem_data_write),
        .act_addr(act_addr),
        .matrix_C(matrix_C),
        .int_ops(int_ops),
        .reads_count(reads_count),
        .writes_count(writes_count),
        .total_cycles(total_cycles),
        //.overflow_out(overflow_out),
        .stepping_enable(stepping_enable),
        .step(step),
        .fsm_state(fsm_state),
        .fsm_state_next_stepping(fsm_state_next_stepping),
        .ReLU_activation(ReLU_activation),
        .system_status(system_status),
        .memory_status(memory_status),
        .error_code(error_code)
    );

    // Generador de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Inicialización y estímulos
    initial begin
        rst = 1;
        new_data = 0;
        addr_A = 12'd0;
        addr_B = 12'd16;
        addr_C = 12'd32;
        n = N;
        ReLU_activation = 1;
        stepping_enable = 0;
        step = 0;

        #10;
        rst = 0;
        #10;
        new_data = 1;
        #10;
        new_data = 0;

        // Simula pasos de reloj si usas stepping
        for (int i = 0; i < 50; i++) begin
            step = 1;
            #10;
            step = 0;
            #20;
        end

        // Realizar la multiplicación de matrices de forma manual entre A y B y guardar en expected_C
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                expected_C[i*N + j] = 0;
                for (int k = 0; k < N; k++) begin
                    expected_C[i*N + j] += mem_A[i*N + k] * mem_B[k*N + j];
                end
            end
        end
        

        $display("Resultados finales en memoria C:");
        for (int i = 0; i < NN; i++) begin
            $display("C[%0d]=%0d, Expected_C[%0d]=%0d", i, mem_C[i], i, expected_C[i]);
        end

        $finish;
    end

    // Simulación de memoria y captura de resultados
    always @(posedge clk) begin
        // Simula lectura de memoria para A
        if (fsm_state == WAITING_MEMORY_A) begin
				mem_A[act_addr - addr_A] <= mem_read;
            $display("Leyendo A[%0d]=%0d", act_addr - addr_A, mem_read);
        end
        // Simula lectura de memoria para B
        else if (fsm_state == WAITING_MEMORY_B) begin
				mem_B[act_addr - addr_B] <= mem_read;
            $display("Leyendo B[%0d]=%0d", act_addr - addr_B, mem_read);
        end
        // Captura los resultados escritos en memoria C
        else if (fsm_state == WRITEBACK) begin
				mem_C[act_addr - addr_C] <= mem_read;
            $display("WRITEBACK: C[%0d]=%0d", act_addr - addr_C, mem_read);
        end
    end

endmodule