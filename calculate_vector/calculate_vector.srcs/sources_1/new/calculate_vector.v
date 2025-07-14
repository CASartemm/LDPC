`timescale 1ns / 1ps
// Основной модуль . основные расчеты 
module calculate_vector (
    input  wire         aclk,          // Тактовый сигнал - это как сердце модуля, задаёт ритм работы
    input  wire         aresetn,       // Сигнал сброса - если 0, всё обнуляется и начинается заново
    // AXI Stream Slave - сюда приходят данные (640 бит по одному за такт)
    input  wire         s_axis_tdata,  // Входной бит - каждый такт приходит 1 бит данных
    input  wire         s_axis_tvalid, // Говорит, что входной бит готов и его можно взять
    output wire         s_axis_tready, // Говорит внешнему миру, что мы готовы принимать данные
    input  wire         s_axis_tlast,  // Показывает, что это последний бит из 640
    // AXI Stream Master - отсюда уходят данные (128 бит по одному за такт)
    output wire         m_axis_tdata,  // Выходной бит - каждый такт выдаём 1 бит результата
    output wire         m_axis_tvalid, // Говорит, что выходной бит готов и его можно забрать
    input  wire         m_axis_tready, // Говорит нам, что внешний мир готов взять наш бит
    output wire         m_axis_tlast   // Показывает, что это последний бит из 128
);

    // Сигналы для общения с подмодулем bit_receiver
    wire        br_m_axis_tdata;       // Бит, который мы получили от bit_receiver
    wire        br_m_axis_tvalid;      // Говорит, что бит от bit_receiver готов
    wire        br_m_axis_tlast;       // Говорит, что это последний бит от bit_receiver
    wire        br_s_axis_tready;      // Показывает, готов ли bit_receiver принимать данные
    reg         int_m_axis_tready;     // Наш сигнал, чтобы сказать bit_receiver, готовы ли мы взять бит

    // Сигналы для общения с подмодулем shift_register_processor
    wire [127:0] out_row;              // Строка из 128 бит, которую даёт shift_register_processor
    wire         valid;                // Говорит, что строка от shift_register_processor готова
    wire         en = br_m_axis_tvalid;// Включает shift_register_processor, когда есть данные

    // Наши внутренние "переменные" (регистры)
    reg [127:0]  acc;                  // Аккумулятор - сюда складываем результат вычислений
    reg [6:0]    bit_index;            // Счётчик для передачи: какой бит из 128 мы сейчас выдаём (0-127)
    reg [9:0]    buffer_index;         // Счётчик для приёма: какой бит из 640 мы приняли (0-639)
    reg [127:0]  result;               // Готовый результат, который будем выдавать
    reg          is_transmitting;      // Флаг: если 1, значит, сейчас выдаём результат
    reg          m_axis_tvalid_reg;    // Регистр, чтобы управлять сигналом готовности выхода

    // Сигнал сброса для shift_register_processor
    wire srp_rst = ~aresetn | (is_transmitting && bit_index == 0); // Сбрасываем его при общем сбросе или начале передачи

    // Переворачиваем строку out_row, чтобы получить reversed_out_row
    reg [127:0] reversed_out_row;      // Строка из shift_register_processor, но задом наперёд
    integer rev_i;                     // Счётчик для цикла
    always @(*) begin                  // Это работает мгновенно, без ожидания такта
        for (rev_i = 0; rev_i < 128; rev_i = rev_i + 1) begin
            reversed_out_row[rev_i] = out_row[127 - rev_i]; // Берём биты с конца
        end
    end

    // Подключаем подмодули
    bit_receiver bit_rx (              // Модуль, который просто передаёт биты от входа к нам
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(br_s_axis_tready),
        .s_axis_tlast (s_axis_tlast),
        .m_axis_tdata (br_m_axis_tdata),
        .m_axis_tvalid(br_m_axis_tvalid),
        .m_axis_tready(int_m_axis_tready),
        .m_axis_tlast (br_m_axis_tlast)
    );

    shift_register_processor shift_reg_proc ( // Модуль, который выдаёт строки по одной за такт
        .clk     (aclk),
        .rst     (srp_rst),
        .en      (en),
        .out_row (out_row),
        .valid   (valid)
    );

    // Выходные сигналы - решаем, что выдавать наружу
    assign m_axis_tdata  = is_transmitting ? result[bit_index] : br_m_axis_tdata; // Если выдаём, берём бит из результата, иначе - от bit_receiver
    assign m_axis_tvalid = is_transmitting ? m_axis_tvalid_reg : br_m_axis_tvalid; // Если выдаём, используем наш регистр, иначе - от bit_receiver
    assign m_axis_tlast  = is_transmitting ? 1'b0 : br_m_axis_tlast; // br_m_axis_tlast, без условия на 128 бит
    assign s_axis_tready = is_transmitting ? 1'b0 : br_s_axis_tready; // Не принимаем данные, пока выдаём результат

    // Основная работа модуля
    always @(posedge aclk or negedge aresetn) begin // Срабатывает на каждый такт или сброс
        if (!aresetn) begin            // Если сброс, обнуляем всё
            int_m_axis_tready <= 1'b1; // Готовы принимать данные
            acc               <= 128'd0; // Обнуляем аккумулятор
            result            <= 128'd0; // Обнуляем результат
            bit_index         <= 7'd0;   // Сбрасываем счётчик битов
            buffer_index      <= 10'd0;  // Сбрасываем счётчик буфера
            is_transmitting   <= 1'b0;   // Не выдаём ничего
            m_axis_tvalid_reg <= 1'b0;   // Выход не готов
        end else begin                 // Если не сброс, работаем
            // Сбрасываем аккумулятор и результат в начале нового пакета
            if (buffer_index == 0 && !is_transmitting) begin
                acc    <= 128'd0;      // Начинаем вычисления с нуля
                result <= 128'd0;      // Готовим чистый результат
            end

            // Принимаем данные
            if (!is_transmitting && br_m_axis_tvalid && int_m_axis_tready) begin
                int_m_axis_tready <= 1'b1; // Продолжаем быть готовыми
                buffer_index      <= buffer_index + 1; // Считаем, сколько битов приняли
                if (br_m_axis_tdata) begin // Если пришёл бит 1
                    acc <= acc ^ reversed_out_row; // Добавляем строку к аккумулятору через XOR
                end
                // Если это последний бит пакета
                if (br_m_axis_tlast) begin
                    result          <= br_m_axis_tdata ? (acc ^ reversed_out_row) : acc; // Финальный результат
                    is_transmitting <= 1'b1; // Переключаемся на выдачу
                    buffer_index    <= 10'd0; // Сбрасываем счётчик приёма
                    bit_index       <= 7'd0;  // Сбрасываем счётчик выдачи
                    m_axis_tvalid_reg <= 1'b1; // Говорим, что выход готов
                    int_m_axis_tready <= 1'b0; // Больше не принимаем данные
                end
            end

            // Выдаём результат
            if (is_transmitting && m_axis_tvalid_reg && m_axis_tready) begin
                if (bit_index < 127) begin // Если не все биты выдали
                    bit_index <= bit_index + 1; // Переходим к следующему биту
                end else begin            // Если выдали последний бит
                    is_transmitting   <= 1'b0; // Заканчиваем выдачу
                    m_axis_tvalid_reg <= 1'b0; // Выход больше не готов
                    bit_index         <= 7'd0; // Сбрасываем счётчик
                    int_m_axis_tready <= 1'b1; // Готовы принимать новый пакет
                end
            end else if (is_transmitting && !m_axis_tvalid_reg && bit_index < 128) begin
                m_axis_tvalid_reg <= 1'b1; // Начинаем выдачу, если ещё не начали
            end
        end
    end

endmodule