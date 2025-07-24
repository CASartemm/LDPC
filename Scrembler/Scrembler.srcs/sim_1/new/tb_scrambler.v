module tb_scrambler;  // Основной модуль тестбенча для проверки модуля scrambler

    reg clk = 0;  // Регистр для сигнала тактовой частоты, инициализирован 0
    reg rst = 1;  // Регистр для сигнала сброса, 1 - нормальная работа, 0 - сброс
    reg s_axis_tvalid ;  // Регистр для валидности входных данных, 0 - данные не валидны
    wire s_axis_tready;  // Провод для сигнала готовности приема данных
    reg s_axis_tdata = 0;  // Регистр для 1-битных входных данных
    reg s_axis_tlast = 0;  // Регистр для сигнала последнего бита в пакете
    wire m_axis_tvalid;  // Провод для валидности выходных данных
    reg m_axis_tready = 1;  // Регистр для готовности приема выходных данных
    wire m_axis_tdata;  // Провод для 1-битных выходных данных
    wire m_axis_tlast;  // Провод для сигнала последнего бита на выходе

    integer fd;  // Дескриптор файла
    integer bit_idx;  // Индекс в массиве bits
    integer char;  // Переменная для хранения символа из файла
    integer test_num = 0;  // Номер текущего теста
    reg end_of_file = 0;  // Флаг конца файла
    reg [0:767] bits;  // Массив для хранения 768 битов
    reg [0:767] output_bits;  // Массив для хранения выходных битов
    integer output_idx = 0;  // Индекс для выходных битов

    scrambler dut (  // Подключение модуля scrambler
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    always #5 clk = ~clk;  // Генератор такта: инверсия каждые 5 единиц времени

    integer i;
    
    
    
    // Добавление задержки на m_axis_tready
//initial begin
  //  m_axis_tready = 1;
    //#1000 m_axis_tready = 0;  // Задержка 500 единиц времени, затем m_axis_tready низкий
    //#3000 m_axis_tready = 1;  // Через 100 единиц времени m_axis_tready снова высокий
//end

////



////
    initial begin
     
      
     

        // Открытие файла
        fd = $fopen("Scrembler_data.txt", "r");
        if (fd == 0) begin
            $display("Не удалось открыть файл Scrembler_data.txt");
            $finish;
        end

        // Чтение и обработка тестов
        bit_idx = 0;
        while (!end_of_file) begin
            char = $fgetc(fd);
            if (char == -1) begin
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
                    
                    output_idx = 0;  // Сбрасываем индекс выходных битов
                    for (i = 0; i < 768; i = i + 1) begin
                        @(posedge clk);
                        while (!s_axis_tready) begin
                            @(posedge clk);
                        end
                        s_axis_tdata = bits[i];
                        s_axis_tvalid = 1;
                        s_axis_tlast = (i == 767);
                    end
                    @(posedge clk);
                    s_axis_tvalid = 0;
                    s_axis_tlast = 0;
                    @(posedge clk);
                    // Вывод строки битов после обработки теста
                    $display("Выходные данные (m_axis_tdata) для теста %0d:", test_num);
                    for (i = 0; i < output_idx; i = i + 1) begin
                        $write("%b", output_bits[i]);
                    end
                    $write("\n");
                    
                    bit_idx = 0;
                end
            end
        end
        
        $fclose(fd);
        $display("Все тесты завершены.");
        #60; $finish;
    end

    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            output_bits[output_idx] = m_axis_tdata;  // Сохраняем выходной бит
            output_idx = output_idx + 1;  // Увеличиваем индекс
        end
    end

endmodule