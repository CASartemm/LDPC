// Основной модуль . основные расчеты
module tdma_calculate_vector (
    input wire aclk,
    input wire aresetn,
    // AXI Stream Slave - сюда приходят данные (640 бит по одному за такт)
    input wire s_axis_tdata, // Входной бит - каждый такт приходит 1 бит данных
    input wire s_axis_tvalid, // Говорит, что входной бит готов и его можно взять
    output wire s_axis_tready, // Говорит внешнему миру, что мы готовы принимать данные
    input wire s_axis_tlast, // Показывает, что это последний бит из 640
    // AXI Stream Master - отсюда уходят данные (128 бит по одному за такт)
    output wire m_axis_tdata, // Выходной бит - каждый такт выдаём 1 бит результата
    output wire m_axis_tvalid, // Говорит, что выходной бит готов и его можно забрать
    input wire m_axis_tready, // Говорит нам, что внешний мир готов взять наш бит
    output wire m_axis_tlast // Показывает, что это последний бит из 128
);
    // Сигналы для общения с подмодулем shift_register_processor
    wire [127:0] out_row; // Строка из 128 бит, которую даёт shift_register_processor
    wire valid; // Говорит, что строка от shift_register_processor готова
    wire en = s_axis_tvalid && m_axis_tready;// Включает shift_register_processor, когда есть данные
    // Наши внутренние "переменные" (регистры)
    reg [127:0] acc; // Аккумулятор - сюда складываем результат вычислений
    reg [6:0] bit_index; // Счётчик для передачи: какой бит из 128 мы сейчас выдаём (0-127)
    reg [9:0] buffer_index; // Счётчик для приёма: какой бит из 640 мы приняли (0-639)
    reg [127:0] result; // Готовый результат, который будем выдавать
    reg is_transmitting; // Флаг: если 1, значит, сейчас выдаём результат
    reg reset_pulse; // Пульс сброса для shift_register_processor
    // Сигнал сброса для shift_register_processor
    wire srp_rst = ~aresetn | reset_pulse; // Сбрасываем при общем сбросе или пульсе
    // Подключаем подмодули

    tdma_shift_register_processor shift_reg_proc ( // Модуль, который выдаёт строки по одной за такт
        .clk (aclk),
        .rst (srp_rst),
        .en (en),
        .out_row (out_row),
        .valid (valid)
    );
    // Выходные сигналы - решаем, что выдавать наружу
    assign m_axis_tdata = is_transmitting ? result[127 - bit_index] : s_axis_tdata; // Если выдаём, берём бит из результата, иначе - от bit_receiver
    assign m_axis_tvalid = is_transmitting ? 1 : s_axis_tvalid; // Если выдаём, используем наш регистр, иначе - от bit_receiver
    assign m_axis_tlast = (is_transmitting && (bit_index == 127)); // Для передачи - на последнем бите
    assign s_axis_tready = is_transmitting ? 1'b0 : m_axis_tready; // Не принимаем данные, пока выдаём результат
    // Основная работа модуля
    always @(posedge aclk or negedge aresetn) begin // Срабатывает на каждый такт или сброс
        if (!aresetn) begin // Если сброс, обнуляем всё
            acc <= 128'd0; // Обнуляем аккумулятор
            result <= 128'd0; // Обнуляем результат
            bit_index <= 7'd0; // Сбрасываем счётчик битов
            buffer_index <= 10'd0; // Сбрасываем счётчик буфера
            is_transmitting <= 1'b0; // Не выдаём ничего
            reset_pulse <= 1'b1; // Пульс сброса
        end else begin // Если не сброс, работаем
            reset_pulse <= 1'b0; // По умолчанию снимаем пульс
            // Принимаем данные
            if (!is_transmitting && s_axis_tvalid && m_axis_tready) begin
                buffer_index <= buffer_index + 1; // Считаем, сколько битов приняли
                if (s_axis_tdata) begin // Если пришёл бит 1
                    acc <= acc ^ out_row; // Добавляем строку к аккумулятору через XOR
                end
                // Если это последний бит пакета
                if (s_axis_tlast) begin
                    result <= s_axis_tdata ? (acc ^ out_row) : acc; // Финальный результат
                    is_transmitting <= 1'b1; // Переключаемся на выдачу
                    buffer_index <= 10'd0; // Сбрасываем счётчик приёма
                    bit_index <= 7'd0; // Сбрасываем счётчик выдачи
                end
            end
            // Выдаём результат
            else if (is_transmitting && m_axis_tready) begin
                if (bit_index < 127) begin // Если не все биты выдали
                    bit_index <= bit_index + 1; // Переходим к следующему биту
                end else begin // Если выдали последний бит
                    is_transmitting <= 1'b0; // Заканчиваем выдачу
                    bit_index <= 7'd0; // Сбрасываем счётчик
                    acc <= 128'd0;
                    result <= 128'd0;
                    reset_pulse <= 1'b1; // Пульс сброса для следующего пакета
                end
            end
        end
    end
endmodule