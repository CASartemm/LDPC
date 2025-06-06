`timescale 1ns / 1ps

module tb_calculate_vector;

    // Сигналы
    reg  aclk, aresetn;
    reg  s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;

    wire        m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    // Подключаем 128-битный вектор «result»
    wire [127:0] dut_result;

    // Делитель на два для замедления приёма
    reg slow_clk_div2;

    // Массив для входной 640-битной последовательности
    reg [0:0] bit_sequence [0:639];
    integer i;

    // Флаг завершения вывода
    reg output_complete = 0;

    // Счётчик для отслеживания номера бита
    integer bit_counter = 0;

    // Инстанцируем DUT
    calculate_vector dut (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast),

        .result       (dut_result),
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast (m_axis_tlast)
    );

    // Генерация тактового сигнала (100 МГц, период 10 нс)
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // Делитель на два для m_axis_tready
    initial begin
        slow_clk_div2 = 1'b0;
    end
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            slow_clk_div2 <= 1'b0;
        end else begin
            slow_clk_div2 <= ~slow_clk_div2;
        end
    end
    always @(*) begin
        m_axis_tready = slow_clk_div2;
    end

    // Обнаружение завершения вывода
    always @(posedge aclk) begin
        if (!aresetn) begin
            output_complete <= 0;
        end else if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
            output_complete <= 1;
        end
    end

    // Логика для отображения бит с номерами и отметки начала передачи 128 бит
    always @(posedge aclk) begin
        if (aresetn && m_axis_tvalid && m_axis_tready) begin
            bit_counter = bit_counter + 1;
            if (bit_counter == 641) begin
                $display("Начало передачи 128-битного результата");
            end
            $display("%d-й бит: %b", bit_counter, m_axis_tdata);
        end
    end

    // Отладочный вывод для m_axis_tvalid и m_axis_tready
    always @(posedge aclk) begin
        $display("Time: %t, m_axis_tvalid: %b, m_axis_tready: %b", $time, m_axis_tvalid, m_axis_tready);
    end

    // Основной initial-блок: сброс ? загрузка ? передача ? ожидание ? завершение
    initial begin
        // Сброс и начальные сигналы
        aresetn       = 1'b0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        #10 aresetn = 1'b1;

        // Загрузка 640 бит из файла sequence.txt
        $readmemb("sequence.txt", bit_sequence);

        // Отправка 640 бит в DUT
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            s_axis_tdata  = bit_sequence[i];
            s_axis_tvalid = 1'b1;
            s_axis_tlast  = (i == 639) ? 1'b1 : 1'b0;
        end
        $display("Цикл завершился, i = %d", i);

        // Сброс сигналов после последнего бита
        @(posedge aclk);
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;

        // Ожидание завершения вывода
        while (!output_complete) begin
            @(posedge aclk);
        end

        $display("The simulation is completed.");
        $finish;
    end

endmodule