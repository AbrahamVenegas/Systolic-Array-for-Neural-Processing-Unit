import SystolicTypes::*;

`timescale 1ns/1ps
`default_nettype none

module SystolicTemp_tb;

    parameter N = 4;
    parameter WIDTH = 16;
    localparam NN = N*N;

    // Señales
    logic clk, rst, new_data;
    logic signed [WIDTH-1:0] mem_read;
    logic unsigned [11:0] addr_A, addr_B, addr_C;
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

    // outputs performance counters
    logic [31:0] int_ops;
    logic enable [4];

    // Para control, en implementacion ----------
    // state_t fsm_state;
    state_t fsm_state_next;
    state_t fsm_state_next_stepping;
    logic stepping_enable, step;
	 state_t fsm_state_next_stepping_next;
	 
	 logic done; 
    logic unsigned [15:0] total_cycles; 
	 
	 logic overflow_out;
	 
	 

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
		  .cycle_count(cycle_count),
          .int_ops(int_ops),
          .enable_out(enable),
			 
          .stepping_enable(stepping_enable),
        .step(step),
        .fsm_state_next(fsm_state_next),
        .fsm_state_next_stepping(fsm_state_next_stepping),
		  .fsm_state_next_stepping_next(fsm_state_next_stepping_next),
		  .done(done),
		  .total_cycles(total_cycles),
		  .overflow_out(overflow_out)
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

        // Probar stepping
        stepping_enable = 0; // Habilita el modo stepping

        // Quita reset y lanza operación
        #12;
        rst = 0;
        #10;
        new_data = 1;
        #10;
        new_data = 0;
		  
	    #10;
        for (int i = 0; i <= 50; i++) begin
            //act_addr = i;
            step = 1; // Simula un paso de reloj
            #10;
            step = 0; // Termina el paso de reloj
            #300; // Espera breve para simular acceso secuencial
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

        $display("Resultados finales en memoria C:");
        for (int i = 0; i < NN; i++) begin
            $display("C[%0d]=%0d", i, mem_C[i]);
        end
		  
		  #10;
        new_data = 1;
		  #1000;
		  
		  
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