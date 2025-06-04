`timescale 1ns / 1ps

module tb_calculate_vector;

    // ------------------------------------------------------------
    // 1. ��������� �������
    // ------------------------------------------------------------
    reg  aclk, aresetn;
    reg  s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;

    wire        m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    // ??????? ��������: ���������� 128-������ ������ �result� ???????
    wire [127:0] dut_result;
    // ???????????????????????????????????????????????????????????

    // �������� �� ��� (slow_clk_div2) ��� ���������� ����� �� DUT
    reg slow_clk_div2;

    // ������ ��� ������� 640-������ ������������������
    reg [0:0] bit_sequence [0:639];
    integer i;

    // ������� ��� ����� ���� �������� ��� (640 ������� + 128 �������� = 768)
    reg [0:767] all_bits;
    integer total_bit_count = 0;

    // ------------------------------------------------------------
    // 2. ������������ DUT: calculate_vector
    // ------------------------------------------------------------
    calculate_vector dut (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast),

        .result       (dut_result),    // ? ��� ��, ���� 128-���
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast (m_axis_tlast)
    );

    // ------------------------------------------------------------
    // 3. ��������� ��������� ������� (100 ���, ������ 10 ��)
    // ------------------------------------------------------------
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // ------------------------------------------------------------
    // 4. �������� �� ��� (slow_clk_div2) - ���������� m_axis_tready
    // ------------------------------------------------------------
    initial begin
        slow_clk_div2 = 1'b0;
    end
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            slow_clk_div2 <= 1'b0;
        end else begin
            slow_clk_div2 <= ~slow_clk_div2;
        end
    end
    always @(*) begin
        m_axis_tready = slow_clk_div2;
    end

    // ------------------------------------------------------------
    // 5. ���� ���� �������� ��� (��� ������� � ������)
    // ------------------------------------------------------------
    // ������ ���, ����� (m_axis_tvalid & m_axis_tready) == 1, ���� m_axis_tdata �
    // ����� � all_bits[ total_bit_count ], ������������� total_bit_count.
    always @(posedge aclk) begin
        if (aresetn && m_axis_tvalid && m_axis_tready) begin
            all_bits[total_bit_count] <= m_axis_tdata;
            total_bit_count <= total_bit_count + 1;
        end
    end

    // ------------------------------------------------------------
    // 6. �������� initial-����: ����� ? �������� ? �������� ? �������� ? �����
    // ------------------------------------------------------------
    initial begin
        // 6.1. ����� � ��������� �������
        aresetn       = 1'b0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        // m_axis_tready ������� ����� slow_clk_div2
        #10 aresetn = 1'b1;

        // 6.2. �������� 640 ��� �� ����� sequence.txt
        // ���� ������ ��������� ����� 640 �������� '0'/'1', ��� ��������.
        $readmemb("sequence.txt", bit_sequence);

        // 6.3. �������� 640 ��� � DUT �� s_axis_* (���� ��� � ����)
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            // ���, ���� DUT ������ s_axis_tready = 1
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            s_axis_tdata  = bit_sequence[i];
            s_axis_tvalid = 1'b1;
            s_axis_tlast  = (i == 639) ? 1'b1 : 1'b0;
        end

        // ����� ���������� ���� ����� ���������� s_axis_tvalid/tlast
        @(posedge aclk);
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;

        // 6.4. �������, ���� all_bits ������ 768 ���������
        // (������� 640 �������, ����� 128 ��������)
        while (total_bit_count < 768) begin
            @(posedge aclk);
        end

        // 6.5. ����� ������ 640 ��� (������� ������������������)
        $display("First 640 bits (input data):");
        for (integer j = 0; j < 20; j = j + 1) begin  // 20 ����� �� 32 ���� = 640
            $write("%b ", all_bits[j*32 +: 32]);
        end
        $write("\n");

        // 6.6. ����� ��������� 128 ��� (��������� �� m_axis_tdata)
        $display("Next 128 bits (result from AXI-Stream):");
        for (integer j = 0; j < 4; j = j + 1) begin  // 4 ������ �� 32 ���� = 128
            $write("%b ", all_bits[640 + j*32 +: 32]);
        end
        $display("\n");

        // 6.7. �������������: ������� ���� dut_result (����� 128-������ ������)
        $display("DUT internal 128-bit result (port): %h", dut_result);

        $display("The simulation is completed.");
        $finish;
    end

    // ------------------------------------------------------------
    // 7. ���������� (�������������) - ������� ������ ������� � ���
    // ------------------------------------------------------------
    initial begin
        $display("   time   aclk aresetn s_tready m_tvalid m_tdata m_tready m_tlast");
        $monitor("%8t   %b     %b       %b         %b        %b         %b       %b",
                  $time, aclk, aresetn, s_axis_tready,
                  m_axis_tvalid, m_axis_tdata,
                  m_axis_tready, m_axis_tlast);
    end

endmodule
