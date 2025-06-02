module bit_receiver (
    input wire aclk,
    input wire aresetn,
    
    // AXI Stream Slave ��������� ��� �������� ������������������
    input wire s_axis_tdata,      // 1 ��� ������
    input wire s_axis_tvalid,     // ������ �������
    output reg s_axis_tready,     // ���������� ���������
    input wire s_axis_tlast,      // ��������� ���
    
    // AXI Stream Master ��������� ��� �������� ������������������
    output reg m_axis_tdata,      // 1 ��� ������
    output reg m_axis_tvalid,     // ������ �������
    input wire m_axis_tready,     // ������� �����
    output reg m_axis_tlast,      // ��������� ���
    
    // ����� ��� �������� �������� (�����������)
    output reg [31:0] bit_count_out  // �������� �������� ���������� �����
);

    reg [31:0] bit_counter;  // ���������� ������� ��������

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_tready <= 1;   // ����� ��������� ������ ����� ������
            m_axis_tvalid <= 0;   // �������� ������ �� �������
            m_axis_tdata <= 0;    // ���������� ������
            m_axis_tlast <= 0;    // ���������� ���� ���������� ����
            bit_counter <= 0;     // ���������� �������
            bit_count_out <= 0;   // ���������� �������� ���� ��������
        end else begin
            // ��������� ���� � ����� ��������
            s_axis_tready <= m_axis_tready;  // ���������� ��������� ������� �� ��������
            if (s_axis_tvalid && m_axis_tready) begin
                m_axis_tdata <= s_axis_tdata;    // ������� ������ �����
                m_axis_tvalid <= s_axis_tvalid;  // ���������� �������� ������
                m_axis_tlast <= s_axis_tlast;    // ������� ���� ���������� ����
                bit_counter <= bit_counter + 1;  // ����������� ������� ��� �������� ����
                bit_count_out <= bit_counter + 1; // ��������� �������� ���� (������� �������� +1)
            end else begin
                m_axis_tvalid <= 0;  // ���� ������� �� �����, ������ �� �������
            end
        end
    end
endmodule