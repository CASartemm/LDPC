// �������� ������ ��� �������� ������ calculate_vector
module tb_calculate_vector;

    // ������� ������� ��� AXI Stream Slave ����������
    reg aclk;              // �������� ������
    reg aresetn;           // ������ ������������ ������ (�������� ������)
    reg s_axis_tdata;      // ������� ��� ������ (1 ���)
    reg s_axis_tvalid;     // ������ ���������� ������� ������
    reg s_axis_tlast;      // ������ ���������� ���� � ������������������
    wire s_axis_tready;    // ������ ���������� ������� ������� ������

    // �������� ������� ��� AXI Stream Master ����������
    wire m_axis_tdata;     // �������� ��� ������ (1 ���)
    wire m_axis_tvalid;    // ������ ���������� �������� ������
    reg  m_axis_tready;    // ������ ���������� ������� �������� ������
    wire m_axis_tlast;     // ������ ���������� ���� � �������� ������������������

    // ������� ��� �������� ������� �������������������
    reg [0:0] bit_sequence_1 [0:639]; // ������ �� 640 ��� �� ������� �����
    reg [0:0] bit_sequence_2 [0:639]; // ������ �� 640 ��� �� ������� �����
    integer i;                      // ������� ��� �����

    // �������� ��� �������� �����������
    reg [127:0] received_result_1;  // ���������� ������ ��������� (128 ���)
    reg [127:0] received_result_2;  // ���������� ������ ��������� (128 ���)
    integer bit_count;              // ������� �������� ���
    integer cycle_count;            // ������� ������������ �������������������

    // ��������������� ������������ ������ calculate_vector
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
        forever #5 aclk = ~aclk;  // ������ ��������� ������� 10 �� (������� 100 ���)
    end

    // ������������� ��������� ���������
    initial begin
        // ������������� ��������
        aresetn = 0;            // �������� �����
        s_axis_tvalid = 0;      // ������ �� �������
        s_axis_tlast = 0;       // �� ��������� ���
        m_axis_tready = 1;      // �������� ����� ������� �������� ������
        bit_count = 0;          // ���������� ������� ���
        cycle_count = 0;        // ���������� ������� ������
        received_result_1 = 128'b0; // ������� ������� ��� ������� ����������
        received_result_2 = 128'b0; // ������� ������� ��� ������� ����������
        #10 aresetn = 1;        // ������� ����� ����� 10 ��

        // ��������� ������������������ �� ������
        $readmemb("sequence.txt", bit_sequence_1);    // ��������� 640 ��� �� ������� �����
        $readmemb("sequence_2.txt", bit_sequence_2);  // ��������� 640 ��� �� ������� �����

        // ��� ���� ������ ������������������ ��� ���������
        repeat(2) begin
            // ������ ������������������ � ������
            for (i = 0; i < 640; i = i + 1) begin
                @(posedge aclk); // ���� �������������� ������ �����
                while (!s_axis_tready) begin
                    @(posedge aclk); // ����, ���� ������ �� ����� ������� ������
                end
                // �������� ������������������ � ����������� �� �����
                s_axis_tdata = (cycle_count == 0) ? bit_sequence_1[i] : bit_sequence_2[i];
                s_axis_tvalid = 1;             // ���������, ��� ������ �������
                s_axis_tlast = (i == 639);     // ������������� tlast ��� ���������� ����
            end
            @(posedge aclk);
            s_axis_tvalid = 0; // ���������� ���������� ������
            s_axis_tlast = 0;  // ���������� ���� ���������� ����

            // ��������� ��������� �� ������
            bit_count = 0; // ���������� ������� �������� ���
            while (bit_count < 128) begin
                @(posedge aclk); // ���� �������������� ������ �����
                if (m_axis_tvalid && m_axis_tready) begin
                    // ��������� �������� ��� � ��������������� �������
                    if (cycle_count == 0) begin
                        received_result_1[bit_count] = m_axis_tdata; // ������ ���������
                    end else begin
                        received_result_2[bit_count] = m_axis_tdata; // ������ ���������
                    end
                    bit_count = bit_count + 1; // ����������� ������� ���
                    // ��������� ��������� �������� ����������
                    if (m_axis_tlast && bit_count == 128) begin
                        if (cycle_count == 0) begin
                            $display("������ ���������: %b", received_result_1); // ������� ������ ���������
                        end else begin
                            $display("������ ���������: %b", received_result_2); // ������� ������ ���������
                        end
                    end
                end
            end
            cycle_count = cycle_count + 1; // ����������� ������� ������
        end

        // ���������� ������������
        $display("������������ ���������");
        $finish; // ��������� ���������
    end

endmodule