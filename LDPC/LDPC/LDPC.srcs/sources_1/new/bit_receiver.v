//Сквозной модуль , принимает биты с тестбентча и передает в calculate_vector
module bit_receiver (
    input wire aclk,              // Тактовый сигнал
    input wire aresetn,           // Активный низкий сброс
    
    // AXI Stream Slave: интерфейс для входной последовательности
    input wire s_axis_tdata,      // 1-битные данные входа
    input wire s_axis_tvalid,     // Данные валидны (готовы к передаче)
    output reg s_axis_tready,     // Готовность модуля принять данные
    input wire s_axis_tlast,      // Флаг последнего бита в пакете
    
    // AXI Stream Master: интерфейс для выходной последовательности
    output reg m_axis_tdata,      // 1-битные данные выхода
    output reg m_axis_tvalid,     // Данные валидны (готовы к передаче)
    input wire m_axis_tready,     // Готовность приемника принять данные
    output reg m_axis_tlast       // Флаг последнего бита в пакете
);

// Основной always-блок: реагирует на такт или сброс
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        // Инициализация при сбросе:
        s_axis_tready <= 1'b1;  // Модуль изначально готов принимать данные
        m_axis_tvalid <= 1'b0;  // Выходные данные не валидны
        m_axis_tdata  <= 1'b0;  // Очищаем выходные данные
        m_axis_tlast  <= 1'b0;  // Сбрасываем флаг последнего бита
    end else begin
        // По умолчанию: выходные данные не валидны, если нет передачи
        m_axis_tvalid <= 1'b0;
        m_axis_tlast  <= 1'b0;  //  сброс по умолчанию, чтобы не залипал
        
        // Обработка входных данных, если они валидны и модуль готов
        if (s_axis_tvalid && s_axis_tready) begin
            // Прямая передача данных:
            m_axis_tdata  <= s_axis_tdata;  // Передаем бит данных на выход
            m_axis_tvalid <= 1'b1;          // Устанавливаем валидность выхода
            m_axis_tlast  <= s_axis_tlast;  // Передаем флаг последнего бита (override)
            
            // Обновление готовности для следующего цикла:
            // Если это последний бит, готовимся к новому пакету
            // Иначе, зависим от готовности приемника (backpressure)
            s_axis_tready <= s_axis_tlast ? 1'b1 : m_axis_tready;
        end else begin
            // Если данных нет или не готовы: применяем backpressure
            // Готовность модуля зависит от готовности приемника
            s_axis_tready <= m_axis_tready;
        end
    end
end
endmodule