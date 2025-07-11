module tb_calculate_vector;

    // ������� ��� ������������
    reg aclk;
    reg aresetn;
    reg s_axis_tdata;       // 1 ��� ������� ������
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;

    wire m_axis_tdata;      // 1 ��� �������� ������
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;

    // ���������� � �������
    reg [639:0] bit_sequence;             // 640 ��� ������� ������
    reg [127:0] expected_result_bits;     // 128 ��� ���������� ����������
    reg [127:0] expected_result;          // ��������� ���������
    reg [127:0] received_result;          // ���������� ��������� �� DUT
    integer i;                            // ������� ������
    integer bit_count;                    // ������� ����� ����������
    integer fd;                           // �������� ����������
    integer char;                         // ����������� ������
    integer test_num;                     // ����� �����
    reg [767:0] bits;                     // ��������� ������ ��� 768 ���
    integer bit_idx;                      // ������ � ������� bits
    reg end_of_file;                      // ���� ����� �����
    integer success_count;                // ������� �������� ������
    integer fail_count;                   // ������� ���������� ������

    // ����������� DUT
    calculate_vector dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // ��������� ��������� �������
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // ������ 10 ������ �������
    end

    // �������� �������� �������
    initial begin
        // ������������� �������� � ����������
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        received_result = 128'b0;
        expected_result = 128'b0;
        test_num = 0;
        bit_idx = 0;
        end_of_file = 0;
        success_count = 0;
        fail_count = 0;
        #10 aresetn = 1;

        // �������� ����� � ��������� ���������
        fd = $fopen("sequence.txt", "r");
        if (fd == 0) begin
            $display("�� ������� ������� ���� sequence.txt");
            $finish;
        end

        // ������ � ��������� ������
        while (!end_of_file) begin
            char = $fgetc(fd);
            if (char == -1) begin // ����� �����
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

                    // ���������� �� ������� ������������������ � ��������� ���������
                    for (i = 0; i < 640; i = i + 1) begin
                        bit_sequence[i] = bits[i];
                    end
                    for (i = 0; i < 128; i = i + 1) begin
                        expected_result_bits[i] = bits[640 + i];
                    end
                    for (i = 0; i < 128; i = i + 1) begin
                        expected_result[127 - i] = expected_result_bits[i];
                    end

                    // �������� ������� ������ � DUT
                    for (i = 0; i < 640; i = i + 1) begin
                        @(posedge aclk);
                        while (!s_axis_tready) begin
                            @(posedge aclk);
                        end
                        s_axis_tdata = bit_sequence[i];
                        s_axis_tvalid = 1;
                        s_axis_tlast = (i == 639);
                    end
                    @(posedge aclk);
                    s_axis_tvalid = 0;
                    s_axis_tlast = 0;

                    // ��������� ���������� �� DUT
                    bit_count = 0;
                    received_result = 128'b0;
                    while (bit_count < 128) begin
                        @(posedge aclk);
                        if (m_axis_tvalid && m_axis_tready) begin
                            received_result[bit_count] = m_axis_tdata;
                            bit_count = bit_count + 1;
                        end
                    end

                    // ��������� � ����� ����������
                    $display("  ��������: %b", received_result);
                    $display("  ���������: %b", expected_result);
                    if (received_result === expected_result) begin
                        $display("  ���������: �����");
                        success_count = success_count + 1;
                    end else begin
                        $display("  ���������: ������");
                        fail_count = fail_count + 1;
                    end

                    // ����� ������� ��� ���������� �����
                    bit_idx = 0;
                end
            end
            // ������� ���������� �������� (��������, \\n)
        end

        // ���������� � ����� ����������
        $fclose(fd);
        $display("��� ����� ���������.");
        $display("�����: �������� ������ = %0d, ���������� = %0d, ����� = %0d", success_count, fail_count, test_num);
        $finish;
    end

endmodule