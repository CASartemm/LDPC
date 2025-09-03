module calculate_vector (
    input wire aclk,              // Тактовый сигнал
    input wire aresetn,           // Сброс (активен низкий)
    
    // AXI Stream Slave интерфейс для входных данных
    input wire s_axis_tdata,      // Входной бит (1 бит)
    input wire s_axis_tvalid,     // Данные валидны
    output wire s_axis_tready,    // Готовность принимать данные
    input wire s_axis_tlast,      // Последний бит в последовательности
    
    // Выходной интерфейс
    output reg [127:0] result,    // 128-битный результат
    output reg result_valid       // Сигнал валидности результата
);

// Внутренние сигналы для связи с bit_receiver
wire m_axis_tdata;    // Выходной бит от bit_receiver
wire m_axis_tvalid;   // Валидность данных от bit_receiver
wire m_axis_tlast;    // Последний бит от bit_receiver
reg  m_axis_tready;   // Готовность принимать данные от bit_receiver

// Внутренние сигналы для связи с shift_register_processor
wire en = m_axis_tvalid; // Сигнал разрешения для shift_register_processor
wire [127:0] out_row; // Текущая строка матрицы (128 бит)
wire valid;           // Валидность строки

// Регистры для вычислений
reg [127:0] acc;      // Аккумулятор для операции XOR
reg done;             // Флаг завершения обработки

// Инстанцирование модуля bit_receiver
bit_receiver bit_rx (
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

// Инстанцирование shift_register_processor с новым сигналом en
    shift_register_processor shift_reg_proc (
        .clk(aclk),
        .rst(~aresetn),
        .en(en),           // Подключаем en к m_axis_tvalid
        .out_row(out_row),
        .valid(valid)
    );

// Логика обработки
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        // Сброс всех регистров при низком aresetn
        acc <= 128'b0;         // Обнуление аккумулятора
        done <= 0;             // Сброс флага завершения
        result_valid <= 0;     // Результат невалиден
        result <= 128'b0;      // Обнуление результата
        m_axis_tready <= 1'b1; // Всегда готов принимать данные
    end else begin
        // Обработка данных на каждом такте
        if (m_axis_tvalid && m_axis_tready) begin
            // Если бит валиден и модуль готов
            if (m_axis_tdata) begin
                // Если бит равен 1, выполнить XOR с текущей строкой
                acc <= acc ^ out_row;
            end
            if (m_axis_tlast) begin
                // Если пришел последний бит, установить флаг завершения
                done <= 1;
            end
        end
        
        // Вывод результата на следующем такте после завершения
        if (done) begin
            result <= acc;         // Записать аккумулятор в результат
            result_valid <= 1;     // Установить сигнал валидности
            done <= 0;             // Сбросить флаг
        end else begin
            result_valid <= 0;     // Сбросить сигнал валидности
        end
    end
end

endmodule