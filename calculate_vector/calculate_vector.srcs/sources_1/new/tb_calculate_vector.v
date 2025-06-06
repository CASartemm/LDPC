`timescale 1ns / 1ps

module tb_calculate_vector;

    // �������
    reg  aclk, aresetn;
    reg  s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;

    wire        m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    // ���������� 128-������ ������ �result�
    wire [127:0] dut_result;

    // �������� �� ��� ��� ���������� �����
    reg slow_clk_div2;

    // ������ ��� ������� 640-������ ������������������
    reg [0:0] bit_sequence [0:639];
    integer i;

    // ���� ���������� ������
    reg output_complete = 0;

    // ������� ��� ������������ ������ ����
    integer bit_counter = 0;

    // ������������ DUT
    calculate_vector dut (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast),

        .result       (dut_result),
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast (m_axis_tlast)
    );

    // ��������� ��������� ������� (100 ���, ������ 10 ��)
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // �������� �� ��� ��� m_axis_tready
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

    // ����������� ���������� ������
    always @(posedge aclk) begin
        if (!aresetn) begin
            output_complete <= 0;
        end else if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
            output_complete <= 1;
        end
    end

    // ������ ��� ����������� ��� � �������� � ������� ������ �������� 128 ���
    always @(posedge aclk) begin
        if (aresetn && m_axis_tvalid && m_axis_tready) begin
            bit_counter = bit_counter + 1;
            if (bit_counter == 641) begin
                $display("������ �������� 128-������� ����������");
            end
            $display("%d-� ���: %b", bit_counter, m_axis_tdata);
        end
    end

    // ���������� ����� ��� m_axis_tvalid � m_axis_tready
    always @(posedge aclk) begin
        $display("Time: %t, m_axis_tvalid: %b, m_axis_tready: %b", $time, m_axis_tvalid, m_axis_tready);
    end

    // �������� initial-����: ����� ? �������� ? �������� ? �������� ? ����������
    initial begin
        // ����� � ��������� �������
        aresetn       = 1'b0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        #10 aresetn = 1'b1;

        // �������� 640 ��� �� ����� sequence.txt
        $readmemb("sequence.txt", bit_sequence);

        // �������� 640 ��� � DUT
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            s_axis_tdata  = bit_sequence[i];
            s_axis_tvalid = 1'b1;
            s_axis_tlast  = (i == 639) ? 1'b1 : 1'b0;
        end
        $display("���� ����������, i = %d", i);

        // ����� �������� ����� ���������� ����
        @(posedge aclk);
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;

        // �������� ���������� ������
        while (!output_complete) begin
            @(posedge aclk);
        end

        $display("The simulation is completed.");
        $finish;
    end

endmodule