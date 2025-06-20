
#include "pe.h"
#include "systoliccontroller.cpp"
#include "memory.cpp"
#include <vector>
#include <iostream>
using namespace std;

int main () {
    // Crear una matriz de PEs
    const int size = 4;

    // Arreglo de PEs 4x4
    vector<vector<PE>> pe_array(size, vector<PE>(size, PE(nullptr, nullptr)));

    // Inicializar los PEs y establecer las conexiones
    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            if (i < size - 1) {
                pe_array[i][j].down = &pe_array[i + 1][j];
            }
            if (j < size - 1) {
                pe_array[i][j].right = &pe_array[i][j + 1];
            }
        }
    }

    // Unidad de memoria
    Memory memoryy;
    memoryy.addr = 0; // Direccion de memoria
    memoryy.data = 0; // Datos a escribir

    // Llenar la memoria con datos de ejemplo
    // Cargar matrices de ejemplo
    vector<vector<int>> matrix_A = {{1, 2, 3, 4},
                            {1, 6, 7, 8}, 
                            {2, 1, 11, 12}, 
                            {3, 14, 15, 16}};

    vector<vector<int>> matrix_B = {{1, 2, 3, 4},
                            {1, 3, 5, 7}, 
                            {2, 8, 9, 3}, 
                            {3, 2, 7, 9}};

    
    // Guardar las matrices en la memoria
    for (int i = 0; i < 16; ++i) {
        memoryy.memory[i] = matrix_A[i / 4][i % 4]; // Guardar matriz A
    }
    
    int j;
    for (int i = 0; i < 16; ++i) {
        j = i + 16; // Offset para la matriz B
        memoryy.memory[j] = matrix_B[i / 4][i % 4]; // Guardar matriz A
    }
        



    // Unidad de control del arreglo sistolico
    SystolicController controller;
    controller.n = size; // Tamaño de la matriz
    controller.addr_A = 0; // Direccion de la matriz A
    controller.addr_B = 16; // Direccion de la matriz B
    controller.addr_C = 32; // Direccion de la matriz C

      
    controller.new_data = 1; // Indicar que hay nuevos datos para procesar

    // Actualizar el controlador (funcion del clk)
    for (int i = 0; i < 60; ++i) {
        // Enviar la info a los PEs
        // Los pesos quedaran asignados en los PEs (assign dentro del controlador)
        for (int i2 = 0; i2 < size; ++i2) {
            for (int j2 = 0; j2 < size; ++j2) {
                pe_array[i2][j2].weight = controller.weight_output[i2 * size + j2];
            }
        }

        // Memoria
        memoryy.addr = controller.act_addr; // Direccion de memoria
        memoryy.wren = controller.mem_write; // Habilitar escritura si es necesario
        memoryy.data = controller.mem_data_write; // Datos a escribir en memoria
        memoryy.update();

        controller.mem_read = memoryy.q;
        controller.update(); // Actualizar el controlador
        

        

        // Enviar los datos de entrada a los PEs (assign)
        for (int j = 0; j < size; ++j) {
            pe_array[0][j].temp_up = controller.data_up[j];
        }

        // Actualizar cada PE
        for (int i2 = 0; i2 < size; ++i2) {
            for (int j2 = 0; j2 < size; ++j2) {
                pe_array[i2][j2].update(); // Actualizar cada PE
            }
        }

        // Enviar los resultados de los PEs al controlador
        for (int j = 0; j < size; ++j) {
            controller.result_col[j] = pe_array[j][3].calc; // Guardar el resultado en el controlador
        }

        controller.new_data = 0;
        
    }

    for (int i = 0; i < 50; ++i) {
        if (i % 4 == 0 && i != 0) {
            cout << endl; // Nueva linea cada 16 elementos
        } 
        cout << memoryy.memory[i] << ", "; // Imprimir la memoria
    }
    cout << endl;

    return 1;
    

}