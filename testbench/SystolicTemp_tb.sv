import SystolicTypes::*;

`timescale 1ns/1ps

module SystolicTemp_tb;

    parameter N = 4;
    parameter WIDTH = 16;
    localparam NN = N*N;

    // Señales
    logic clk, rst, new_data;
    logic signed [WIDTH-1:0] mem_read;
    logic [11:0] addr_A, addr_B, addr_C;
    logic unsigned [3:0] n;
	 logic signed [WIDTH-1:0] result_col [N - 1:0];
    logic mem_write;
	 logic unsigned [7:0] cycle_count;
    logic signed [WIDTH-1:0] mem_data_write;
    logic unsigned [11:0] act_addr;
    logic signed [WIDTH-1:0] weight_output [N - 1:0][N - 1:0];
    logic signed [WIDTH-1:0] data_up [N - 1:0];
    state_t fsm_state;

    // Memorias de prueba
    logic signed [WIDTH-1:0] mem_A [NN - 1:0];
    logic signed [WIDTH-1:0] mem_B [NN - 1:0];
    logic signed [WIDTH-1:0] mem_C [NN - 1:0];

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
        .mem_write(mem_write),
        .mem_data_write(mem_data_write),
        .act_addr(act_addr),
        .weight_output(weight_output),
        .data_up(data_up),
        .result_col(result_col),
        .fsm_state(fsm_state),
		  .cycle_count(cycle_count)
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
        mem_read = 0;
        addr_A = 12'd0;
        addr_B = 12'd16;
        addr_C = 12'd32;
        n = N;

        // Inicializa matrices A y B con valores conocidos
        for (int i = 0; i < NN; i++) begin
            mem_A[i] = i + 1;         // Matriz A: 1,2,3,...
            mem_B[i] = (i + 1) * 2;   // Matriz B: 2,4,6,...
        end

        // Quita reset y lanza operación
        #12;
        rst = 0;
        #10;
        new_data = 1;
        #10;
        new_data = 0;
		  
		  #1000;
        for (int i = 0; i <= 50; i++) begin
            act_addr = i;
            #2; // Espera breve para simular acceso secuencial
        end

        $display("Resultados finales en memoria C:");
        for (int i = 0; i < NN; i++) begin
            $display("C[%0d]=%0d", i, mem_C[i]);
        end
		  
		  // Segunda operacion
		  addr_A = 12'd16;
        addr_B = 12'd32;
        addr_C = 12'd48;
		  #10;
        new_data = 1;
        #10;
        new_data = 0;
		  
		  #1000;
        for (int i = 0; i <= 50; i++) begin
            act_addr = i;
            #2; // Espera breve para simular acceso secuencial
        end

        $display("Resultados finales en memoria C:");
        for (int i = 0; i < NN; i++) begin
            $display("C[%0d]=%0d", i, mem_C[i]);
        end
		  
		  
        $finish;
    end

    // Simulación de memoria y captura de resultados
    always @(negedge clk) begin
        // Simula lectura de memoria para A
        if (fsm_state == WAITING_MEMORY_A) begin
            // mem_read <= mem_A[act_addr - addr_A];
            // $display("Leyendo A[%0d]=%0d", act_addr - addr_A, mem_A[act_addr - addr_A]);
				$display("1 - Leyendo Mem[%0d]=%0d", act_addr, mem_read);
        end
        // Simula lectura de memoria para B
        else if (fsm_state == WAITING_MEMORY_B) begin
            // mem_read <= mem_B[act_addr - addr_B];
            // $display("Leyendo B[%0d]=%0d", act_addr - addr_B, mem_B[act_addr - addr_B]);
				$display("2 - Leyendo Mem[%0d]=%0d", act_addr, mem_read);
        end
        else if (fsm_state == EXECUTE) begin
            // Captura los resultados de los PEs
            for (int i = 0; i < N; i++) begin
                $display("PE[%0d] resultado: %0d", i, result_col[i]);
            end
        end
        // Captura los resultados escritos en memoria C
        else if (fsm_state == WRITEBACK) begin
            mem_C[act_addr - addr_C] <= mem_data_write;
            $display("WRITEBACK: C[%0d]=%0d", act_addr - addr_C, mem_data_write);
        end
    end


endmodule