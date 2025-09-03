module axi_stream_master (
    input wire aclk,                // Тактовый сигнал
    input wire aresetn,             // Асинхронный сброс (активный низкий)
    
    // Входной интерфейс AXI Stream
    input wire s_axis_tdata,        // 1 бит данных
    input wire s_axis_tvalid,       // Валидность входных данных
    output reg s_axis_tready,       // Готовность принимать данные
    input wire s_axis_tlast,        // Сигнал конца пакета (не используется)
    
    // Выходной интерфейс AXI Stream
    output reg m_axis_tdata,        // 1 бит данных
    output reg m_axis_tvalid,       // Валидность выходных данных
    input wire m_axis_tready,       // Готовность приемника
    output reg m_axis_tlast         // Сигнал конца пакета (устанавливается для 640-го бита)
);

    // FIFO буфер: 640 элементов, каждый содержит tdata
    reg [0:0] fifo [0:639];         // Только tdata, так как tlast управляется отдельно
    reg [9:0] write_ptr;            // Указатель записи (10 бит для 0-639)
    reg [9:0] read_ptr;             // Указатель чтения (10 бит для 0-639)
    reg [9:0] count;                // Счетчик заполненности (0-640)
    reg [9:0] packet_counter;       // Счетчик переданных битов в пакете (0-639)

    // Основной процесс
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Сброс состояния
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
            packet_counter <= 0;
            s_axis_tready <= 1;     // Готов принимать данные
            m_axis_tvalid <= 0;     // Нет данных для передачи
            m_axis_tdata <= 0;
            m_axis_tlast <= 0;
        end else begin
            // Прием данных
            if (s_axis_tvalid && s_axis_tready) begin
                if (count < 640) begin
                    fifo[write_ptr] <= s_axis_tdata; // Запись данных
                    write_ptr <= (write_ptr == 639) ? 0 : write_ptr + 1; // Циклическое увеличение
                    count <= count + 1;   // Увеличение счетчика
                end
            end

            // Передача данных
            if (m_axis_tready && count > 0) begin
                m_axis_tdata <= fifo[read_ptr]; // Чтение данных
                m_axis_tlast <= (packet_counter == 639); // Устанавливаем tlast для 640-го бита
                read_ptr <= (read_ptr == 639) ? 0 : read_ptr + 1; // Циклическое увеличение
                count <= count - 1;   // Уменьшение счетчика
                packet_counter <= (packet_counter == 639) ? 0 : packet_counter + 1; // Сброс счетчика пакета
            end else begin
                m_axis_tlast <= 0; // Сбрасываем tlast, если не передаем данные
            end

            // Управление сигналами готовности
            s_axis_tready <= (count < 640); // Готов принимать, если буфер не полон
            m_axis_tvalid <= (count > 0);   // Данные валидны, если буфер не пуст
        end
    end
endmodule