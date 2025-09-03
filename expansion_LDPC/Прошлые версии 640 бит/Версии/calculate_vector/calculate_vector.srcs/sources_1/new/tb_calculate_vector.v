module tb_calculate_vector;

    // Сигналы для управления
    reg aclk, aresetn;
    reg s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;
    wire [127:0] result;
    wire result_valid;

    // Массив для входной последовательности битов
    reg [0:0] bit_sequence [0:639];
    integer i;

    // Экземпляр модуля calculate_vector
    calculate_vector dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .result(result),
        .result_valid(result_valid)
    );

    // Генерация тактового сигнала
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;  // Частота 100 МГц
    end

    // Логика тестбенча
    initial begin
        // Инициализация
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        #10 aresetn = 1;

        // Загрузка последовательности из файла
        $readmemb("sequence.txt", bit_sequence);

        // Отправка последовательности в модуль
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            s_axis_tdata = bit_sequence[i];
            s_axis_tvalid = 1;
            s_axis_tlast = (i == 639);
        end
        @(posedge aclk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;

        // Ожидание результата
        wait (result_valid);
        $display("Result: %h", result);

        // Завершение симуляции
        $display("Simulation finished");
        $finish;
    end

endmodule