

// Entradas: clk, data, wren, addr
// Salidad: q

class Memory {
    public:
        // Entradas 
        int clk;
        int data; // Data to write (32 bits) por palabra
        int wren; // Write enable
        int addr; // Address to read/write (16 bits)
        
        // Salidas
        int q; // Data read from memory (32 bits)

        // Memoria de 65536 palabras
        int memory[65536];
        

        void update() {
            // Si wren es alto, escribimos en la memoria
            if (wren) {
                memory[addr] = data;
            }
            // Siempre leemos de la memoria
            q = memory[addr];
        }


};