module tb_shift_register_processor;
    reg clk, rst;
    wire [127:0] out_row;
    wire valid;
    integer file;
    integer i;

    shift_register_processor uut (
        .clk(clk),
        .rst(rst),
        .out_row(out_row),
        .valid(valid)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Период 10 единиц времени
    end

    initial begin
        file = $fopen("matrix_full_sim.txt", "w");
        rst = 1;
        #10 rst = 0;

        for (i = 0; i < 640; i = i + 1) begin
            @(posedge clk);
            #1; // Небольшая задержка для учета NBA-обновлений
            if (valid) begin
                // Вывод на экран в двоичном виде в одну строку
                $display("Time: %0t, out_row: %b", $time, out_row);
                // Запись в файл в шестнадцатеричном формате
                $fwrite(file, "%h\n", out_row);
            end
        end
        #10; // Задержка перед закрытием файла
        $fclose(file);
        $display("Total rows written: %0d", i);
        $finish;
    end
endmodule