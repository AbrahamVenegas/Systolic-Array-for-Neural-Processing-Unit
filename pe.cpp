#include "pe.h"

// Clase PE para el arreglo sistolico
// inputs: clk, rst, weight, temp_left, temp_up, 
// outputs: result_down, result_right

// Constructor
PE::PE(PE* down, PE* right) {
    weight = 0.0;
    calc = 0.0;
    state = 0; // Indica si el PE esta activo

    this->down = down;
    this->right = right;

    temp_left = 0.0; // Salida para el PE de la izquierda
    temp_up = 0.0;   // Salida para el PE de arriba

    temp_left_2 = 0.0; // Un flip-flop para almacenar el valor de la izquierda
    temp_up_2 = 0.0;   // Un flip-flop para almacenar el valor de arriba
}

int PE::update() {
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