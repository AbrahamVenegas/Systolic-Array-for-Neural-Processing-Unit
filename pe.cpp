#include <iostream>
#include <vector>
using namespace std;

// Clase PE para el arreglo sistolico
class PE {
    public:
        // Variables (flip-flops)
        float weight;
        float calc;
        bool ready = false; // Indica si los PEs terminaron su trabajo

        // PEs vecinos (conexiones a los fliplops vecinos como pipelines)
        PE *down, *right;
        float temp_left = 0; // Un flip-flop para almacenar el valor de la izquierda
        float temp_up = 0; // Un flip-flop para almacenar el valor de arriba

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
        calc = (temp_up * weight) + temp_left;

        // Las validaciones y el ready no se hacen en el hardware, pero hay que pasar los valores temps a los vecinos
        if (right != nullptr) {
            right->temp_left = calc;
        } else {
            // Si no hay PE a la derecha, se considera que el valor de salida es el resultado final
            ready = true;
        }
        if (down != nullptr) {
            down->temp_up = temp_up; // Pasa el valor calculado al PE de abajo
        }

        return 1;
    }

    
 
};

// Probar la clase PE en un arreglo sistolico 4x4

int main() {
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
    vector<vector<float>> input_up = {{1, 2, 3, 4},
                                      {1, 6.0, 7.0, 8.0}, 
                                      {2, 10.0, 11.0, 12.0}, 
                                      {3, 14.0, 15.0, 16.0}};
    vector<vector<float>> weights = {{1, 2, 3, 4},
                                     {1, 1.0, 1.1, 1.2}, 
                                     {2, 1.4, 1.5, 1.6}, 
                                     {3, 1.7, 1.8, 1.9}};

    // Definir los tamanos de las matrices cuadradas
    int n = 3;

    // Asignar pesos a los PEs (desde el control unit)
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            pe_array[i][j].weight = weights[i][j];

        }
    }

    // Simular el procesamiento de los PEs
    vector<vector<float>> output(size, vector<float>(size, 0.0));     // Almacenamiento de datos de salida
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            pe_array[0][j].temp_up = input_up[j][i]; // Cargar el valor de entrada
            for (int i = 0; i < size; ++i) {
                for (int j = 0; j < size; ++j) {
                    pe_array[i][j].update(); // Actualizar cada PE
                }
            }
        }   

        // Guardar en una matriz los resultados de los PEs listos
        for (int i2 = 0; i2 < size; ++i2) {
            if (pe_array[i2][3].ready) {
                //cout << "PE[" << i2 << "][" << 3 << "] = " << pe_array[i2][3].calc << endl;
                output[i2][i] = pe_array[i2][3].calc; // Guardar el resultado en la matriz de salida
            }

        }
    }

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



