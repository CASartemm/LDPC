module tb_scrambler;  // �������� ������ ��������� ��� �������� ������ scrambler

    reg clk = 0;  // ������� ��� ������� �������� �������, ��������������� 0
    reg rst = 1;  // ������� ��� ������� ������, 1 - ���������� ������, 0 - �����
    reg s_axis_tvalid ;  // ������� ��� ���������� ������� ������, 0 - ������ �� �������
    wire s_axis_tready;  // ������ ��� ������� ���������� ������ ������
    reg s_axis_tdata = 0;  // ������� ��� 1-������ ������� ������
    reg s_axis_tlast = 0;  // ������� ��� ������� ���������� ���� � ������
    wire m_axis_tvalid;  // ������ ��� ���������� �������� ������
    reg m_axis_tready = 1;  // ������� ��� ���������� ������ �������� ������
    wire m_axis_tdata;  // ������ ��� 1-������ �������� ������
    wire m_axis_tlast;  // ������ ��� ������� ���������� ���� �� ������

    integer fd;  // ���������� �����
    integer bit_idx;  // ������ � ������� bits
    integer char;  // ���������� ��� �������� ������� �� �����
    integer test_num = 0;  // ����� �������� �����
    reg end_of_file = 0;  // ���� ����� �����
    reg [0:767] bits;  // ������ ��� �������� 768 �����
    reg [0:767] output_bits;  // ������ ��� �������� �������� �����
    integer output_idx = 0;  // ������ ��� �������� �����

    scrambler dut (  // ����������� ������ scrambler
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    always #5 clk = ~clk;  // ��������� �����: �������� ������ 5 ������ �������

    integer i;
    
    
    
    // ���������� �������� �� m_axis_tready
//initial begin
  //  m_axis_tready = 1;
    //#1000 m_axis_tready = 0;  // �������� 500 ������ �������, ����� m_axis_tready ������
    //#3000 m_axis_tready = 1;  // ����� 100 ������ ������� m_axis_tready ����� �������
//end

////



////
    initial begin
     
      
     

        // �������� �����
        fd = $fopen("Scrembler_data.txt", "r");
        if (fd == 0) begin
            $display("�� ������� ������� ���� Scrembler_data.txt");
            $finish;
        end

        // ������ � ��������� ������
        bit_idx = 0;
        while (!end_of_file) begin
            char = $fgetc(fd);
            if (char == -1) begin
                if (bit_idx > 0) begin
                    $display("��������: ���� ������ %0d ����� �� ��������� (������ 768 ���)", bit_idx);
                end
                end_of_file = 1;
            end else if (char == "0" || char == "1") begin
                bits[bit_idx] = (char == "1");
                bit_idx = bit_idx + 1;
                if (bit_idx == 768) begin
                    test_num = test_num + 1;
                    $display("���� %0d:", test_num);
                    
                    output_idx = 0;  // ���������� ������ �������� �����
                    for (i = 0; i < 768; i = i + 1) begin
                        @(posedge clk);
                        while (!s_axis_tready) begin
                            @(posedge clk);
                        end
                        s_axis_tdata = bits[i];
                        s_axis_tvalid = 1;
                        s_axis_tlast = (i == 767);
                    end
                    @(posedge clk);
                    s_axis_tvalid = 0;
                    s_axis_tlast = 0;
                    @(posedge clk);
                    // ����� ������ ����� ����� ��������� �����
                    $display("�������� ������ (m_axis_tdata) ��� ����� %0d:", test_num);
                    for (i = 0; i < output_idx; i = i + 1) begin
                        $write("%b", output_bits[i]);
                    end
                    $write("\n");
                    
                    bit_idx = 0;
                end
            end
        end
        
        $fclose(fd);
        $display("��� ����� ���������.");
        #60; $finish;
    end

    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            output_bits[output_idx] = m_axis_tdata;  // ��������� �������� ���
            output_idx = output_idx + 1;  // ����������� ������
        end
    end

endmodule