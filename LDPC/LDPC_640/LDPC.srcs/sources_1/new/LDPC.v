// LDPC: ���-������ - ������� ��� calculate_vector. ������ �������� ���� ��� �����.

module tdma_LDPC (
    input  wire aclk,             // ����: �������� ������ (clock)
    input  wire aresetn,          // ����: ������ ������ 
    input  wire s_axis_tdata,     // ����: 1-������ ������ �� AXI-Stream
    input  wire s_axis_tvalid,    // ����: ���������� ������� ������
    input  wire s_axis_tlast,     // ����: ��������� ����� ������� ������
    output wire s_axis_tready,    // �����: ���������� ������ ������� ������
    
    output wire m_axis_tdata,     // �����: 1-������ �������� ������ �� AXI-Stream
    output wire m_axis_tvalid,    // �����: ���������� �������� ������
    input  wire m_axis_tready,    // ����: ���������� ������ �������� ������
    output wire m_axis_tlast      // �����: ��������� ����� �������� ������
);

// ������� DUT (calculate_vector) - ���������� ��� ����� ��������.
tdma_calculate_vector dut (
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

endmodule

// ������ bit_receiver ��������� ���� �� calculate_vector, 1 ��� �� 1 ���� � ����������  � calculate_vector ��� ��� br_m_axis_tdata ,
//br_m_axis_tdata ��� ��������� � ��������� ������ �� ������� .
//������ ������ ��� �������� �����������  ������ 640 ��� � 128 ���. 

//������ shift_register_processor ���������� 640 ����� ������� Pg �� 20 ������� (�� 128 ���) ���� ����������� ������� (32 ���� �� ������).
// ��������� ������ �� ����� , ����� �� ����� ������ �� ���� ��� en=1 , �� ������� out_row �������� � calculate_vector ��� ��������� 

//������ calculate_vector ��������� ���������� � ������� ,
// ����� ������������� �� ��������� is_transmitting = 0 ������ 640 ��� ����� ������ br_m_axis_tdata,
// �� ��������� is_transmitting = 1 ������ 128 ��� ����� ������ m_axis_tdata . 