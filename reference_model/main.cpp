
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
    int n = 8;
    vector<vector<int>> matrix_A(n, vector<int>(n));
    vector<vector<int>> matrix_B(n, vector<int>(n));

    // Llenar matrix_A con valores de ejemplo (1, 2, ..., 256)
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            matrix_A[i][j] = i * n + j + 1;
        }
    }

    // Llenar matrix_B con valores de ejemplo (2, 4, ..., 512)
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            matrix_B[i][j] = 2 * (i * n + j + 1);
        }
    }

    cout << "Cargando matrices A y B en la memoria..." << endl;
    // Guardar las matrices en la memoria
    for (int i = 0; i < n * n; ++i) {
        memoryy.memory[i] = matrix_A[i / n][i % n]; // Guardar matriz A
    }
    
    int j;
    for (int i = 0; i < n * n; ++i) {
        // Cuidado
        j = i + (n * n); // Offset para la matriz B
        memoryy.memory[j] = matrix_B[i / n][i % n]; // Guardar matriz B
    }
        



    // Unidad de control del arreglo sistolico
    SystolicController controller;
    controller.n = n; // Tamaño de la matriz
    controller.addr_A = 0; // Direccion de la matriz A
    controller.addr_B = n * n; // Direccion de la matriz B
    controller.addr_C = n * n * 2; // Direccion de la matriz C

      
    controller.new_data = 1; // Indicar que hay nuevos datos para procesar
    cout << "Cargando matrices A y B en el controlador..." << endl;

    // Actualizar el controlador (funcion del clk)
    for (int i = 0; i < 3000; ++i) {
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

        if (memoryy.wren == 1) {
            cout << "Escribiendo en memoria en la direccion " << memoryy.addr << ": " << memoryy.data << endl;
        } else {
            // cout << "Leyendo de memoria en la direccion " << memoryy.addr << ": " << memoryy.q << endl;
        }

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

    for (int i = 0; i < 800; ++i) {
        if (i % n == 0 && i != 0) {
            cout << endl; // Nueva linea cada 16 elementos
        } 
        cout << memoryy.memory[i] << ", "; // Imprimir la memoria
    }
    cout << endl;

    // Hacer el calculo de A * B sin usar el arreglo sistolico
    cout << "\nResultado de la multiplicacion A*B (sin arreglo sistolico):" << endl;
    vector<vector<int>> result(n, vector<int>(n, 0));
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            int sum = 0;
            for (int k = 0; k < n; ++k) {
                sum += matrix_A[i][k] * matrix_B[k][j];
            }
            result[i][j] = sum;
            cout << result[i][j] << " ";
        }
        cout << endl;
    }

    return 1;
    

}