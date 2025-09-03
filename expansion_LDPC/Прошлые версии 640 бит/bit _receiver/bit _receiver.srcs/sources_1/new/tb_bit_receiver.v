module tb_bit_receiver;     // передача и прием параллельны , за 1 такт передается 1 бит , при ready=0 передача останавливается 
    reg aclk, aresetn;
    reg s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;
    wire m_axis_tdata, m_axis_tvalid, m_axis_tlast;
    reg m_axis_tready;

    reg [0:0] bit_sequence [0:639];  // Массив для загрузки из файла
    reg [0:0] received_bits [0:639]; // Массив для принятых битов
    integer i, received_count;

    bit_receiver dut (
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
        forever #5 aclk = ~aclk;  // Частота 100 МГц
    end

    // Логика тестбенча
    initial begin
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;  // Готов принимать данные с самого начала
        received_count = 0;
        #20 aresetn = 1;

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

        // Ждем завершения приема всех данных
        wait (received_count == 640);
        // Проверка данных
        for (i = 0; i < 640; i = i + 1) begin
            if (received_bits[i] != bit_sequence[i]) begin
                $display("Error: mismatch at bit %d", i);
            end
        end
        $display("Simulation finished");
        $finish;
    end

    // Прием данных от модуля
    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            received_bits[received_count] = m_axis_tdata;
            received_count = received_count + 1;
        end
    end
endmodule