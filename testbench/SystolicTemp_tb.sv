import SystolicTypes::*;

`timescale 1ns/1ps
`default_nettype none

module SystolicTemp_tb;

    parameter N = 4;
    parameter WIDTH = 16;
    localparam NN = N*N;

    // Señales
    logic clk, rst, new_data;
    logic unsigned [11:0] addr_A, addr_B, addr_C;
    logic unsigned [8:0] n;
    logic unsigned [11:0] act_addr;
    logic signed [WIDTH-1:0] matrix_C [N-1:0][N-1:0];
    logic [31:0] int_ops;
    logic [31:0] reads_count;
    logic [31:0] writes_count;
    logic unsigned [15:0] total_cycles;
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
    logic signed [WIDTH-1:0] expected_C_relu0 [NN-1:0]; // Resultados esperados sin ReLU
    logic signed [WIDTH-1:0] expected_C_relu1 [NN-1:0]; // Resultados esperados con ReLU

    // Buffers para capturar los valores leídos por el DUT
    logic signed [WIDTH-1:0] captured_A [NN-1:0];
    logic signed [WIDTH-1:0] captured_B [NN-1:0];
    int captured_A_count, captured_B_count;

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
        .act_addr(act_addr),
        .matrix_C(matrix_C),
        .int_ops(int_ops),
        .reads_count(reads_count),
        .writes_count(writes_count),
        .total_cycles(total_cycles),
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

    // Inicialización de memoria 
    initial begin
        // Matriz A: posiciones 0-15
        for (int i = 0; i < NN; i++) mem_A[i] = 0;
        // Matriz B: posiciones 16-31
        for (int i = 0; i < NN; i++) mem_B[i] = 0;
        // Inicializa C en cero
        for (int i = 0; i < NN; i++) mem_C[i] = 0;
    end

    // Captura los resultados escritos en memoria C
    always @(posedge clk) begin
        if (fsm_state == WRITEBACK) begin
            mem_C[act_addr - addr_C] <= mem_read;
        end
    end

    // Captura los valores leídos por el DUT para A y B
    always @(posedge clk) begin
        if (rst) begin
            captured_A_count <= 0;
            captured_B_count <= 0;
            for (int i = 0; i < NN; i++) begin
                captured_A[i] <= 0;
                captured_B[i] <= 0;
            end
        end else begin
            // Captura para matriz A solo en WAITING_MEMORY_A
            if (fsm_state == WAITING_MEMORY_A && act_addr >= addr_A && act_addr < addr_A + NN && captured_A_count < NN) begin
                captured_A[act_addr - addr_A] <= mem_read;
                captured_A_count <= captured_A_count + 1;
            end
            // Captura para matriz B solo en WAITING_MEMORY_B
            if (fsm_state == WAITING_MEMORY_B && act_addr >= addr_B && act_addr < addr_B + NN && captured_B_count < NN) begin
                captured_B[act_addr - addr_B] <= mem_read;
                captured_B_count <= captured_B_count + 1;
            end
        end
    end

     // Calcula el resultado esperado usando los valores capturados
    task calc_expected_no_relu;
        begin
            for (int i = 0; i < N; i++) begin
                for (int j = 0; j < N; j++) begin
                    expected_C_relu0[i*N + j] = 0;
                    for (int k = 0; k < N; k++) begin
                        expected_C_relu0[i*N + j] += captured_A[i*N + k] * captured_B[k*N + j];
                    end
                end
            end
        end
    endtask

    task calc_expected_with_relu;
        begin
            for (int i = 0; i < N; i++) begin
                for (int j = 0; j < N; j++) begin
                    expected_C_relu1[i*N + j] = 0;
                    for (int k = 0; k < N; k++) begin
                        expected_C_relu1[i*N + j] += captured_A[i*N + k] * captured_B[k*N + j];
                    end
                    // Aplica ReLU
                    if (expected_C_relu1[i*N + j] < 0)
                        expected_C_relu1[i*N + j] = 0;
                end
            end
        end
    endtask

    // Prueba 1: Multiplicación sin ReLU
    task test_no_relu;
        begin
            // Reset y setup
            rst = 1; new_data = 0; ReLU_activation = 0; stepping_enable = 0; step = 0;
            addr_A = 12'd0; addr_B = 12'd16; addr_C = 12'd32; n = N;
            #20; rst = 0; #10;
            new_data = 1; #10; new_data = 0;

            // Espera a que termine la operación (puedes ajustar el tiempo)
            wait (system_status == DONE_AND_WAITING);
            #20;

            // Calcula el resultado esperado usando los valores capturados
            calc_expected_no_relu();

            // Compara resultados
            $display("==== TEST 1: Multiplication without ReLU ====");
            for (int i = 0; i < NN; i++) begin
                if (mem_C[i] !== expected_C_relu0[i])
                    $error("ERROR: C[%0d]=%0d, expected=%0d", i, mem_C[i], expected_C_relu0[i]);
                else
                    $display("OK: C[%0d]=%0d, expected=%0d", i, mem_C[i], expected_C_relu0[i]);
            end
        end
    endtask

    // Prueba 2: Multiplicación con ReLU
    task test_with_relu;
        begin
            // Reset y setup
            rst = 1; new_data = 0; ReLU_activation = 1; stepping_enable = 0; step = 0;
            addr_A = 12'd0; addr_B = 12'd16; addr_C = 12'd32; n = N;
            // Limpia memoria C
            for (int i = 0; i < NN; i++) mem_C[i] = 0;
            #20; rst = 0; #10;
            new_data = 1; #10; new_data = 0;

            // Espera a que termine la operación
            wait (system_status == DONE_AND_WAITING);
            #20;

            // Calcula el resultado esperado usando los valores capturados
            calc_expected_with_relu();

            // Compara resultados
            $display("==== TEST 2: Multiplication with ReLU ====");
            for (int i = 0; i < NN; i++) begin
                if (mem_C[i] !== expected_C_relu1[i])
                    $error("ERROR: C[%0d]=%0d, expected=%0d", i, mem_C[i], expected_C_relu1[i]);
                else
                    $display("OK: C[%0d]=%0d, expected=%0d", i, mem_C[i], expected_C_relu1[i]);
            end
        end
    endtask

    // Secuencia de pruebas
    initial begin
        test_no_relu();
        test_with_relu();

        $display("==== PERFORMANCE COUNTERS ====");
        $display("total int operations = %0d", int_ops);
        $display("total memory reads   = %0d", reads_count);
        $display("total memory writes  = %0d", writes_count);

        if ((reads_count + writes_count) != 0)
            $display("Aritmetic Intensity = %f", real'(int_ops) / real'(reads_count * 2 + writes_count * 2));
        else
            $display("Aritmetic Intensity = undefined (division by zero)");

        $display("==== TESTBENCH FINISHED ====");
        $finish;
    end

endmodule