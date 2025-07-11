`timescale 1ns / 1ps

module calculate_vector (
    input  wire         aclk,          // Тактовый сигнал
    input  wire         aresetn,       // Сигнал сброса (активный низкий уровень)

    // AXI Stream Slave (вход 640 бит)
    input  wire         s_axis_tdata,  // Входные данные (1 бит за такт)
    input  wire         s_axis_tvalid, // Сигнал валидности входных данных
    output wire         s_axis_tready, // Сигнал готовности модуля к приему данных
    input  wire         s_axis_tlast,  // Сигнал, обозначающий конец пакета данных

    // Выход 128-битного результата
    output reg  [127:0] result,        // Итоговый 128-битный результат обработки данных

    // AXI Stream Master (выход 128 бит)
    output wire         m_axis_tdata,  // Выходные данные (1 бит за такт)
    output wire         m_axis_tvalid, // Сигнал валидности выходных данных
    input  wire         m_axis_tready, // Сигнал готовности внешнего устройства к приему данных
    output wire         m_axis_tlast   // Сигнал конца пакета выходных данных
);

    // Внутренние сигналы для подключения к модулю bit_receiver
    wire        br_m_axis_tdata;       // Выходные данные от bit_receiver (1 бит)
    wire        br_m_axis_tvalid;      // Сигнал валидности данных от bit_receiver
    wire        br_m_axis_tlast;       // Сигнал конца пакета от bit_receiver
    wire        br_s_axis_tready;      // Сигнал готовности bit_receiver к приему данных
    reg         int_m_axis_tready;     // Внутренний сигнал готовности к приему данных от bit_receiver

    // Внутренние сигналы для подключения к shift_register_processor
    wire [127:0] out_row;              // 128-битный выходной ряд от shift_register_processor
    wire         valid;                // Сигнал валидности данных от shift_register_processor
    wire         en = br_m_axis_tvalid;// Сигнал включения для shift_register_processor, связан с валидностью входных данных

    // Определение состояний конечного автомата (FSM)
    localparam RECEIVING    = 2'b00;   // Состояние приема данных
    localparam TRANSMITTING = 2'b01;   // Состояние передачи результата

    reg [1:0]    state;                // Текущее состояние конечного автомата
    reg [127:0]  acc;                  // Аккумулятор для промежуточного хранения результата обработки
    reg [6:0]    bit_index;            // Индекс текущего бита для передачи результата (до 127)
    reg [9:0]    buffer_index;         // Индекс для буфера входных данных (до 639)
    reg [639:0]  input_buffer;         // Буфер для хранения 640 бит входных данных

    // Сигнал сброса для shift_register_processor
    wire srp_rst = ~aresetn | (state == TRANSMITTING && bit_index == 0); // Сброс при низком aresetn или в начале передачи

    // Подключение модуля bit_receiver для приема 640 бит данных
    bit_receiver bit_rx (
        .aclk         (aclk),          // Тактовый сигнал
        .aresetn      (aresetn),       // Сигнал сброса
        .s_axis_tdata (s_axis_tdata),  // Входные данные от AXI Stream Slave
        .s_axis_tvalid(s_axis_tvalid), // Валидность входных данных
        .s_axis_tready(br_s_axis_tready), // Готовность bit_receiver к приему
        .s_axis_tlast (s_axis_tlast),  // Сигнал конца пакета
        .m_axis_tdata (br_m_axis_tdata), // Выходные данные bit_receiver
        .m_axis_tvalid(br_m_axis_tvalid), // Валидность выходных данных
        .m_axis_tready(int_m_axis_tready), // Готовность к приему внутри модуля
        .m_axis_tlast (br_m_axis_tlast)   // Сигнал конца пакета
    );

    // Подключение модуля shift_register_processor для обработки данных
    shift_register_processor shift_reg_proc (
        .clk     (aclk),               // Тактовый сигнал
        .rst     (srp_rst),            // Сигнал сброса
        .en      (en),                 // Сигнал включения обработки
        .out_row (out_row),            // Выходной 128-битный ряд
        .valid   (valid)               // Сигнал валидности результата
    );

    // Логика формирования сигналов AXI Stream Master
    reg m_axis_tvalid_reg;             // Регистр для управления сигналом m_axis_tvalid
    assign m_axis_tdata  = (state == RECEIVING) ? br_m_axis_tdata : result[bit_index]; // Выбор между данными от bit_receiver и битом результата
    assign m_axis_tvalid = (state == RECEIVING) ? br_m_axis_tvalid : m_axis_tvalid_reg; // Валидность зависит от состояния
    assign m_axis_tlast  = (state == RECEIVING) ? br_m_axis_tlast : (bit_index == 127 && m_axis_tvalid_reg && m_axis_tready); // Конец пакета

    // Логика сигнала s_axis_tready
    assign s_axis_tready = (state == RECEIVING) ? br_s_axis_tready : 1'b0; // Готовность к приему только в состоянии RECEIVING

    // Конечный автомат для управления приемом и передачей данных
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin            // Асинхронный сброс при низком aresetn
            state        <= RECEIVING; // Начальное состояние - прием данных
            int_m_axis_tready <= 1'b1; // Модуль готов принимать данные
            acc          <= 128'd0;    // Сброс аккумулятора
            result       <= 128'd0;    // Сброс результата
            bit_index    <= 7'd0;      // Сброс индекса битов
            buffer_index <= 10'd0;     // Сброс индекса буфера
            input_buffer <= 640'd0;    // Сброс буфера
            m_axis_tvalid_reg <= 0;    // Выходные данные не валидны
        end else begin
            case (state)
                RECEIVING: begin       // Состояние приема данных
                    int_m_axis_tready <= 1'b1; // Готовность к приему от bit_receiver
                    m_axis_tvalid_reg <= 0;    // Выходные данные не валидны
                    if (buffer_index == 0) begin // При начале нового пакета
                        acc <= 128'd0;     // Сброс аккумулятора
                        result <= 128'd0;  // Сброс результата
                    end
                    if (br_m_axis_tvalid && int_m_axis_tready) begin // Если данные валидны и модуль готов
                        input_buffer[buffer_index] <= br_m_axis_tdata; // Запись бита в буфер
                        buffer_index <= buffer_index + 1; // Увеличение индекса буфера
                        if (br_m_axis_tdata)      // Если входной бит равен 1
                            acc <= acc ^ out_row; // Выполнение операции XOR с выходом shift_register_processor
                        if (br_m_axis_tlast) begin // Если получен последний бит пакета
                            result <= br_m_axis_tdata ? (acc ^ out_row) : acc; // Формирование окончательного результата
                            state        <= TRANSMITTING; // Переход в состояние передачи
                            bit_index    <= 7'd0; // Сброс индекса битов
                            buffer_index <= 10'd0; // Сброс индекса буфера
                            m_axis_tvalid_reg <= 1; // Готовность к передаче первого бита результата
                        end
                    end
                end
                TRANSMITTING: begin    // Состояние передачи результата
                    int_m_axis_tready <= 0; // Остановка приема новых данных во время передачи
                    if (m_axis_tvalid_reg && m_axis_tready) begin // Если данные валидны и внешнее устройство готово
                        if (bit_index < 127) begin // Если не все биты переданы
                            bit_index <= bit_index + 1; // Увеличение индекса битов
                        end else begin         // Если передан последний бит
                            m_axis_tvalid_reg <= 0; // Передача завершена
                            state <= RECEIVING; // Возврат в состояние приема
                            bit_index <= 0;     // Сброс индекса битов
                        end
                    end else if (!m_axis_tvalid_reg && bit_index < 128) begin // Если данные еще не переданы
                        m_axis_tvalid_reg <= 1; // Готовность к передаче следующего бита
                    end
                end
            endcase
        end
    end

endmodule