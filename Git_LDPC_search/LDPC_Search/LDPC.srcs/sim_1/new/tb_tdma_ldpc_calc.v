`timescale 1ns/1ps

module tb_LDPC;

    // ------------------ Такт и сброс ------------------
    reg aclk, aresetn;
    initial begin aclk=0; forever #5 aclk=~aclk; end

    // ------------------ Ключ выбора матрицы ------------------
    reg [3:0] slot_size;
    reg [3:0] slot_type;

    // ------------------ AXI Stream ------------------
    reg  s_axis_tdata;
    reg  s_axis_tvalid;
    reg  s_axis_tlast;
    wire s_axis_tready;

    wire m_axis_tdata;
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;

    // ------------------ DUT ------------------
    tdma_ldpc dut (
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

    // ------------------ Переменные ------------------
    integer fd;
    integer test_num, success_count, fail_count;
    integer bit_count, j;
  integer ok;
    // === Максимальные буферы (увеличьте при необходимости) ===
    localparam integer MAX_IN_BITS  = 4096;
    localparam integer MAX_OUT_BITS = 1024;

    // Универсальные буферы (индекс [0:N-1] как у вас)
    reg [0:MAX_IN_BITS-1]  bit_sequence_in;   // фактически N_IN
    reg [0:MAX_OUT_BITS-1] expected_out;      // фактически M_OUT
    reg [0:MAX_OUT_BITS-1] received_out;      // фактически M_OUT

    // Текущие размеры выбранной матрицы
    integer N_IN, M_OUT;

    // «Строки» 
    reg [8*256-1:0] infile;
    reg [8*256-1:0] default_infile;
    reg [8*128-1:0] cfg_name;

    // ------------------ Печать произвольной ширины вектора ------------------
    task show_vec;
        input [8*16-1:0] tag;                 // "RX " / "EXP"
        input [0:MAX_OUT_BITS-1] vec;         // фиксированная ширина
        input integer width;                  // сколько реально печатать
        integer t;
        begin
            $write("%0s: ", tag);
            for (t = width-1; t >= 0; t = t - 1)
                $write("%0d", vec[t]);
            $write("\n");
        end
    endtask

    // ------------------ Универсальная передача/приём/сравнение ------------------
    task send_and_check;
        begin
            // Передача N_IN бит во вход DUT
            for (j = 0; j < N_IN; j = j + 1) begin
                @(posedge aclk);
                while (!s_axis_tready) @(posedge aclk);
                s_axis_tdata  <= bit_sequence_in[j];
                s_axis_tvalid <= 1'b1;
                s_axis_tlast  <= (j == N_IN-1);
                @(posedge aclk);
                s_axis_tvalid <= 1'b0;
                s_axis_tlast  <= 1'b0;
            end

            // Приём M_OUT бит с выхода DUT
            bit_count   = 0;
            received_out = {MAX_OUT_BITS{1'b0}}; // обнуляем весь буфер константой

            while (bit_count < M_OUT) begin
                @(posedge aclk);
                if (m_axis_tvalid && m_axis_tready) begin
                    // MSB-first, как в вашем коде
                    received_out[M_OUT-1-bit_count] = m_axis_tdata;
                    bit_count = bit_count + 1;
                end
            end

            // Сравнение и лог
            if (received_out === expected_out) begin
                $display("OK   (%0s, N=%0d, M=%0d, slot_size=%0d, slot_type=%0d)",
                         cfg_name, N_IN, M_OUT, slot_size, slot_type);
                success_count = success_count + 1;
            end else begin
                $display("FAIL (%0s, N=%0d, M=%0d, slot_size=%0d, slot_type=%0d)",
                         cfg_name, N_IN, M_OUT, slot_size, slot_type);
                show_vec("RX ", received_out, M_OUT);
                show_vec("EXP", expected_out , M_OUT);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ------------------ Загрузка одного тест-вектора из файла ------------------
    // Формат: подряд N_IN входных бит затем M_OUT ожидаемых (символы '0'/'1'; \n и пробелы игнорируются)
    task load_one_vector;
        output integer ok;
        integer need, got, idx_in, idx_out;
        integer ch;
        reg eof_hit;
        begin
            need     = N_IN + M_OUT;
            got      = 0;
            idx_in   = 0;
            idx_out  = 0;
            eof_hit  = 0;

            // Очистим буферы на всякий случай
            bit_sequence_in = {MAX_IN_BITS{1'b0}};
            expected_out    = {MAX_OUT_BITS{1'b0}};

            while ((got < need) && !eof_hit) begin
                ch = $fgetc(fd);
                if (ch == -1) begin
                    eof_hit = 1;
                end else if (ch=="0" || ch=="1") begin
                    if (idx_in < N_IN) begin
                        bit_sequence_in[idx_in] = (ch=="1");
                        idx_in  = idx_in  + 1;
                    end else begin
                        // Заполняем expected_out в MSB-first (как в сравнении)
                        expected_out[M_OUT-1-idx_out] = (ch=="1");
                        idx_out = idx_out + 1;
                    end
                    got = got + 1;
                end
            end

            if (eof_hit && (got < need)) ok = 0; // не хватило на полный тест
            else                          ok = 1; // полный тест собран
        end
    endtask

    // ------------------ Таблица: выбор матрицы по slot_size/slot_type ------------------
    task select_matrix_by_slot;
        begin
            // Значения по умолчанию (на случай default)
            N_IN = 0; M_OUT = 0;
            cfg_name = "undefined";
            default_infile = "";

            case ({slot_size,slot_type})
                // ==== добавляйте свои пары ниже ====
                {4'd2,4'd3}: begin
                    N_IN=640;  M_OUT=128;
                    cfg_name=" 640x128 (t4)";
                    default_infile="c:/temp/sequence.txt";
                end
                
                 {4'd3,4'd1}: begin
                    N_IN=768;  M_OUT=384;
                    cfg_name="small 768x384 (t5)";
                    default_infile="c:/temp/Slot_size_3_Slot_type_2.3.txt";
                end
               ////
                  {4'd6,4'd0}: begin
                    N_IN=1152;  M_OUT=1152;
                    cfg_name="small 1152x1152 (t5)";
                    default_infile="c:/temp/Slot_size_6_Slot_type_1.2.txt";
                end
               
               {4'd6,4'd3}: begin
                    N_IN=1920;  M_OUT=384;
                    cfg_name="small 1920x384 (t5)";
                    default_infile="c:/temp/Slot_size_6_Slot_type_4.txt";
                end
               
               {4'd6,4'd1}: begin
                    N_IN=1536;  M_OUT=768;
                    cfg_name="small 1536x768 (t5)";
                    default_infile="c:/temp/Slot_size_6_Slot_type_2.3.txt";
                end
               
               
                 {4'd6,4'd2}: begin
                    N_IN=1728;  M_OUT=576;
                    cfg_name="small 1728x576 (t5)";
                    default_infile="c:/temp/Slot_size_6_Slot_type_3.4.txt";
                end
               
                    {4'd4,4'd0}: begin
                    N_IN=768;  M_OUT=768;
                    cfg_name="small 768x768 (t5)";
                    default_infile="c:/temp/Slot_size_4_Slot_type_1.2.txt";
                end
              
              {4'd4,4'd1}: begin
                    N_IN=1024;  M_OUT=512;
                    cfg_name="small 1024x512 (t5)";
                    default_infile="c:/temp/Slot_size_4_Slot_type_3.4.txt";
                end
              
              
                  {4'd4,4'd2}: begin
                    N_IN=1152;  M_OUT=384;
                    cfg_name="small 1152x384 (t5)";
                    default_infile="c:/temp/Slot_size_4_Slot_type_3.txt";
                end
               
               
               
                {4'd4,4'd3}: begin
                    N_IN=1280;  M_OUT=256;
                    cfg_name="small 1280x256 (t5)";
                    default_infile="c:/temp/Slot_size_4_Slot_type_4.txt";
                end
               
                  {4'd3,4'd0}: begin
                    N_IN=576;  M_OUT=576;
                    cfg_name="small 576x576 (t5)";
                    default_infile="c:/temp/Slot_size_3_Slot_type_1.txt";
                end
               
                {4'd3,4'd2}: begin
                    N_IN=864;  M_OUT=288;
                    cfg_name="small 864x288 (t5)";
                    default_infile="c:/temp/Slot_size_3_Slot_type_3.4.txt";
                end
                
               
                {4'd2,4'd2}: begin
                    N_IN=576;  M_OUT=192;
                    cfg_name="small 576x192 (t5)";
                    default_infile="c:/temp/Slot_size_2_Slot_type_3.txt";
                end
                
                        {4'd2,4'd0}: begin
                    N_IN=384;  M_OUT=384;
                    cfg_name="small 384x384 (t5)";
                    default_infile="c:/temp/Slot_size_2_Slot_type_1.2.txt";
                end
                
                
                {4'd3,4'd3}: begin
                    N_IN=960;  M_OUT=192;
                    cfg_name="small 960x192 (t5)";
                    default_infile="c:/temp/modified_data_slot_size_3_slot_type_4.txt";
                end
                
                
                
                {4'd8,4'd1}: begin
                    N_IN=2048;  M_OUT=1024;
                    cfg_name=" 2048x1024 (t6)";
                    default_infile="c:/temp/2048+1024_FEC_2.3_Slot_size_8.txt";
                end
                    {4'd2,4'd1}: begin
                    N_IN=512;  M_OUT=256;
                    cfg_name=" 512x256 (t6)";
                    default_infile="c:/temp/512+256_Fec_2.3_Slot_size_2.txt";
                end
//                {4'd7,4'd1}: begin
                    {4'd8,4'd3}: begin
                    N_IN=2560; M_OUT=512;
                    cfg_name="2560x512";
                    default_infile="c:/temp/sequence_2560x512_fec_5.6_slot_8.txt";
                end
                // -----------------------------------
                default: begin
                    $display("Неизвестная комбинация slot_size=%0d slot_type=%0d",
                             slot_size, slot_type);
                end
            endcase
        end
    endtask

    // ------------------ Главный сценарий ------------------
    initial begin
      

        // Инициализация
        aresetn        = 0;
        s_axis_tvalid  = 0;
        s_axis_tlast   = 0;
        m_axis_tready  = 1;
        test_num       = 0;
        success_count  = 0;
        fail_count     = 0;

        // Значения slot_size/slot_type (можно переопределить плюс-аргами)
                        if (!$value$plusargs("SLOT_SIZE=%d", slot_size)) slot_size = 4'd6;
                        if (!$value$plusargs("SLOT_TYPE=%d", slot_type)) slot_type = 4'd0; //(fec)
            
        // Выбор матрицы по паре slot_size/slot_type
        select_matrix_by_slot();
        if (N_IN==0 || M_OUT==0) begin
            $display("Нет конфигурации для slot_size=%0d slot_type=%0d - останов.",
                     slot_size, slot_type);
            $finish;
        end

        // Путь к файлу: +INFILE имеет приоритет, иначе дефолт из таблицы
        if (!$value$plusargs("INFILE=%s", infile)) infile = default_infile;

        // Сброс DUT
        #20 aresetn = 1;

        // Открытие файла
        fd = $fopen(infile, "rb");
        if (fd == 0) begin
            $display("Ошибка: не удалось открыть файл %s", infile);
            $finish;
        end
        $display("Матрица: %0s, N=%0d, M=%0d, slot_size=%0d, slot_type=%0d",
                  cfg_name, N_IN, M_OUT, slot_size, slot_type);
        $display("Файл: %s", infile);

        // Читаем и выполняем тесты, пока хватает бит на полный вектор
        forever begin
            load_one_vector(ok);
            if (!ok) begin
                $display("\nВсе тесты завершены.");
                $display("Итого: успешных = %0d, ошибок = %0d, всего = %0d",
                          success_count, fail_count, test_num);
                $fclose(fd);
                $finish;
            end
            test_num = test_num + 1;
            $display("\n=== Тест %0d ===", test_num);
            send_and_check();
            
         

        end
    end
    
    
//always @(dut.shift[2879:2752]) begin
//  $display("%t shift[2879:2752] = %032h", $time, dut.shift[2879:2752]);
//end


endmodule
