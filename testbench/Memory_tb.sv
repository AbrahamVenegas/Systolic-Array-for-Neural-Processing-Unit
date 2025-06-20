


`timescale 1ns/1ps

module Memory_tb;

    // Parámetros de la IP
    localparam ADDR_W = 12;
    localparam DATA_W = 16;
    localparam DEPTH  = 1 << ADDR_W;

    // Señales
    logic [ADDR_W-1:0] address;
    logic clock;
    logic [DATA_W-1:0] data;
    logic wren;
    logic [DATA_W-1:0] q;

    // Instancia de la memoria
    Memory dut (
        .address(address),
        .clock(clock),
        .data(data),
        .wren(wren),
        .q(q)
    );

    // Generador de reloj
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Prueba de escritura y lectura
    initial begin
        // Inicialización
        wren = 0;
        address = 0;
        data = 0;

        // Espera un ciclo
        #10;

        // Escribe en las primeras 8 posiciones
        for (int i = 0; i < 8; i++) begin
            @(negedge clock);
            wren = 1;
            address = i;
            data = i * 11 + 3;
            $display("Escribiendo: addr=%0d, data=%0d", address, data);
        end

        // Desactiva escritura
        @(negedge clock);
        wren = 0;
        data = 'x;

        // Lee las posiciones escritas
        for (int i = 0; i < 8; i++) begin
            @(negedge clock);
            address = i;
            @(posedge clock); // Espera a que q se actualice
            #1;
            $display("Leyendo: addr=%0d, q=%0d", address, q);
        end

        #20;
        $finish;
    end

endmodule