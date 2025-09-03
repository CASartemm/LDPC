module top_module (
    input wire clk,               // Тактовый сигнал
    input wire rst,               // Сигнал сброса
    input wire s_axis_tdata,      // Входной бит от внешнего источника
    input wire s_axis_tvalid,     // Валидность входного бита
    output wire s_axis_tready,    // Готовность принимать данные
    input wire s_axis_tlast,      // Последний бит
    output wire [127:0] result,   // Результирующий 128-битный вектор
    output wire result_valid      // Валидность результата
);

    // Промежуточные сигналы между модулями
    wire m_axis_tdata;            // Бит от axi_stream_master
    wire m_axis_tvalid;           // Валидность бита
    wire m_axis_tready;           // Готовность принимать бит
    wire m_axis_tlast;            // Последний бит
    wire [127:0] out_row;         // Строка матрицы от shift_register_processor
    wire row_valid;               // Валидность строки

    // Экземпляр axi_stream_master
    axi_stream_master u_axi_stream_master (
        .aclk(clk),
        .aresetn(~rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Экземпляр shift_register_processor
    shift_register_processor u_shift_register_processor (
        .clk(clk),
        .rst(rst),
        .out_row(out_row),
        .valid(row_valid)
    );

    // Экземпляр matrix_vector_multiplier
    matrix_vector_multiplier u_matrix_vector_multiplier (
        .clk(clk),
        .rst(rst),
        .bit_in(m_axis_tdata),
        .bit_valid(m_axis_tvalid),
        .row_in(out_row),
        .row_valid(row_valid),
        .result(result),
        .result_valid(result_valid)
    );

    // Управление потоком данных
    assign m_axis_tready = row_valid;  // Принимаем бит, когда строка готова

endmodule

// Модуль для вычисления произведения матрицы на вектор
module matrix_vector_multiplier (
    input wire clk,
    input wire rst,
    input wire bit_in,         // Входной бит
    input wire bit_valid,      // Валидность бита
    input wire [127:0] row_in, // Входная строка матрицы
    input wire row_valid,      // Валидность строки
    output reg [127:0] result, // Результирующий вектор
    output reg result_valid    // Валидность результата
);

    reg [127:0] accumulator;   // Аккумулятор для XOR
    reg [9:0] count;           // Счётчик тактов (0-639)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accumulator <= 128'b0;
            count <= 10'b0;
            result_valid <= 1'b0;
        end else begin
            if (bit_valid && row_valid) begin
                if (bit_in) begin
                    accumulator <= accumulator ^ row_in;  // Накопление XOR
                end
                count <= count + 1;
                if (count == 639) begin
                    result <= accumulator;  // Выдача результата
                    result_valid <= 1'b1;
                    accumulator <= 128'b0;  // Сброс для следующего цикла
                    count <= 10'b0;
                end else begin
                    result_valid <= 1'b0;
                end
            end
        end
    end

endmodule