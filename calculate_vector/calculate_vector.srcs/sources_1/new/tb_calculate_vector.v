module tb_calculate_vector;

    // Сигналы для тестирования
    reg aclk;
    reg aresetn;
    reg s_axis_tdata;       // 1 бит входных данных
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;

    wire m_axis_tdata;      // 1 бит выходных данных
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;

    // Переменные и массивы
    reg [639:0] bit_sequence;             // 640 бит входных данных
    reg [127:0] expected_result_bits;     // 128 бит эталонного результата
    reg [127:0] expected_result;          // Эталонный результат
    reg [127:0] received_result;          // Полученный результат от DUT
    integer i;                            // Счетчик циклов
    integer bit_count;                    // Счетчик битов результата
    integer fd;                           // Файловый дескриптор
    integer char;                         // Прочитанный символ
    integer test_num;                     // Номер теста
    reg [767:0] bits;                     // Временный массив для 768 бит
    integer bit_idx;                      // Индекс в массиве bits
    reg end_of_file;                      // Флаг конца файла
    integer success_count;                // Счетчик успешных тестов
    integer fail_count;                   // Счетчик неуспешных тестов

    // Подключение DUT
    calculate_vector dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Генерация тактового сигнала
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // Период 10 единиц времени
    end

    // Основной тестовый процесс
    initial begin
        // Инициализация сигналов и переменных
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        received_result = 128'b0;
        expected_result = 128'b0;
        test_num = 0;
        bit_idx = 0;
        end_of_file = 0;
        success_count = 0;
        fail_count = 0;
        #10 aresetn = 1;

        // Открытие файла с тестовыми векторами
        fd = $fopen("sequence.txt", "r");
        if (fd == 0) begin
            $display("Не удалось открыть файл sequence.txt");
            $finish;
        end

        // Чтение и обработка тестов
        while (!end_of_file) begin
            char = $fgetc(fd);
            if (char == -1) begin // Конец файла
                if (bit_idx > 0) begin
                    $display("Внимание: тест длиной %0d битов не обработан (меньше 768 бит)", bit_idx);
                end
                end_of_file = 1;
            end else if (char == "0" || char == "1") begin
                bits[bit_idx] = (char == "1");
                bit_idx = bit_idx + 1;
                if (bit_idx == 768) begin
                    test_num = test_num + 1;
                    $display("Тест %0d:", test_num);

                    // Разделение на входную последовательность и эталонный результат
                    for (i = 0; i < 640; i = i + 1) begin
                        bit_sequence[i] = bits[i];
                    end
                    for (i = 0; i < 128; i = i + 1) begin
                        expected_result_bits[i] = bits[640 + i];
                    end
                    for (i = 0; i < 128; i = i + 1) begin
                        expected_result[127 - i] = expected_result_bits[i];
                    end

                    // Передача входных данных в DUT
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

                    // Получение результата от DUT
                    bit_count = 0;
                    received_result = 128'b0;
                    while (bit_count < 128) begin
                        @(posedge aclk);
                        if (m_axis_tvalid && m_axis_tready) begin
                            received_result[bit_count] = m_axis_tdata;
                            bit_count = bit_count + 1;
                        end
                    end

                    // Сравнение и вывод результата
                    $display("  Получено: %b", received_result);
                    $display("  Ожидалось: %b", expected_result);
                    if (received_result === expected_result) begin
                        $display("  Результат: УСПЕХ");
                        success_count = success_count + 1;
                    end else begin
                        $display("  Результат: ОШИБКА");
                        fail_count = fail_count + 1;
                    end

                    // Сброс индекса для следующего теста
                    bit_idx = 0;
                end
            end
            // Пропуск незначимых символов (например, \\n)
        end

        // Завершение и вывод статистики
        $fclose(fd);
        $display("Все тесты завершены.");
        $display("Итого: успешных тестов = %0d, неуспешных = %0d, всего = %0d", success_count, fail_count, test_num);
        $finish;
    end

endmodule