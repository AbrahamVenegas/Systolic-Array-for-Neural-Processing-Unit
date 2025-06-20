#ifndef PE_H
#define PE_H

// Clase PE para el arreglo sistolico
// inputs: clk, rst, weight, temp_left, temp_up, 
// outputs: result_down, result_right
class PE {
    public:
        // Variables (flip-flops)
        float weight;
        float calc;
        int state; // Indica si el PE esta activo
        //bool ready = false; // Indica si los PEs terminaron su trabajo

        // PEs vecinos (conexiones a los fliplops vecinos como pipelines)
        PE *down, *right;
        float temp_left; // Salida para el PE de la izquierda
        float temp_up;   // Salida para el PE de arriba

        float temp_left_2; // Un flip-flop para almacenar el valor de la izquierda
        float temp_up_2;   // Un flip-flop para almacenar el valor de arriba

        // Constructor
        PE(PE* down = nullptr, PE* right = nullptr);

        int update();
};

#endif // PE_H