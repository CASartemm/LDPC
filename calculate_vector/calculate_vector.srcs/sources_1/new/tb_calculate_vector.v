// Тестовый модуль для проверки модуля calculate_vector
module tb_calculate_vector;

    // Входные сигналы для AXI Stream Slave интерфейса
    reg aclk;              // Тактовый сигнал
    reg aresetn;           // Сигнал асинхронного сброса (активный низкий)
    reg s_axis_tdata;      // Входной бит данных (1 бит)
    reg s_axis_tvalid;     // Сигнал валидности входных данных
    reg s_axis_tlast;      // Сигнал последнего бита в последовательности
    wire s_axis_tready;    // Сигнал готовности принять входные данные

    // Выходные сигналы для AXI Stream Master интерфейса
    wire m_axis_tdata;     // Выходной бит данных (1 бит)
    wire m_axis_tvalid;    // Сигнал валидности выходных данных
    reg  m_axis_tready;    // Сигнал готовности принять выходные данные
    wire m_axis_tlast;     // Сигнал последнего бита в выходной последовательности

    // Массивы для хранения входных последовательностей
    reg [0:0] bit_sequence_1 [0:639]; // Массив на 640 бит из первого файла
    reg [0:0] bit_sequence_2 [0:639]; // Массив на 640 бит из второго файла
    integer i;                      // Счетчик для цикла

    // Регистры для хранения результатов
    reg [127:0] received_result_1;  // Полученный первый результат (128 бит)
    reg [127:0] received_result_2;  // Полученный второй результат (128 бит)
    integer bit_count;              // Счетчик принятых бит
    integer cycle_count;            // Счетчик обработанных последовательностей

    // Инстанцирование тестируемого модуля calculate_vector
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
        forever #5 aclk = ~aclk;  // Период тактового сигнала 10 нс (частота 100 МГц)
    end

    // Инициализация тестового окружения
    initial begin
        // Инициализация сигналов
        aresetn = 0;            // Активный сброс
        s_axis_tvalid = 0;      // Данные не валидны
        s_axis_tlast = 0;       // Не последний бит
        m_axis_tready = 1;      // Приемник готов принять выходные данные
        bit_count = 0;          // Сбрасываем счетчик бит
        cycle_count = 0;        // Сбрасываем счетчик циклов
        received_result_1 = 128'b0; // Очищаем регистр для первого результата
        received_result_2 = 128'b0; // Очищаем регистр для второго результата
        #10 aresetn = 1;        // Снимаем сброс через 10 нс

        // Загружаем последовательности из файлов
        $readmemb("sequence.txt", bit_sequence_1);    // Загружаем 640 бит из первого файла
        $readmemb("sequence_2.txt", bit_sequence_2);  // Загружаем 640 бит из второго файла

        // Два раза подаем последовательность для обработки
        repeat(2) begin
            // Подаем последовательность в модуль
            for (i = 0; i < 640; i = i + 1) begin
                @(posedge aclk); // Ждем положительного фронта такта
                while (!s_axis_tready) begin
                    @(posedge aclk); // Ждем, если модуль не готов принять данные
                end
                // Выбираем последовательность в зависимости от цикла
                s_axis_tdata = (cycle_count == 0) ? bit_sequence_1[i] : bit_sequence_2[i];
                s_axis_tvalid = 1;             // Указываем, что данные валидны
                s_axis_tlast = (i == 639);     // Устанавливаем tlast для последнего бита
            end
            @(posedge aclk);
            s_axis_tvalid = 0; // Сбрасываем валидность данных
            s_axis_tlast = 0;  // Сбрасываем флаг последнего бита

            // Принимаем результат на выходе
            bit_count = 0; // Сбрасываем счетчик принятых бит
            while (bit_count < 128) begin
                @(posedge aclk); // Ждем положительного фронта такта
                if (m_axis_tvalid && m_axis_tready) begin
                    // Сохраняем выходной бит в соответствующий регистр
                    if (cycle_count == 0) begin
                        received_result_1[bit_count] = m_axis_tdata; // Первый результат
                    end else begin
                        received_result_2[bit_count] = m_axis_tdata; // Второй результат
                    end
                    bit_count = bit_count + 1; // Увеличиваем счетчик бит
                    // Проверяем окончание передачи результата
                    if (m_axis_tlast && bit_count == 128) begin
                        if (cycle_count == 0) begin
                            $display("Первый результат: %b", received_result_1); // Выводим первый результат
                        end else begin
                            $display("Второй результат: %b", received_result_2); // Выводим второй результат
                        end
                    end
                end
            end
            cycle_count = cycle_count + 1; // Увеличиваем счетчик циклов
        end

        // Завершение тестирования
        $display("Тестирование завершено");
        $finish; // Завершаем симуляцию
    end

endmodule