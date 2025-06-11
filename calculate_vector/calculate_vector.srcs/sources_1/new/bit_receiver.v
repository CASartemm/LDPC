module bit_receiver (
    input wire aclk,
    input wire aresetn,
    
    // AXI Stream Slave интерфейс для входной последовательности
    input wire s_axis_tdata,      // 1 бит данных
    input wire s_axis_tvalid,     // Данные валидны
    output reg s_axis_tready,     // Готовность принять
    input wire s_axis_tlast,      // Последний бит
    
    // AXI Stream Master интерфейс для выходной последовательности
    output reg m_axis_tdata,      // 1 бит данных
    output reg m_axis_tvalid,     // Данные валидны
    input wire m_axis_tready,     // Приемник готов
    output reg m_axis_tlast,      // Последний бит
    
    // Выход для отладки (опционально)
    output reg [31:0] bit_count_out  // Счетчик принятых битов
);

    reg [31:0] bit_counter;  // Счетчик принятых битов
    reg next_ready;         // Следующее значение готовности

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_tready <= 1;   // Изначально готов принимать данные
            m_axis_tvalid <= 0;   // Выходные данные не валидны
            m_axis_tdata <= 0;    // Очищаем данные
            m_axis_tlast <= 0;    // Сбрасываем флаг последнего бита
            bit_counter <= 0;     // Сбрасываем счетчик
            bit_count_out <= 0;   // Сбрасываем выходной счетчик
            next_ready <= 1;      // Изначально готовы к следующему приему
        end else begin
            // Обновляем готовность к приему
            s_axis_tready <= next_ready;
            
            // Обрабатываем входные данные
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata <= s_axis_tdata;    // Передаем бит данных
                m_axis_tvalid <= 1;              // Устанавливаем валидность
                m_axis_tlast <= s_axis_tlast;    // Передаем флаг последнего бита
                bit_counter <= bit_counter + 1;  // Увеличиваем счетчик
                bit_count_out <= bit_counter + 1;
                
                // Если это последний бит, готовимся к следующему потоку
                if (s_axis_tlast) begin
                    next_ready <= 1;  // Готовы принять новый поток
                end else begin
                    next_ready <= m_axis_tready;  // Зависим от готовности приемника
                end
            end else begin
                m_axis_tvalid <= 0;  // Если данные не приняты, сбрасываем валидность
                next_ready <= m_axis_tready;  // Обновляем готовность к следующему приему
            end
        end
    end
endmodule