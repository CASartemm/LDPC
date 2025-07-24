module scrambler (
    input clk,
    input rst,               
    input s_axis_tvalid,     // Входной сигнал, данные готовы
    output s_axis_tready,    // Сигнал готовности принимать данные
    input s_axis_tdata,      // Входные данные
    input s_axis_tlast,      // Метка последнего бита данных
    output reg m_axis_tvalid,// Сигнал, что выходные данные готовы
    input m_axis_tready,     // Сигнал готовности внешнего устройства
    output reg m_axis_tdata, // Выходные данные
    output reg m_axis_tlast  // Метка последнего бита на выходе
);

reg separation = 0;                           // Переключатель четный/нечетный
reg [14:0] shift_reg_a = 15'b100101010101111; // Регистр А для четных данных
reg [14:0] shift_reg_b = 15'b000111000111000; // Регистр B для нечетных данных
reg [9:0] bit_counter = 0;                    // Счетчик битов (10 бит для счета до 768) используется для m_axis_tlast 

assign s_axis_tready = m_axis_tready || !m_axis_tvalid; // Модуль готов принимать данные, если преведущий модуль готов или нет данных на выходе
                                                        
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        m_axis_tvalid <= 0;     // Сбрасываем сигнал готовности выходных данных
        m_axis_tdata <= 0;      // Сбрасываем выходные данные
        m_axis_tlast <= 0;      // Сбрасываем метку последнего бита
        separation <= 0;        // Сбрасываем переключатель четный/нечетный
        bit_counter <= 0;       // Сбрасываем счетчик битов
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin // Если есть входные данные и устройство готово
            if (!separation) begin  // Четный случай
                m_axis_tdata <= s_axis_tdata ^ (shift_reg_a[2] ^ shift_reg_a[0]);      // xor битов 0 и 2 , после xor с битом входным (0 и 2 из за индексации , чтение регистра идет справа налево)
                shift_reg_a <= {(shift_reg_a[2] ^ shift_reg_a[0]), shift_reg_a[14:1]}; // Сдвигаем регистр B 
            end else begin  // Нечетный случай
                m_axis_tdata <= s_axis_tdata ^ (shift_reg_b[2] ^ shift_reg_b[0]); // Скремблируем данные с регистром B (биты 0 и 2 для обратной связи)
                shift_reg_b <= {(shift_reg_b[2] ^ shift_reg_b[0]), shift_reg_b[14:1]}; // Сдвигаем регистр B  
            end
            bit_counter <= bit_counter + 1; // Увеличиваем счетчик битов
            m_axis_tlast <= (bit_counter == 767); // Устанавливаем tlast, когда выдано 768 битов
            m_axis_tvalid <= 1;           // Устанавливаем, что выходные данные готовы               
            separation <= ~separation;    // Переключаем четный/нечетный
        end else if (m_axis_tready && m_axis_tvalid) begin // Если внешнее устройство готово и есть выходные данные
            m_axis_tvalid <= 0; // Сбрасываем сигнал готовности выходных данных
            if (m_axis_tlast) begin //если m_axis_tlast =1 то регистры сбрасываются в начальное состояние 
                separation <= 0;
                shift_reg_a <= 15'b100101010101111;
                shift_reg_b <= 15'b000111000111000;
                bit_counter <= 0; // Сбрасываем счетчик битов после tlast
            end
        end
    end
end

endmodule