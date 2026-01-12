// LDPC: Топ-модуль - обертка для calculate_vector. Только основные пины как порты.

module tdma_ldpc (
    input  wire aclk,             // Вход: тактовый сигнал (clock)
    input  wire aresetn,          // Вход: сигнал сброса 
    input  wire s_axis_tdata,     // Вход: 1-битные данные по AXI-Stream
    input  wire s_axis_tvalid,    // Вход: валидность входных данных
    input  wire s_axis_tlast,     // Вход: последний пакет входных данных
    output wire s_axis_tready,    // Выход: готовность приема входных данных
    
    output wire m_axis_tdata,     // Выход: 1-битные выходные данные по AXI-Stream
    output wire m_axis_tvalid,    // Выход: валидность выходных данных
    input  wire m_axis_tready,    // Вход: готовность приема выходных данных
    output wire m_axis_tlast,      // Выход: последний пакет выходных данных
    
    input wire [3:0] slot_size,
    input wire [3:0] slot_type
);

// Инстанс DUT (calculate_vector) - подключаем все порты напрямую.
tdma_ldpc_calc dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .slot_size(slot_size),
    .slot_type(slot_type)
);

endmodule

// Модуль bit_receiver принимает биты из calculate_vector, 1 бит за 1 такт и возвращает  в calculate_vector уже как br_m_axis_tdata ,
//br_m_axis_tdata уже участвует в умножении строки из матрицы .
//модуль создан для удобства чередования  выдачи 640 бит и 128 бит. 

//Модуль shift_register_processor генерирует 640 строк матрицы Pg из 20 базовых (по 128 бит) путём циклических сдвигов (32 раза на каждую).
// Загружает строки из файла , выдаёт по одной строке за такт при en=1 , по сигналу out_row передает в calculate_vector для умножения 

//Модуль calculate_vector выполняет накопление и расчеты ,
// через мультиплексор по состоянию is_transmitting = 0 выдает 640 бит через сигнал br_m_axis_tdata,
// по состоянию is_transmitting = 1 выдает 128 бит через сигнал m_axis_tdata . 