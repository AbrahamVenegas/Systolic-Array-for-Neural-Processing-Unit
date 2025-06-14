#include <iostream>
#include <vector>
using namespace std;

// Clase PE para el arreglo sistolico
// inputs: clk, rst, weight, temp_left, temp_up, 
// outputs: result_down, result_right
class PE {
    public:
        // Variables (flip-flops)
        float weight;
        float calc;
        int state = 0; // Indica si el PE esta activo
        //bool ready = false; // Indica si los PEs terminaron su trabajo

        // PEs vecinos (conexiones a los fliplops vecinos como pipelines)
        PE *down, *right;
        float temp_left = 0; // Salida para el PE de la izquierda
        float temp_up = 0; // Salida para el PE de arriba

        float temp_left_2 = 0; // Un flip-flop para almacenar el valor de la izquierda
        float temp_up_2 = 0; // Un flip-flop para almacenar el valor de arriba

    // Constructor
    PE(PE* down, PE* right) {
        weight = 0.0;
        calc = 0.0;

        this->down = down;
        this->right = right;
    }

    int update() {
        // Si es PE de la primer fila, cargar el valor de entrada de arriba directamente a temp_up

        // Multiplica el valor de entrada de arriba por el peso y lo suma al valor de entrada de la izquierda 
        // (logica combinacional)
        calc = (temp_up_2 * weight) + temp_left_2;
        temp_left_2 = temp_left; 
        temp_up_2 = temp_up; 

        // Las validaciones y el ready no se hacen en el hardware, pero hay que pasar los valores temps a los vecinos
        if (right != nullptr) {
            right->temp_left = calc;
        }

        if (down != nullptr) {
            down->temp_up = temp_up; // Pasa el valor calculado al PE de abajo
        }

        return 1;
    }    
 
};

class Counter {
    public:
        int count = 0; // Contador para el reloj

        // Incrementa el contador
        void tick() {
            count++;
        }

        // Resetea el contador
        void reset() {
            count = 0;
        }

};

// Probar la clase PE en un arreglo sistolico 4x4

int main() {

    /*
    Ejemplo arreglo sistolico 4x4:
    int n = 4; // Tamaño de la matriz cuadrada
    for (int t = 0; t < 2 * n - 1; ++t) {
        for (int i = 0; i < n; ++i) {
            int j = t - i;
            if (j >= 0 && j < n) {
                cout << "PE[" << i << "][" << j << "], ";
            }
        }
        cout << endl;
    }
    */

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

    // Crear matrices de ejemplo

    // Definir los tamanos de las matrices cuadradas
    int n = 4;
    // Input_up es la matriz A
    vector<vector<float>> input_up = {{1, 2, 3, 4},
                                      {1, 6.0, 7.0, 8.0}, 
                                      {2, 10.0, 11.0, 12.0}, 
                                      {3, 14.0, 15.0, 16.0}};
    // Weights es la matriz B
    vector<vector<float>> weights = {{1, 2, 3, 4},
                                     {1, 1.0, 1.1, 1.2}, 
                                     {2, 1.4, 1.5, 1.6}, 
                                     {3, 1.7, 1.8, 1.9}};

    

    // Asignar pesos a los PEs (desde el control unit)
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            // Se debe hace la transpuesta de la matriz de pesos
            pe_array[i][j].weight = weights[j][i];

        }
    }

    cout << "Pesos" << endl;
    for (int i2 = 0; i2 < n; ++i2) {
        for (int j2 = 0; j2 < n; ++j2) {
            cout << pe_array[i2][j2].weight << " ";
        }
        cout << endl;
    }
    cout << endl;

    // Simular el procesamiento de los PEs
    vector<vector<float>> output(size, vector<float>(size, 0.0));     // Almacenamiento de datos de salida


    int icol0, icol1, icol2, icol3;
    for (int i = 0; i < n * 2; ++i) {
        // Definir los indices de las columnas de entrada
        icol0 = (i < n) ? i : 0xFF;
        icol1 = (i - 1 < n && i - 1 >= 0) ? i - 1 : 0xFF;
        icol2 = (i - 2 < n && i - 2 >= 0) ? i - 2 : 0xFF;
        icol3 = (i - 3 < n && i - 3 >= 0) ? i - 3 : 0xFF;

        // Cargar los valores de entrada en los PEs de la primera fila
        // Si el indice es 0xFF, significa que no hay valor de entrada, se carga 0.0
        pe_array[0][0].temp_up = (icol0 != 0xFF) ? input_up[icol0][0] : 0.0; // Cargar el valor de entrada
        pe_array[0][1].temp_up = (icol1 != 0xFF) ? input_up[icol1][1] : 0.0; // Cargar el valor de entrada
        pe_array[0][2].temp_up = (icol2 != 0xFF) ? input_up[icol2][2] : 0.0; // Cargar el valor de entrada
        pe_array[0][3].temp_up = (icol3 != 0xFF) ? input_up[icol3][3] : 0.0; // Cargar el valor de entrada
        
        // Actualizar cada PE
        for (int i2 = 0; i2 < n; ++i2) {
            for (int j2 = 0; j2 < n; ++j2) {
                pe_array[i2][j2].update(); // Actualizar cada PE
            }
        }
        
        // Guardar en una matriz los resultados de los PEs
        if (i >= 4) {
            for (int j = 0; j < n; ++j) {
                output[i % 4][j] = pe_array[j][3].calc; // Guardar el resultado en la matriz de salida
            }
        }
        
    }

    /* Salidas: (En este caso, ciclo + 1)
    Ciclo 4: C00, C01, C02, C03
    Ciclo 5: C10, C11, C12, C13
    Ciclo 6: C20, C21, C22, C23
    Ciclo 7: C30, C31, C32, C33
    */

    // Imprimir la matriz de salida
    cout << "Matriz de salida:" << endl;
    for (const auto& row : output) {
        for (const auto& val : row) {
            cout << val << " ";
        }
        cout << endl;
    }

    return 0;

}



