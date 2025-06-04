`timescale 1ns / 1ps

module calculate_vector (
    input  wire         aclk,          // Тактовый сигнал
    input  wire         aresetn,       // Сброс (активен низкий)

    // AXI Stream Slave (приём 640 бит по одному)
    input  wire         s_axis_tdata,  // Входной бит (1 бит)
    input  wire         s_axis_tvalid, // Валидность входного бита
    output wire         s_axis_tready, // Готовность принять входной бит
    input  wire         s_axis_tlast,  // Флаг последнего входного бита

    // ??????? ЭКСПОРТИРУЕМ 128-БИТНЫЙ ВЕКТОР «result» ???????
    output reg  [127:0] result,        // Выходной порт: весь 128-битный результат
    // ??????????????????????????????????????????????????????

    // AXI Stream Master (выдача 128 бит побитно)
    output wire         m_axis_tdata,  // Выходной бит (1 бит)
    output wire         m_axis_tvalid, // Валидность выходного бита
    input  wire         m_axis_tready, // Приёмник готов
    output wire         m_axis_tlast   // Флаг последнего выходного бита
);

    // ================= ВНУТРЕННИЕ СИГНАЛЫ =================
    // Связь с bit_receiver (приём первых 640 бит)
    wire        br_m_axis_tdata;    // Бит от bit_receiver
    wire        br_m_axis_tvalid;   // Валиден ли этот бит
    wire        br_m_axis_tlast;    // Флаг конца 640-битного потока
    reg         int_m_axis_tready;  // Мы готовы принять очередной бит

    // Связь с shift_register_processor
    wire [127:0] out_row;  // «Строка» (128 бит) на входе XOR
    wire         valid;    // Валидность out_row
    wire         en = br_m_axis_tvalid; // Каждый раз, когда есть бит, включаем shift

    // FSM и регистры
    reg [127:0]  acc;       // Аккумулятор XOR (128 бит)
    reg [6:0]    bit_index; // Счётчик при отдаче 128 бит (0..127)
    reg          state;     // FSM: RECEIVING или TRANSMITTING
    reg          prev_state;

    localparam RECEIVING    = 1'b0;
    localparam TRANSMITTING = 1'b1;

    // При переходе из RECEIVING ? TRANSMITTING надо сбросить shift
    wire srp_rst = ~aresetn | (state == TRANSMITTING && prev_state == RECEIVING);

    // ================ ПОДМОДУЛИ =================
    // 1) bit_receiver: принимает 640 бит по s_axis_* и выдаёт их через br_m_axis_*
    bit_receiver bit_rx (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast),
        .m_axis_tdata (br_m_axis_tdata),
        .m_axis_tvalid(br_m_axis_tvalid),
        .m_axis_tready(int_m_axis_tready),
        .m_axis_tlast (br_m_axis_tlast)
    );

    // 2) shift_register_processor: при en=1 генерирует 128-битную строку out_row
    shift_register_processor shift_reg_proc (
        .clk     (aclk),
        .rst     (srp_rst),
        .en      (en),
        .out_row (out_row),
        .valid   (valid)
    );

    // ============= ВЫХОД m_axis_* =================
    // Если ещё в RECEIVING, передаём br_m_axis_tdata.
    // В TRANSMITTING выдаём по одному биту result[bit_index].
    assign m_axis_tdata  = (state == RECEIVING) ? br_m_axis_tdata
                         : result[bit_index];
    assign m_axis_tvalid = (state == RECEIVING) ? br_m_axis_tvalid
                         : 1'b1;
    assign m_axis_tlast  = (state == TRANSMITTING) && (bit_index == 127);

    // ==================== FSM ====================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Асинхронный сброс
            state             <= RECEIVING;
            prev_state        <= RECEIVING;
            int_m_axis_tready <= 1'b1;
            bit_index         <= 7'd0;
            acc               <= 128'd0;
            result            <= 128'd0;
        end else begin
            prev_state <= state;
            case (state)
                // ------------- RECEIVING -------------
                RECEIVING: begin
                    // ВСЕГДА готовы принимать биты от bit_receiver,
                    // даже если m_axis_tready == 0. 
                    // Это главное изменение: раньше стояло int_m_axis_tready <= m_axis_tready;
                    int_m_axis_tready <= 1'b1;
                    if (br_m_axis_tvalid && int_m_axis_tready) begin
                        // Если пришёл «1», то «xor» с текущей строкой
                        if (br_m_axis_tdata)
                            acc <= acc ^ out_row;
                        // Если этот бит был последним (640-й), формируем result
                        if (br_m_axis_tlast) begin
                            result            <= br_m_axis_tdata ? (acc ^ out_row) : acc;
                            acc               <= 128'd0;
                            state             <= TRANSMITTING;
                            bit_index         <= 7'd0;   // Сбрасываем счётчик перед передачей
                            int_m_axis_tready <= 1'b0;   // Не принимаем больше, пока передаём
                        end
                    end
                end

                // ------------ TRANSMITTING ------------
                TRANSMITTING: begin
                    // Теперь не принимаем новых бит из bit_receiver
                    int_m_axis_tready <= 1'b0;
                    if (m_axis_tvalid && m_axis_tready) begin
                        if (bit_index < 7'd127) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            // Отдали все 128 бит ? возвращаемся в RECEIVING
                            state     <= RECEIVING;
                            bit_index <= 7'd0;  // Сброс для следующего раза
                        end
                    end
                end

            endcase
        end
    end

endmodule
