
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

    // Llenar la memoria con datos de ejemplo
    // Cargar matrices de ejemplo
    vector<vector<int>> matrix_A = {
        {1, 2, 3, 4, 5, 6, 7, 8},
        {9, 10, 11, 12, 13, 14, 15, 16},
        {17, 18, 19, 20, 21, 22, 23, 24},
        {25, 26, 27, 28, 29, 30, 31, 32},
        {33, 34, 35, 36, 37, 38, 39, 40},
        {41, 42, 43, 44, 45, 46, 47, 48},
        {49, 50, 51, 52, 53, 54, 55, 56},
        {57, 58, 59, 60, 61, 62, 63, 64}
    };

    vector<vector<int>> matrix_B = {
        {1, 2, 3, 4, 5, 6, 7, 8},
        {8, 7, 6, 5, 4, 3, 2, 1},
        {2, 4, 6, 8, 10, 12, 14, 16},
        {16, 14, 12, 10, 8, 6, 4, 2},
        {1, 3, 5, 7, 9, 11, 13, 15},
        {15, 13, 11, 9, 7, 5, 3, 1},
        {5, 10, 15, 20, 25, 30, 35, 40},
        {40, 35, 30, 25, 20, 15, 10, 5}
    };

    vector<vector<int>> matrix_C(8, vector<int>(8, 0)); // Matriz de resultado C

    // Matrices registro para hacer el calculo
    vector<vector<int>>matrix_A_calc(4, vector<int>(4, 0)); 
    vector<vector<int>>matrix_B_calc(4, vector<int>(4, 0)); 
    vector<vector<int>>matrix_C_calc(4, vector<int>(4, 0)); 
    vector<vector<int>>matrix_D_sum(4, vector<int>(4, 0)); 

    // Realizar analisis para calcular A*B = C en un arreglo sistolico 4x4
    int act_addr = 0;
    int n = 8;
    
    //                 i, j      i y j van de 1 a 1 pero se debe hacer calculo de la ubicacion de direccion en memoria (4 en 4)
    int offset_A[2] = {0, 0}; // Offset para la matriz A
    int offset_B[2] = {0, 0}; // Offset para la matriz B 

    int div_matrix = n / 4;     // Partes en las que se divide la matriz (k)


        



    

}