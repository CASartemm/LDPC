module axi_stream_receiver (
    input wire clk,                // Тактовый сигнал
    input wire reset,              // Сигнал сброса
    input wire s_axis_tvalid,      // Входной сигнал валидности данных от AXI Stream
    output reg s_axis_tready,      // Выходной сигнал готовности к приему данных
    input wire s_axis_tdata,       // Входной бит данных (1 бит за такт)
    output reg [639:0] data_out,   // Выходные данные (640 бит)
    output reg data_valid          // Сигнал валидности выходных данных
);

    reg [9:0] bit_counter;         // Счетчик битов (до 640, т.е. 10 бит)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_counter <= 10'd0;  // Сброс счетчика
            data_out <= 640'd0;    // Сброс выходных данных
            data_valid <= 1'b0;    // Сброс сигнала валидности
            s_axis_tready <= 1'b1; // Готов к приему данных после сброса
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                // Сдвигаем бит в регистр
                data_out <= {data_out[638:0], s_axis_tdata};
                bit_counter <= bit_counter + 1'b1;

                // Когда собрано 640 бит, активируем data_valid
                if (bit_counter == 10'd639) begin
                    data_valid <= 1'b1;
                    bit_counter <= 10'd0; // Сбрасываем счетчик
                end else begin
                    data_valid <= 1'b0;
                end
            end else begin
                data_valid <= 1'b0; // Нет валидных данных, если не принимаем бит
            end
        end
    end

    // Логика управления s_axis_tready
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axis_tready <= 1'b1; // После сброса готов принимать данные
        end else begin
            // Модуль всегда готов принимать данные
            // При необходимости можно добавить логику для backpressure
            s_axis_tready <= 1'b1;
        end
    end

endmodule
