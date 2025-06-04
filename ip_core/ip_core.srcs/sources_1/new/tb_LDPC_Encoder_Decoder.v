module tb_LDPC_0;

    // Параметры
    parameter CLK_PERIOD = 10; // Период тактового сигнала в нс
    parameter DATA_WIDTH = 128; // Ширина данных для AXI-Stream

    // Сигналы
    reg core_clk;
    reg reset_n;

    // S_AXI_CTRL (AXI-Stream для управления)
    reg [31:0] s_axis_ctrl_tdata;
    reg s_axis_ctrl_tvalid;
    wire s_axis_ctrl_tready;

    // S_AXI_DIN (AXI-Stream для входных данных)
    reg [DATA_WIDTH-1:0] s_axis_din_tdata;
    reg s_axis_din_tlast;
    reg s_axis_din_tvalid;
    wire s_axis_din_tready;

    // M_AXI_DOUT (AXI-Stream для выходных данных)
    wire [DATA_WIDTH-1:0] m_axis_dout_tdata;
    wire m_axis_dout_tlast;
    wire m_axis_dout_tvalid;
    reg m_axis_dout_tready;

    // M_AXI_STATUS (AXI-Stream для статуса)
    wire [31:0] m_axis_status_tdata;
    wire m_axis_status_tvalid;
    reg m_axis_status_tready;

    // Другие сигналы
    wire interrupt;

    // Инстанцирование IP-ядра
    ldpc_0 uut (
        .core_clk(core_clk),
        .reset_n(reset_n),
        .s_axis_ctrl_tdata(s_axis_ctrl_tdata),
        .s_axis_ctrl_tvalid(s_axis_ctrl_tvalid),
        .s_axis_ctrl_tready(s_axis_ctrl_tready),
        .s_axis_din_tdata(s_axis_din_tdata),
        .s_axis_din_tlast(s_axis_din_tlast),
        .s_axis_din_tvalid(s_axis_din_tvalid),
        .s_axis_din_tready(s_axis_din_tready),
        .m_axis_dout_tdata(m_axis_dout_tdata),
        .m_axis_dout_tlast(m_axis_dout_tlast),
        .m_axis_dout_tvalid(m_axis_dout_tvalid),
        .m_axis_dout_tready(m_axis_dout_tready),
        .m_axis_status_tdata(m_axis_status_tdata),
        .m_axis_status_tvalid(m_axis_status_tvalid),
        .m_axis_status_tready(m_axis_status_tready),
        .interrupt(interrupt)
    );

    // Генерация тактового сигнала
    always #(CLK_PERIOD / 2) core_clk = ~core_clk;

    // Основной процесс тестирования
    initial begin
        // Инициализация сигналов
        core_clk = 0;
        reset_n = 0;
        s_axis_ctrl_tdata = 0;
        s_axis_ctrl_tvalid = 0;
        s_axis_din_tdata = 0;
        s_axis_din_tlast = 0;
        s_axis_din_tvalid = 0;
        m_axis_dout_tready = 1; // Готовность принимать данные
        m_axis_status_tready = 1; // Готовность принимать статус

        // Сброс ядра
        #100 reset_n = 1;

        // Тест 1: Настройка ядра для кодирования
        #10;
        s_axis_ctrl_tdata = 32'h00000001; // Пример команды для кодирования
        s_axis_ctrl_tvalid = 1;
        wait (s_axis_ctrl_tready); // Ожидание готовности ядра
        #10;
        s_axis_ctrl_tvalid = 0;

        // Тест 2: Отправка данных для кодирования
        #10;
        s_axis_din_tdata = 128'hDEADBEEF1234567890ABCDEF12345678; // Пример входных данных
        s_axis_din_tvalid = 1;
        s_axis_din_tlast = 1; // Указание конца пакета
        wait (s_axis_din_tready); // Ожидание готовности ядра
        #10;
        s_axis_din_tvalid = 0;
        s_axis_din_tlast = 0;

        // Тест 3: Проверка выходных данных
        wait (m_axis_dout_tvalid); // Ожидание валидных выходных данных
        $display("Выходные данные: %h", m_axis_dout_tdata);
        $display("Статус: %h", m_axis_status_tdata);

        // Завершение симуляции
        #1000 $finish;
    end

    // Мониторинг сигналов (опционально)
    initial begin
        $monitor("Time=%0t | reset_n=%b | interrupt=%b | m_axis_dout_tvalid=%b | m_axis_dout_tdata=%h",
                 $time, reset_n, interrupt, m_axis_dout_tvalid, m_axis_dout_tdata);
    end

endmodule