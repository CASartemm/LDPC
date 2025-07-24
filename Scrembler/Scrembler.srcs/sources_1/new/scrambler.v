module scrambler (
    input clk,
    input rst,               
    input s_axis_tvalid,     // ������� ������, ������ ������
    output s_axis_tready,    // ������ ���������� ��������� ������
    input s_axis_tdata,      // ������� ������
    input s_axis_tlast,      // ����� ���������� ���� ������
    output reg m_axis_tvalid,// ������, ��� �������� ������ ������
    input m_axis_tready,     // ������ ���������� �������� ����������
    output reg m_axis_tdata, // �������� ������
    output reg m_axis_tlast  // ����� ���������� ���� �� ������
);

reg separation = 0;                           // ������������� ������/��������
reg [14:0] shift_reg_a = 15'b100101010101111; // ������� � ��� ������ ������
reg [14:0] shift_reg_b = 15'b000111000111000; // ������� B ��� �������� ������
reg [9:0] bit_counter = 0;                    // ������� ����� (10 ��� ��� ����� �� 768) ������������ ��� m_axis_tlast 

assign s_axis_tready = m_axis_tready || !m_axis_tvalid; // ������ ����� ��������� ������, ���� ���������� ������ ����� ��� ��� ������ �� ������
                                                        
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        m_axis_tvalid <= 0;     // ���������� ������ ���������� �������� ������
        m_axis_tdata <= 0;      // ���������� �������� ������
        m_axis_tlast <= 0;      // ���������� ����� ���������� ����
        separation <= 0;        // ���������� ������������� ������/��������
        bit_counter <= 0;       // ���������� ������� �����
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin // ���� ���� ������� ������ � ���������� ������
            if (!separation) begin  // ������ ������
                m_axis_tdata <= s_axis_tdata ^ (shift_reg_a[2] ^ shift_reg_a[0]);      // xor ����� 0 � 2 , ����� xor � ����� ������� (0 � 2 �� �� ���������� , ������ �������� ���� ������ ������)
                shift_reg_a <= {(shift_reg_a[2] ^ shift_reg_a[0]), shift_reg_a[14:1]}; // �������� ������� B 
            end else begin  // �������� ������
                m_axis_tdata <= s_axis_tdata ^ (shift_reg_b[2] ^ shift_reg_b[0]); // ������������ ������ � ��������� B (���� 0 � 2 ��� �������� �����)
                shift_reg_b <= {(shift_reg_b[2] ^ shift_reg_b[0]), shift_reg_b[14:1]}; // �������� ������� B  
            end
            bit_counter <= bit_counter + 1; // ����������� ������� �����
            m_axis_tlast <= (bit_counter == 767); // ������������� tlast, ����� ������ 768 �����
            m_axis_tvalid <= 1;           // �������������, ��� �������� ������ ������               
            separation <= ~separation;    // ����������� ������/��������
        end else if (m_axis_tready && m_axis_tvalid) begin // ���� ������� ���������� ������ � ���� �������� ������
            m_axis_tvalid <= 0; // ���������� ������ ���������� �������� ������
            if (m_axis_tlast) begin //���� m_axis_tlast =1 �� �������� ������������ � ��������� ��������� 
                separation <= 0;
                shift_reg_a <= 15'b100101010101111;
                shift_reg_b <= 15'b000111000111000;
                bit_counter <= 0; // ���������� ������� ����� ����� tlast
            end
        end
    end
end

endmodule