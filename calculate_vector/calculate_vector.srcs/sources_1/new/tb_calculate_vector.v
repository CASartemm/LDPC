`timescale 1ns / 1ps

module tb_calculate_vector;

    // ------------------------------------------------------------
    // 1. ОБЪЯВЛЯЕМ СИГНАЛЫ
    // ------------------------------------------------------------
    reg  aclk, aresetn;
    reg  s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;

    wire        m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    // ??????? ДОБАВИЛИ: подключаем 128-битный вектор «result» ???????
    wire [127:0] dut_result;
    // ???????????????????????????????????????????????????????????

    // Делитель на два (slow_clk_div2) для замедления приёма из DUT
    reg slow_clk_div2;

    // Массив для входной 640-битной последовательности
    reg [0:0] bit_sequence [0:639];
    integer i;

    // Регистр для сбора ВСЕХ выходных бит (640 входных + 128 выходных = 768)
    reg [0:767] all_bits;
    integer total_bit_count = 0;

    // ------------------------------------------------------------
    // 2. ИНСТАНЦИРУЕМ DUT: calculate_vector
    // ------------------------------------------------------------
    calculate_vector dut (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast),

        .result       (dut_result),    // ? вот он, порт 128-бит
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast (m_axis_tlast)
    );

    // ------------------------------------------------------------
    // 3. ГЕНЕРАЦИЯ ТАКТОВОГО СИГНАЛА (100 МГц, период 10 нс)
    // ------------------------------------------------------------
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // ------------------------------------------------------------
    // 4. ДЕЛИТЕЛЬ НА ДВА (slow_clk_div2) - замедление m_axis_tready
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // 5. СБОР ВСЕХ ВЫХОДНЫХ БИТ (для анализа и вывода)
    // ------------------------------------------------------------
    // Каждый раз, когда (m_axis_tvalid & m_axis_tready) == 1, берём m_axis_tdata и
    // пишем в all_bits[ total_bit_count ], инкрементируя total_bit_count.
    always @(posedge aclk) begin
        if (aresetn && m_axis_tvalid && m_axis_tready) begin
            all_bits[total_bit_count] <= m_axis_tdata;
            total_bit_count <= total_bit_count + 1;
        end
    end

    // ------------------------------------------------------------
    // 6. ОСНОВНОЙ initial-БЛОК: сброс ? загрузка ? передача ? ожидание ? вывод
    // ------------------------------------------------------------
    initial begin
        // 6.1. Сброс и начальные сигналы
        aresetn       = 1'b0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        // m_axis_tready задаётся через slow_clk_div2
        #10 aresetn = 1'b1;

        // 6.2. ЗАГРУЗКА 640 БИТ из файла sequence.txt
        // Файл должен содержать ровно 640 символов '0'/'1', без пробелов.
        $readmemb("sequence.txt", bit_sequence);

        // 6.3. ОТПРАВКА 640 БИТ В DUT по s_axis_* (один бит в такт)
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            // Ждём, пока DUT скажет s_axis_tready = 1
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            s_axis_tdata  = bit_sequence[i];
            s_axis_tvalid = 1'b1;
            s_axis_tlast  = (i == 639) ? 1'b1 : 1'b0;
        end

        // После последнего бита сразу сбрасываем s_axis_tvalid/tlast
        @(posedge aclk);
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;

        // 6.4. ОЖИДАЕМ, пока all_bits наберёт 768 элементов
        // (сначала 640 входных, потом 128 выходных)
        while (total_bit_count < 768) begin
            @(posedge aclk);
        end

        // 6.5. ВЫВОД первых 640 БИТ (входная последовательность)
        $display("First 640 bits (input data):");
        for (integer j = 0; j < 20; j = j + 1) begin  // 20 групп по 32 бита = 640
            $write("%b ", all_bits[j*32 +: 32]);
        end
        $write("\n");

        // 6.6. ВЫВОД следующих 128 БИТ (результат по m_axis_tdata)
        $display("Next 128 bits (result from AXI-Stream):");
        for (integer j = 0; j < 4; j = j + 1) begin  // 4 группы по 32 бита = 128
            $write("%b ", all_bits[640 + j*32 +: 32]);
        end
        $display("\n");

        // 6.7. ДОПОЛНИТЕЛЬНО: выводим порт dut_result (целый 128-битный вектор)
        $display("DUT internal 128-bit result (port): %h", dut_result);

        $display("The simulation is completed.");
        $finish;
    end

    // ------------------------------------------------------------
    // 7. МОНИТОРИНГ (необязательно) - выводим важные сигналы в лог
    // ------------------------------------------------------------
    initial begin
        $display("   time   aclk aresetn s_tready m_tvalid m_tdata m_tready m_tlast");
        $monitor("%8t   %b     %b       %b         %b        %b         %b       %b",
                  $time, aclk, aresetn, s_axis_tready,
                  m_axis_tvalid, m_axis_tdata,
                  m_axis_tready, m_axis_tlast);
    end

endmodule
