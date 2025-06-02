module tb_calculate_vector;

    // ������� ����������
    reg aclk, aresetn;
    reg s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;
    
    // AXI Stream Master ��������� ��� ��������� ����������
    wire m_axis_tdata;
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;
    
    // ������ ��� ������� ������������������ �����
    reg [0:0] bit_sequence [0:639];
    integer i;
    
    // ������� ��� ����� ���� ���
    reg [0:767] all_bits; // 640 + 128 = 768 ���
    integer total_bit_count = 0;

    // ��������� ������ calculate_vector
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
        forever #5 aclk = ~aclk;  // ������� 100 ���
    end

    // ���� ���� ��� �� m_axis_tdata
    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            all_bits[total_bit_count] = m_axis_tdata;
            total_bit_count = total_bit_count + 1;
        end
    end

    // ������ ���������
    initial begin
        // �������������
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;  // ������ ����� ��������� ������
        #10 aresetn = 1;

        // �������� ������������������ �� �����
        $readmemb("sequence.txt", bit_sequence);

        // �������� ������������������ � ������
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

        // �������� ���������� �������� ���� ���
        while (total_bit_count < 768) begin
            @(posedge aclk);
        end

        // ����� ������ 640 ��� (������� ������) � ���� ������
        $display("First 640 bits (input data):");
        for (integer j = 0; j < 20; j = j + 1) begin  // 640 / 32 = 20 �����
            $write("%b ", all_bits[j*32 +: 32]);
        end
        $write("\n");  // ������� �� ����� ������ ����� ���� 640 ���

        // ����� ��������� 128 ��� (���������)
        $display("Next 128 bits (result):");
        for (integer j = 0; j < 4; j = j + 1) begin  // 128 / 32 = 4 ������
            $write("%b ", all_bits[640 + j*32 +: 32]);
        end
        $display("\n");

        // ���������� ���������
        $display("The simulation is completed");
        $finish;
    end

endmodule