module tb_tdma_LDPC_working;

    reg aclk;
    reg aresetn;

    reg s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;

    wire m_axis_tdata;
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;

    tdma_LDPC dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Clock generation
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // period = 10
    end

    // 640-битный входной вектор
    reg [639:0] input_vector = 640'b1000000000010000011100111111111100001100000110000011011011110000101000100000000000000000011101001100001001110100000000100000000011111100100010001101110101010110000000110001010101111011100101100000001100010101101110111101011010010101101000111011000000110101000000000101100000000110101010100000000010011100111011100011100110111000101110010000110010101111010110101011101111110001001000110100001001001101111101110100001011100011101100110001100000001000001101101111000010100010000000000000000011001100110000101111010000000010000000001111110010001000110111010010011000000011000101010111101110010110000000110001010110111011110101101001010110100011;

    // Эталонный 128-битный результат
    reg [127:0] expected_result_bits = 128'b10100111100110010101011001010001011110001101010001010110111110010001000011111011011110001111111110011001010111110010101010000101;

    reg [127:0] received_result;
    integer i;

    initial begin
        // Инициализация
        aresetn = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        received_result = 128'b0;

        // Сброс DUT
        #10 aresetn = 1;

        // Подать 640 бит с паузой, учитывая valid и tready
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            s_axis_tdata = input_vector[639 - i];
            s_axis_tvalid = 1;
            s_axis_tlast = (i == 639);
            // Ждём готовности принять бит
            while (!s_axis_tready) @(posedge aclk);
        end

        @(posedge aclk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;

        // Получение 128-битного результата
        i = 0;
        received_result = 128'b0;
        while (i < 128) begin
            @(posedge aclk);
            if (m_axis_tvalid && m_axis_tready) begin
                received_result[127 - i] = m_axis_tdata;
                i = i + 1;
            end
        end

        // Проверка результата
        $display("Полученный результат: %b", received_result);
        $display("Эталонный результат: %b", expected_result_bits);
        if (received_result === expected_result_bits)
            $display("Результат совпадает!");
        else
            $display("Результат НЕ совпадает!");

        $finish;
    end

endmodule
