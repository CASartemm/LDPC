//�������� ������ , ��������� ���� � ���������� � �������� � calculate_vector
module bit_receiver (
    input wire aclk,              // �������� ������
    input wire aresetn,           // �������� ������ �����
    
    // AXI Stream Slave: ��������� ��� ������� ������������������
    input wire s_axis_tdata,      // 1-������ ������ �����
    input wire s_axis_tvalid,     // ������ ������� (������ � ��������)
    output reg s_axis_tready,     // ���������� ������ ������� ������
    input wire s_axis_tlast,      // ���� ���������� ���� � ������
    
    // AXI Stream Master: ��������� ��� �������� ������������������
    output reg m_axis_tdata,      // 1-������ ������ ������
    output reg m_axis_tvalid,     // ������ ������� (������ � ��������)
    input wire m_axis_tready,     // ���������� ��������� ������� ������
    output reg m_axis_tlast       // ���� ���������� ���� � ������
);

// �������� always-����: ��������� �� ���� ��� �����
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        // ������������� ��� ������:
        s_axis_tready <= 1'b1;  // ������ ���������� ����� ��������� ������
        m_axis_tvalid <= 1'b0;  // �������� ������ �� �������
        m_axis_tdata  <= 1'b0;  // ������� �������� ������
        m_axis_tlast  <= 1'b0;  // ���������� ���� ���������� ����
    end else begin
        // �� ���������: �������� ������ �� �������, ���� ��� ��������
        m_axis_tvalid <= 1'b0;
        m_axis_tlast  <= 1'b0;  //  ����� �� ���������, ����� �� �������
        
        // ��������� ������� ������, ���� ��� ������� � ������ �����
        if (s_axis_tvalid && s_axis_tready) begin
            // ������ �������� ������:
            m_axis_tdata  <= s_axis_tdata;  // �������� ��� ������ �� �����
            m_axis_tvalid <= 1'b1;          // ������������� ���������� ������
            m_axis_tlast  <= s_axis_tlast;  // �������� ���� ���������� ���� (override)
            
            // ���������� ���������� ��� ���������� �����:
            // ���� ��� ��������� ���, ��������� � ������ ������
            // �����, ������� �� ���������� ��������� (backpressure)
            s_axis_tready <= s_axis_tlast ? 1'b1 : m_axis_tready;
        end else begin
            // ���� ������ ��� ��� �� ������: ��������� backpressure
            // ���������� ������ ������� �� ���������� ���������
            s_axis_tready <= m_axis_tready;
        end
    end
end
endmodule