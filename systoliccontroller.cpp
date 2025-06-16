
#include <iostream>
#include <vector>
using namespace std;

enum class State {
    IDLE, 
    MEMORY,
    WAITING_MEMORY_A,
    WAITING_MEMORY_B,
    EXECUTE,
    WRITEBACK
};



class SystolicController {
    public:
        // Inputs
        int clk, n, addr_A, addr_B, addr_C, new_data;
        int result_col[4];

        // Outputs
        int weight_output[16];
        int data_up[4];

        // Variables privadas
        int matrix_A[4][4];
        int matrix_B[4][4];
        int matrix_C[4][4];

        int act_addr;
        int mem_read;
        int data_ready = 0;
        int cycle_count = 0;
        int icol0, icol1, icol2, icol3;

        // Variables para FSM
        State fsm_state = State::IDLE;

        // Para interacturar con la memoria
        int mem_write = 0; // Write enable
        int mem_data_write = 0; // Data to write


    void update() {
        // Cargar pesos (B) (assign)
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                weight_output[i * 4 + j] = matrix_B[j][i]; // Guardar en el output (transpuesta)
                
            }
        }

        switch (fsm_state) {
            case State::IDLE: 
                // Assign
                cout << "FSM: IDLE" << endl;
                mem_write = 0;
                fsm_state = (new_data == 1) ? State::MEMORY : fsm_state;
                break;
            case State::MEMORY:
                act_addr = addr_A;  // Direccion para obtener matriz A de memoria
                cout << "FSM: MEMORY, " << "act_addr: " << act_addr << endl;
                fsm_state = State::WAITING_MEMORY_A;
                break;
            case State::WAITING_MEMORY_A:
                // Esperar obtener datos de memoria
                // mem_read = memory.read(); -> mem_read
                cout << "FSM: WAITING_MEMORY_A, " << "act_addr: " << act_addr << ", mem_read: " << mem_read << endl;
                matrix_A[(act_addr - addr_A) / 4][(act_addr - addr_A) % 4] = mem_read;
                act_addr = (act_addr < addr_A + 16) ? act_addr + 1 : addr_B;  // Direccion para obtener matriz B de memoria
                fsm_state = (act_addr >= addr_A + 16) ? State::WAITING_MEMORY_B : State::WAITING_MEMORY_A;

                // IMPRIMIR la matriz A
                cout << "Matriz A: " << endl;
                for (int i = 0; i < 4; ++i) {
                    for (int j = 0; j < 4; ++j) {
                        cout << matrix_A[i][j] << " ";
                    }
                    cout << endl;
                }
                break;
            case State::WAITING_MEMORY_B:
                // Alistar para empezar a ejecutar
                // mem_read = memory.read(); -> mem_read
                cout << "FSM: WAITING_MEMORY_B, act_addr: " << act_addr << ", mem_read: " << mem_read << endl;
                matrix_B[(act_addr - addr_B) / 4][(act_addr - addr_B) % 4] = mem_read;
                act_addr = (act_addr < addr_B + 16) ? act_addr + 1 : addr_C;
                
                // data_ready = 1;      // Avisar al control unit para comenzar a operar
                cycle_count = 0; // Reiniciar el contador de ciclos

                // Asignar la matriz B de lo que sale de memoria
                fsm_state = (act_addr >= addr_B + 16) ? State::EXECUTE : State::WAITING_MEMORY_B;

                // IMPRIMIR la matriz B
                cout << "Matriz B: " << endl;
                for (int i = 0; i < 4; ++i) {
                    for (int j = 0; j < 4; ++j) {
                        cout << matrix_B[i][j] << " ";
                    }
                    cout << endl;
                }
                break;
            case State::EXECUTE:
                // Estos son assigns que van controlados con data_ready
                cout << "FSM: EXECUTE" << endl;
                
                

                // Cargar datos de entrada (A)
                icol0 = (cycle_count < n) ? cycle_count : 0xFF;
                icol1 = (cycle_count - 1 < n && cycle_count - 1 >= 0) ? cycle_count - 1 : 0xFF;
                icol2 = (cycle_count - 2 < n && cycle_count - 2 >= 0) ? cycle_count - 2 : 0xFF;
                icol3 = (cycle_count - 3 < n && cycle_count - 3 >= 0) ? cycle_count - 3 : 0xFF;

                data_up[0] = (icol0 != 0xFF) ? matrix_A[icol0][0] : 0;
                data_up[1] = (icol1 != 0xFF) ? matrix_A[icol1][1] : 0;
                data_up[2] = (icol2 != 0xFF) ? matrix_A[icol2][2] : 0;
                data_up[3] = (icol3 != 0xFF) ? matrix_A[icol3][3] : 0;

                // Imprimir los datos de entrada
                cout << "Data Up: ";
                for (int i = 0; i < 4; ++i) {
                    cout << data_up[i] << " ";
                }
                cout << endl;

                

                // Guardar los datos en los registros privados de la matriz C
                if (cycle_count > 4) {
                    cout << "Saving results to matrix_C" << endl;
                    for (int j = 0; j < 4; ++j) {
                        matrix_C[(cycle_count - 1) % 4][j] = result_col[j]; // Guardar el resultado en la matriz C
                        cout << matrix_C[(cycle_count - 1) % 4][j] << " ";
                    }
                    cout << endl;
                }

                if (cycle_count >= n * 2) {
                    fsm_state = State::WRITEBACK; // Cambiar al estado de escritura
                    mem_write = 1;
                    cycle_count = 0; // Reiniciar el contador de ciclos
                    act_addr = addr_C; // Direccion para escribir la matriz C
                    mem_data_write = matrix_C[0][0]; // Obtener el dato a escribir (inicialmente el primer elemento de la matriz C)
                    
                    // Imprimir la matriz C
                    cout << "Matriz C: " << endl;
                    for (int i = 0; i < 4; ++i) {
                        for (int j = 0; j < 4; ++j) {
                            cout << matrix_C[i][j] << " ";
                        }
                        cout << endl;
                    }

                }

                // Incrementar el contador de ciclos
                cycle_count++;

                break;
            case State::WRITEBACK:
                cout << "FSM: WRITEBACK" << endl;

                // Escribir la matriz C en memoria
                // memory.write();
                // Pasar a IDLE
                mem_data_write = matrix_C[cycle_count / 4][cycle_count % 4]; // Obtener el dato a escribir
                act_addr = addr_C + cycle_count;  // Direccion para obtener matriz B de memoria
                
                if (cycle_count >= 16) {
                    fsm_state = State::IDLE; 
                    mem_write = 0;
                }

                cycle_count++;
                break;

        }
    }

    void load_A(const int src[4][4]) {
        for(int i=0; i<4; ++i)
            for(int j=0; j<4; ++j)
                matrix_A[i][j] = src[i][j];
    }

    void load_B(const int src[4][4]) {
        for(int i=0; i<4; ++i)
            for(int j=0; j<4; ++j)
                matrix_B[i][j] = src[i][j];
    }
};

/*
// Probar la unidad
int main() {
    SystolicController controller;

    // Inicializar el controlador
    controller.clk = 0;
    controller.n = 4; // Tamaño de la matriz
    controller.addr_A = 16; // Direccion de la matriz A
    controller.addr_B = 32; // Direccion de la matriz B
    controller.addr_C = 48; // Direccion de la matriz C
    controller.new_data = 1; // Indicar que hay nuevos datos

    // Simular el ciclo de reloj
    for (int i = 0; i < 20; ++i) {
        controller.update();
        controller.new_data = 0; 
        //controller.clk++;
    }

    return 0;
}
    */