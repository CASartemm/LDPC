module tb_top_module;
    reg clk, rst;
    reg s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;
    wire [127:0] result;
    wire result_valid;

    reg [0:0] bit_sequence [0:639];  // Массив для 640 бит
    integer i;

    // Экземпляр top_module
    top_module dut (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .result(result),
        .result_valid(result_valid)
    );

    // Генерация тактового сигнала
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Частота 100 МГц
    end

    // Логика тестбенча
    initial begin
        rst = 1;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        #20 rst = 0;  // Снимаем сброс через 20 нс

        // Загрузка последовательности из файла
        $readmemb("sequence.txt", bit_sequence);

        // Отправка последовательности
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge clk);
            s_axis_tdata = bit_sequence[i];
            s_axis_tvalid = 1;
            s_axis_tlast = (i == 639);
            // Ждём, пока модуль примет данные
            wait(s_axis_tready);
        end
        @(posedge clk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;

        // Ожидание результата
        wait(result_valid == 1);
        $display("Результат: %h", result);

        #100 $finish;  // Завершаем симуляцию
    end

    // Отладочный вывод для проверки передачи данных
    always @(posedge clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            $display("Передача бита %d: %b", i, s_axis_tdata);
        end
    end

    // Отладочный вывод для проверки генерации строк
    always @(posedge clk) begin
        if (dut.u_shift_register_processor.valid) begin
            $display("Строка %d: %h", dut.u_shift_register_processor.shift_cnt + 32 * dut.u_shift_register_processor.base_idx, dut.u_shift_register_processor.out_row);
        end
    end

    // Отладочный вывод для проверки аккумулятора
    always @(posedge clk) begin
        if (dut.u_matrix_vector_multiplier.bit_valid && dut.u_matrix_vector_multiplier.row_valid) begin
            $display("Обработка такта %d: bit_in = %b, accumulator = %h", dut.u_matrix_vector_multiplier.count, dut.u_matrix_vector_multiplier.bit_in, dut.u_matrix_vector_multiplier.accumulator);
        end
    end
endmodule