
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
	 output logic [7:0] cycle_count,
     output logic enable [N],

    // Para control, en implementacion ----------
    output state_t fsm_state,
    output state_t fsm_state_next,
    output state_t fsm_state_next_stepping,
    output state_t fsm_state_next_stepping_next,

    // En implementacion ------------
    // Stepping
    input logic stepping_enable, step,

    // Para indicar que se ha terminado una operacion
    output logic done, // No se usa en este modulo, pero se puede usar en el controlador

    // Contador de ciclos total
    output logic [15:0] total_cycles, // Contador de ciclos total

    // Overflow detectado
    input logic overflow_in, // Overflow detectado por los PEs
    output logic overflow_out
);


    //state_t fsm_state_next;
    //state_t fsm_state_next_stepping;

    // Registros privados
    logic [WIDTH - 1:0] matrix_A [N - 1:0][N - 1:0];
    logic [WIDTH - 1:0] matrix_B [N - 1:0][N - 1:0];
    logic [WIDTH - 1:0] matrix_C [N - 1:0][N - 1:0];

    // Flip-flops
    logic [7:0] cycle_count_next;

    logic [11:0] act_addr_next;
    logic [WIDTH - 1:0] mem_data_write_next;
    logic       mem_write_next;
	 logic signed [WIDTH - 1:0] data_up_next [N - 1:0];
     logic enable_next [N];
     logic done_next;
     logic overflow_next;
     logic [15:0] total_cycles_next;
    // Maquina de estados parte secuencial 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state      <= IDLE;
            cycle_count    <= 0;
            act_addr       <= 0;
            mem_write      <= 0;
            mem_data_write <= 0;
            done           <= 0;
            total_cycles <= 0;
            overflow_out <= 0;
            for (int i = 0; i < N; i++) begin
                data_up[i] <= 0;
                enable[i] <= 0;
            end
            
        end else begin
             fsm_state      <= fsm_state_next;
             fsm_state_next_stepping <= fsm_state_next_stepping_next;
            // Stepping control
            // fsm_state <= (fsm_state == WAITING_STEP && step) ? fsm_state_next_stepping : 
            //              (!stepping_enable) ? fsm_state_next : 
            //              fsm_state;

            cycle_count    <= cycle_count_next;
            act_addr       <= act_addr_next;
            mem_write      <= mem_write_next;
            mem_data_write <= mem_data_write_next;
            done           <= done_next;
            total_cycles <= total_cycles_next;
            overflow_out <= overflow_next;
            for (int i = 0; i < N; i++) begin
                data_up[i] <= data_up_next[i];
                enable[i] <= enable_next[i];
            end
				
        end
    end

    // Maquina de estados parte combinacional
    always_comb begin
        fsm_state_next      = fsm_state;
        cycle_count_next    = cycle_count;
        act_addr_next       = act_addr;
        mem_write_next      = mem_write;
        mem_data_write_next = mem_data_write;
        done_next           = done;
        fsm_state_next_stepping_next = fsm_state_next_stepping;
        total_cycles_next = total_cycles;
        overflow_next = overflow_in;
        
        for (int i = 0; i < N; i++) begin
            data_up_next[i] = data_up[i];
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
					 
                if (new_data) begin 
                    done_next = 0; // No se ha terminado la operacion
						  total_cycles_next = 0;
                    //overflow_next = 0; // Reiniciar overflow
								  
						 if (stepping_enable) begin
                        fsm_state_next = WAITING_STEP; // Esperando el paso de stepping
                        fsm_state_next_stepping_next = MEMORY; // Estado al que se va a ir cuando se de el
                    end else 
                        fsm_state_next = MEMORY;
                    //fsm_state_next = MEMORY;
                end else begin
                    fsm_state_next = IDLE; // Mantener en IDLE si no hay nueva operacion
                end
            end
            MEMORY: begin
                // Empezar obteniendo los datos de memoria de la primera matriz
                total_cycles_next = total_cycles + 1; // Incrementar el contador de ciclos
                act_addr_next = addr_A;
                
                //fsm_state_next = WAITING_MEMORY_A;
			    matrix_A[(act_addr - addr_A) / N][(act_addr-addr_A) % N] = mem_read;

                if (stepping_enable) begin
                    fsm_state_next = WAITING_STEP; // Esperando el paso de stepping
                    fsm_state_next_stepping_next = WAITING_MEMORY_A; // Estado al que se va a ir cuando se de el paso
                end else begin
                    fsm_state_next = WAITING_MEMORY_A; // Estado al que se va a ir cuando se de el paso
                end
            end
            WAITING_MEMORY_A: begin
                // Guardar el dato leido de memoria y guardarlo en la matriz A
                total_cycles_next = total_cycles + 1; // Incrementar el contador de ciclos
                matrix_A[(act_addr - addr_A) / N][(act_addr - addr_A) % N] = mem_read;
					 for (int i = 0; i < N; i++) begin
							data_up_next[i] = 0;
							enable_next[i] = 1;
					 end 
                if (act_addr < addr_A + N*N - 1)
                    act_addr_next = act_addr + 1;
                else begin
                    // Cuando se termina de guardar, pasa ahora a la matriz B
                    act_addr_next = addr_B;
                    // fsm_state_next = WAITING_MEMORY_B;

                    if (stepping_enable) begin
                        fsm_state_next = WAITING_STEP; // Esperando el paso de stepping
                        fsm_state_next_stepping_next = WAITING_MEMORY_B; // Estado al que se va a ir cuando se de el paso
                    end else begin
                        fsm_state_next = WAITING_MEMORY_B; // Estado al que se va a ir cuando se de el paso
                    end
                end
            end
            WAITING_MEMORY_B: begin
                total_cycles_next = total_cycles + 1; // Incrementar el contador de ciclos
                 matrix_B[(act_addr-addr_B) / N][(act_addr-addr_B) % N] = mem_read;
                 if (act_addr < addr_B + N*N - 1)
                    act_addr_next = act_addr + 1;
                else begin
                    // Cuando se termina de guardar, se elige ahora la matriz C para el writeback al final
                    act_addr_next = addr_C;
                    cycle_count_next = 0;       // Se pone el contador de ciclos en 0        
                    fsm_state_next = EXECUTE;   // Se pasa a la ejecucion de los PEs\
					data_up_next[0] = matrix_A[0][0];
                    if (stepping_enable) begin
                        fsm_state_next = WAITING_STEP; // Esperando el paso de stepping
                        fsm_state_next_stepping_next = EXECUTE; // Estado al que se va a ir cuando se de el paso
                    end else begin
                        fsm_state_next = EXECUTE; // Estado al que se va a ir cuando se de el paso
                    end
                end

                
            end
            EXECUTE: begin
                total_cycles_next = total_cycles + 1; // Incrementar el contador de ciclos
                // Cargar datos de entrada por la parte de arriba de los PEs (A)	 
					 for (int i = 0; i < N; i++) begin
                        if ((cycle_count - i < n) && (cycle_count - i >= 0)) begin
                            data_up_next[i] = matrix_A[cycle_count - i][i];
                            enable_next[i] = 1;
                        end
                        else begin
                            data_up_next[i] = 0;
                            enable_next[i] = 0;
                        end
					 end          

                // Guardar resultados en C cuando salgan los primeros resultados
                if (cycle_count > 4) begin
                    for (int j = 0; j < N; j++)
                        matrix_C[(cycle_count - 1) % N][j] = result_col[j];
                end

                if (overflow_in) begin
                    overflow_next = 1; // Si hay overflow, se marca
                end else begin
                    overflow_next = overflow_next; 
                end

                // Se termina el execute cuando se lleva a la cantidad de ciclos
                if (cycle_count == n*2) begin
                    //fsm_state_next = WRITEBACK;
                    mem_write_next = 1;         // Para escribir en memoria en el siguiente 
                    cycle_count_next = 0;
                    act_addr_next = addr_C;     // Direccion de la escritura
                    mem_data_write_next = matrix_C[0][0];

                    if (stepping_enable) begin
                        fsm_state_next = WAITING_STEP; // Esperando el paso de stepping
                        fsm_state_next_stepping_next = WRITEBACK; // Estado al que se va a ir cuando se de el paso
                    end else begin
                        fsm_state_next = WRITEBACK; // Estado al que se va a ir cuando se de el paso
                    end
                end else begin
                    cycle_count_next = cycle_count + 1;
                end
            end
            WRITEBACK: begin
                total_cycles_next = total_cycles + 1; // Incrementar el contador de ciclos
                // Guardar el resultado en memoria
                mem_data_write_next = matrix_C[cycle_count / N][cycle_count % N];
                act_addr_next = addr_C + cycle_count;
                
                // Caso de parada
                if (cycle_count >= N*N) begin
                    fsm_state_next = IDLE;
                    mem_write_next = 0;
                    cycle_count_next = 0;
                    act_addr_next = 0;
                    mem_data_write_next = 0;
                    for (int i = 0; i < N; i++) begin
                        data_up_next[i] = 0;
                    end

                    done_next = 1; // Se ha terminado la operacion
                    if (stepping_enable) begin
                        fsm_state_next_stepping_next = IDLE; // Estado al que se va a ir cuando se de el paso
                        fsm_state_next = WAITING_STEP; // Esperando el paso de stepping
                    end else begin
                        fsm_state_next = IDLE; // Estado al que se va a ir cuando se de el paso
                    end
                end else begin
                    cycle_count_next = cycle_count + 1;
                end
            end
            WAITING_STEP: begin
                // Esperando el paso de stepping
                if (step) begin
                    // Si se da el paso, se va al siguiente estado
                    fsm_state_next = fsm_state_next_stepping;
                end else begin
                    // Si no se da el paso, se mantiene en WAITING_STEP
                    fsm_state_next = WAITING_STEP;
                end
            end
        endcase

    end

    // Asignar directamente la transpuesta de matrix_B a weight_output
    



endmodule