module main_tb;

    parameter WIDTH = 16;
    logic clk = 0;
    logic rst;

    logic signed [WIDTH-1:0] in_left [0:3];
    logic signed [WIDTH-1:0] in_up   [0:3];
    logic signed [WIDTH-1:0] weights [0:3][0:3];
    logic signed [WIDTH-1:0] out_right [0:3];
    logic signed [WIDTH-1:0] out_down  [0:3];

    // Instanciar top
    main #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .rst(rst),
        .in_left(in_left),
        .in_up(in_up),
        .weights(weights),
        .out_right(out_right),
        .out_down(out_down)
    );

    // Generar reloj
    always #5 clk = ~clk;

    integer i, j;

    initial begin
        // Inicialización
        clk = 0;
        rst = 0;
        #10;
        rst = 1;

        // Cargar pesos de forma manual (por compatibilidad)
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                weights[i][j] = i + j + 1;
            end
        end

        in_left[0] = 0;
        in_left[1] = 0;
        in_left[2] = 0;
        in_left[3] = 0;

        // Asignar entradas desde arriba
        in_up[0] = 1;
        in_up[1] = 0;
        in_up[2] = 0;
        in_up[3] = 0;

        // Esperar suficientes ciclos
        #10;

        // Asignar entradas desde arriba
        in_up[0] = 5;
        in_up[1] = 2;
        in_up[2] = 0;
        in_up[3] = 0;

        #10;

        // Asignar entradas desde arriba
        in_up[0] = 9;
        in_up[1] = 6;
        in_up[2] = 3;
        in_up[3] = 0;

        #10; 

        // Asignar entradas desde arriba
        in_up[0] = 13;
        in_up[1] = 10;
        in_up[2] = 7;
        in_up[3] = 4;

        #10

        // Asignar entradas desde arriba
        in_up[0] = 0;
        in_up[1] = 14;
        in_up[2] = 11;
        in_up[3] = 8;

        #10

        // Asignar entradas desde arriba
        in_up[0] = 0;
        in_up[1] = 0;
        in_up[2] = 15;
        in_up[3] = 12;

        #10

        // Asignar entradas desde arriba
        in_up[0] = 0;
        in_up[1] = 0;
        in_up[2] = 0;
        in_up[3] = 16;

        #10

        // Mostrar resultados
        $display("=== Out Right ===");
        for (i = 0; i < 4; i = i + 1) begin
            $display("Row %0d: %0d", i, out_right[i]);
        end

        $display("=== Out Down ===");
        for (j = 0; j < 4; j = j + 1) begin
            $display("Col %0d: %0d", j, out_down[j]);
        end

        $finish;
    end

endmodule
