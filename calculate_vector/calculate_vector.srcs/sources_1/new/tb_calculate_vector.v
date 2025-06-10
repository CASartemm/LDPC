module tb_calculate_vector;

    // Сигналы
    reg  aclk, aresetn;
    reg  s_axis_tdata;
    reg  s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;

    wire        m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    wire [127:0] dut_result;

    reg slow_clk_div2;

    reg [0:0] bit_sequence [0:639];
    integer bit_index;

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

    // Генерация тактового сигнала
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // Генерация замедленного сигнала для m_axis_tready
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

    // Основной процесс отправки данных
    initial begin
        // Инициализация
        aresetn = 1'b0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast = 1'b0;
        s_axis_tdata = 1'b0;
        #10 aresetn = 1'b1;

        // Чтение данных из файла
        $readmemb("sequence.txt", bit_sequence);

        // Установка начальных значений и запуск передачи
        bit_index = 0;
        s_axis_tdata = bit_sequence[0];
        s_axis_tlast = (bit_index == 639);
        s_axis_tvalid = 1'b1;

        // Бесконечная отправка потоков
        forever begin
            @(posedge aclk);
            if (s_axis_tready) begin
                bit_index = (bit_index + 1) % 640;
                s_axis_tdata = bit_sequence[bit_index];
                s_axis_tlast = (bit_index == 639);
            end
        end
    end

    // Остановка симуляции
    initial begin
        #10000; // Симуляция длится 10 мкс
        $display("Симуляция завершена.");
        $finish;
    end

endmodule