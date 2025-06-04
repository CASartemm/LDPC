module tb_LDPC_0;

    // ���������
    parameter CLK_PERIOD = 10; // ������ ��������� ������� � ��
    parameter DATA_WIDTH = 128; // ������ ������ ��� AXI-Stream

    // �������
    reg core_clk;
    reg reset_n;

    // S_AXI_CTRL (AXI-Stream ��� ����������)
    reg [31:0] s_axis_ctrl_tdata;
    reg s_axis_ctrl_tvalid;
    wire s_axis_ctrl_tready;

    // S_AXI_DIN (AXI-Stream ��� ������� ������)
    reg [DATA_WIDTH-1:0] s_axis_din_tdata;
    reg s_axis_din_tlast;
    reg s_axis_din_tvalid;
    wire s_axis_din_tready;

    // M_AXI_DOUT (AXI-Stream ��� �������� ������)
    wire [DATA_WIDTH-1:0] m_axis_dout_tdata;
    wire m_axis_dout_tlast;
    wire m_axis_dout_tvalid;
    reg m_axis_dout_tready;

    // M_AXI_STATUS (AXI-Stream ��� �������)
    wire [31:0] m_axis_status_tdata;
    wire m_axis_status_tvalid;
    reg m_axis_status_tready;

    // ������ �������
    wire interrupt;

    // ��������������� IP-����
    ldpc_0 uut (
        .core_clk(core_clk),
        .reset_n(reset_n),
        .s_axis_ctrl_tdata(s_axis_ctrl_tdata),
        .s_axis_ctrl_tvalid(s_axis_ctrl_tvalid),
        .s_axis_ctrl_tready(s_axis_ctrl_tready),
        .s_axis_din_tdata(s_axis_din_tdata),
        .s_axis_din_tlast(s_axis_din_tlast),
        .s_axis_din_tvalid(s_axis_din_tvalid),
        .s_axis_din_tready(s_axis_din_tready),
        .m_axis_dout_tdata(m_axis_dout_tdata),
        .m_axis_dout_tlast(m_axis_dout_tlast),
        .m_axis_dout_tvalid(m_axis_dout_tvalid),
        .m_axis_dout_tready(m_axis_dout_tready),
        .m_axis_status_tdata(m_axis_status_tdata),
        .m_axis_status_tvalid(m_axis_status_tvalid),
        .m_axis_status_tready(m_axis_status_tready),
        .interrupt(interrupt)
    );

    // ��������� ��������� �������
    always #(CLK_PERIOD / 2) core_clk = ~core_clk;

    // �������� ������� ������������
    initial begin
        // ������������� ��������
        core_clk = 0;
        reset_n = 0;
        s_axis_ctrl_tdata = 0;
        s_axis_ctrl_tvalid = 0;
        s_axis_din_tdata = 0;
        s_axis_din_tlast = 0;
        s_axis_din_tvalid = 0;
        m_axis_dout_tready = 1; // ���������� ��������� ������
        m_axis_status_tready = 1; // ���������� ��������� ������

        // ����� ����
        #100 reset_n = 1;

        // ���� 1: ��������� ���� ��� �����������
        #10;
        s_axis_ctrl_tdata = 32'h00000001; // ������ ������� ��� �����������
        s_axis_ctrl_tvalid = 1;
        wait (s_axis_ctrl_tready); // �������� ���������� ����
        #10;
        s_axis_ctrl_tvalid = 0;

        // ���� 2: �������� ������ ��� �����������
        #10;
        s_axis_din_tdata = 128'hDEADBEEF1234567890ABCDEF12345678; // ������ ������� ������
        s_axis_din_tvalid = 1;
        s_axis_din_tlast = 1; // �������� ����� ������
        wait (s_axis_din_tready); // �������� ���������� ����
        #10;
        s_axis_din_tvalid = 0;
        s_axis_din_tlast = 0;

        // ���� 3: �������� �������� ������
        wait (m_axis_dout_tvalid); // �������� �������� �������� ������
        $display("�������� ������: %h", m_axis_dout_tdata);
        $display("������: %h", m_axis_status_tdata);

        // ���������� ���������
        #1000 $finish;
    end

    // ���������� �������� (�����������)
    initial begin
        $monitor("Time=%0t | reset_n=%b | interrupt=%b | m_axis_dout_tvalid=%b | m_axis_dout_tdata=%h",
                 $time, reset_n, interrupt, m_axis_dout_tvalid, m_axis_dout_tdata);
    end

endmodule