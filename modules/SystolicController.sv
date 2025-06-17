
import SystolicTypes::*;

`timescale 1ns/1ps

module SystolicController #(parameter N = 4, parameter int WIDTH = 16) (
    // Inputs
    input logic clk, rst, new_data,
    input logic signed [WIDTH - 1:0] mem_read,
	 input logic signed [WIDTH - 1:0] result_col [N - 1:0],
    input logic [11:0] addr_A, addr_B, addr_C, 
    input logic [3:0] n,

    // Outputs
    output logic mem_write,
    output logic signed [WIDTH - 1:0] mem_data_write,
    output logic [11:0] act_addr,
    output logic signed [WIDTH - 1:0] weight_output [N - 1:0][N - 1:0],
    output logic signed [WIDTH - 1:0] data_up [N - 1:0],

    // Temporales
    output state_t fsm_state
);


    state_t fsm_state_next;

    // Registros privados
    logic [WIDTH - 1:0] matrix_A [N - 1:0][N - 1:0];
    logic [WIDTH - 1:0] matrix_B [N - 1:0][N - 1:0];
    logic [WIDTH - 1:0] matrix_C [N - 1:0][N - 1:0];

    // Flip-flops
    logic [7:0] cycle_count, cycle_count_next;
    logic [7:0] act_addr_next;
    logic [7:0] mem_data_write_next;
    logic       mem_write_next;

    // Maquina de estados parte secuencial 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state      <= IDLE;
            cycle_count    <= 0;
            act_addr       <= 0;
            mem_write      <= 0;
            mem_data_write <= 0;
        end else begin
            fsm_state      <= fsm_state_next;
            cycle_count    <= cycle_count_next;
            act_addr       <= act_addr_next;
            mem_write      <= mem_write_next;
            mem_data_write <= mem_data_write_next;
        end
    end

    // Maquina de estados parte combinacional
    always_comb begin
        fsm_state_next      = fsm_state;
        cycle_count_next    = cycle_count;
        act_addr_next       = act_addr;
        mem_write_next      = mem_write;
        mem_data_write_next = mem_data_write;

        // Default outputs
        for (int i = 0; i < N; i++) begin
            data_up[i] = 0;
        end
		  
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                weight_output[i][j] = 0;
            end
        end

        // Asignar los pesos siempre
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                weight_output[i][j] = matrix_B[j][i];
            end
        end

        // Estados de la FSM
        case (fsm_state)
            IDLE: begin
                // Esperando nueva operacion
                mem_write_next = 0;
                if (new_data) fsm_state_next = MEMORY;
            end
            MEMORY: begin
                // Empezar obteniendo los datos de memoria de la primera matriz
                act_addr_next = addr_A;
                fsm_state_next = WAITING_MEMORY_A;
					 matrix_A[(act_addr-addr_A) / N][(act_addr-addr_A) % N] = mem_read;
            end
            WAITING_MEMORY_A: begin
                // Guardar el dato leido de memoria y guardarlo en la matriz A
                matrix_A[(act_addr-addr_A) / N][(act_addr-addr_A) % N] = mem_read;
                if (act_addr < addr_A + N*N - 1)
                    act_addr_next = act_addr + 1;
                else begin
                    // Cuando se termina de guardar, pasa ahora a la matriz B
                    act_addr_next = addr_B;
                    fsm_state_next = WAITING_MEMORY_B;
                end
            end
            WAITING_MEMORY_B: begin
                 matrix_B[(act_addr-addr_B) / N][(act_addr-addr_B) % N] = mem_read;
                 if (act_addr < addr_B + N*N - 1)
                    act_addr_next = act_addr + 1;
                else begin
                    // Cuando se termina de guardar, se elige ahora la matriz C para la operacion
                    act_addr_next = addr_C;
                    cycle_count_next = 0;       // Se pone el contador de ciclos en 0        
                    fsm_state_next = EXECUTE;   // Se pasa a la ejecucion de los PEs\
						  data_up[0] = 1;
                end
            end
            EXECUTE: begin
                // Cargar datos de entrada por la parte de arriba de los PEs (A)
                data_up[0] = 1;
                data_up[1] = ((cycle_count - 1 < n) && (cycle_count - 1 >= 0)) ? matrix_A[cycle_count - 1][1] : 0;
                data_up[2] = ((cycle_count - 2 < n) && (cycle_count - 2 >= 0)) ? matrix_A[cycle_count - 2][2] : 0;
                data_up[3] = ((cycle_count - 3 < n) && (cycle_count - 3 >= 0)) ? matrix_A[cycle_count - 3][3] : 0;
                
                // Guardar resultados en C cuando salgan los primeros resultados
                if (cycle_count > 4) begin
                    for (int j = 0; j < N; j++)
                        matrix_C[(cycle_count - 1) % N][j] = result_col[j];
                end

                // Se termina el execute cuando se lleva a la cantidad de ciclos
                if (cycle_count == n*2) begin
                    fsm_state_next = WRITEBACK;
                    mem_write_next = 1;         // Para escribir en memoria en el siguiente 
                    cycle_count_next = 0;
                    act_addr_next = addr_C;     // Direccion de la escritura
                    mem_data_write_next = matrix_C[0][0];
                end else begin
                    cycle_count_next = cycle_count + 1;
                end
            end
            WRITEBACK: begin
                // Guardar el resultado en memoria
                mem_data_write_next = matrix_C[cycle_count / N][cycle_count % N];
                act_addr_next = addr_C + cycle_count;
                
                // Caso de parada
                if (cycle_count >= N*N - 1) begin
                    fsm_state_next = IDLE;
                    mem_write_next = 0;
                end else begin
                    cycle_count_next = cycle_count + 1;
                end
            end
        endcase

    end

    // Asignar directamente la transpuesta de matrix_B a weight_output
    



endmodule