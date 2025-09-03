module axi_stream_master_tb;

    reg aclk;
    reg aresetn;
    wire m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire m_axis_tlast;

    // Инстанцируем модуль
    axi_stream_master dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Генерация тактового сигнала
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;  // Период 10 единиц времени
    end

    // Загрузка последовательности из файла и тестирование
    initial begin
        $readmemb("sequence.txt", dut.bit_sequence);  // Загружаем данные в массив
        aresetn = 0;
        m_axis_tready = 0;
        #20;
        aresetn = 1;
        #10;
        m_axis_tready = 1;  // Готовность принимать данные
        #6500;              // Ждём передачи всех 640 битов
        $finish;
    end

    // Отслеживание передачи данных
    integer bit_count = 0;  // Счётчик переданных битов

    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $display("Time: %0t, Transmitted bit: %b", $time, m_axis_tdata);
            bit_count = bit_count + 1;
            if (m_axis_tlast) begin
                if (bit_count == 640) begin
                    $display("All 640 bits transmitted successfully.");
                end else begin
                    $display("Error: Only %0d bits were transmitted.", bit_count);
                end
            end
        end
    end

endmodule