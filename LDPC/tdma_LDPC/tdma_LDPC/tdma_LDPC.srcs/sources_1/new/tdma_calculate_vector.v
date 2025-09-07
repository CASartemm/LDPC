// �������� ������ . �������� �������
module tdma_calculate_vector (
    input wire aclk,
    input wire aresetn,
    // AXI Stream Slave - ���� �������� ������ (640 ��� �� ������ �� ����)
    input wire s_axis_tdata, // ������� ��� - ������ ���� �������� 1 ��� ������
    input wire s_axis_tvalid, // �������, ��� ������� ��� ����� � ��� ����� �����
    output wire s_axis_tready, // ������� �������� ����, ��� �� ������ ��������� ������
    input wire s_axis_tlast, // ����������, ��� ��� ��������� ��� �� 640
    // AXI Stream Master - ������ ������ ������ (128 ��� �� ������ �� ����)
    output wire m_axis_tdata, // �������� ��� - ������ ���� ����� 1 ��� ����������
    output wire m_axis_tvalid, // �������, ��� �������� ��� ����� � ��� ����� �������
    input wire m_axis_tready, // ������� ���, ��� ������� ��� ����� ����� ��� ���
    output wire m_axis_tlast // ����������, ��� ��� ��������� ��� �� 128
);
    // ������� ��� ������� � ���������� shift_register_processor
    wire [127:0] out_row; // ������ �� 128 ���, ������� ��� shift_register_processor
    wire valid; // �������, ��� ������ �� shift_register_processor ������
    wire en = s_axis_tvalid && m_axis_tready;// �������� shift_register_processor, ����� ���� ������
    // ���� ���������� "����������" (��������)
    reg [127:0] acc; // ����������� - ���� ���������� ��������� ����������
    reg [6:0] bit_index; // ������� ��� ��������: ����� ��� �� 128 �� ������ ����� (0-127)
    reg [9:0] buffer_index; // ������� ��� �����: ����� ��� �� 640 �� ������� (0-639)
    reg [127:0] result; // ������� ���������, ������� ����� ��������
    reg is_transmitting; // ����: ���� 1, ������, ������ ����� ���������
    reg reset_pulse; // ����� ������ ��� shift_register_processor
    // ������ ������ ��� shift_register_processor
    wire srp_rst = ~aresetn | reset_pulse; // ���������� ��� ����� ������ ��� ������
    // ���������� ���������

    tdma_shift_register_processor shift_reg_proc ( // ������, ������� ����� ������ �� ����� �� ����
        .clk (aclk),
        .rst (srp_rst),
        .en (en),
        .out_row (out_row),
        .valid (valid)
    );
    // �������� ������� - ������, ��� �������� ������
    assign m_axis_tdata = is_transmitting ? result[127 - bit_index] : s_axis_tdata; // ���� �����, ���� ��� �� ����������, ����� - �� bit_receiver
    assign m_axis_tvalid = is_transmitting ? 1 : s_axis_tvalid; // ���� �����, ���������� ��� �������, ����� - �� bit_receiver
    assign m_axis_tlast = (is_transmitting && (bit_index == 127)); // ��� �������� - �� ��������� ����
    assign s_axis_tready = is_transmitting ? 1'b0 : m_axis_tready; // �� ��������� ������, ���� ����� ���������
    // �������� ������ ������
    always @(posedge aclk or negedge aresetn) begin // ����������� �� ������ ���� ��� �����
        if (!aresetn) begin // ���� �����, �������� ��
            acc <= 128'd0; // �������� �����������
            result <= 128'd0; // �������� ���������
            bit_index <= 7'd0; // ���������� ������� �����
            buffer_index <= 10'd0; // ���������� ������� ������
            is_transmitting <= 1'b0; // �� ����� ������
            reset_pulse <= 1'b1; // ����� ������
        end else begin // ���� �� �����, ��������
            reset_pulse <= 1'b0; // �� ��������� ������� �����
            // ��������� ������
            if (!is_transmitting && s_axis_tvalid && m_axis_tready) begin
                buffer_index <= buffer_index + 1; // �������, ������� ����� �������
                if (s_axis_tdata) begin // ���� ������ ��� 1
                    acc <= acc ^ out_row; // ��������� ������ � ������������ ����� XOR
                end
                // ���� ��� ��������� ��� ������
                if (s_axis_tlast) begin
                    result <= s_axis_tdata ? (acc ^ out_row) : acc; // ��������� ���������
                    is_transmitting <= 1'b1; // ������������� �� ������
                    buffer_index <= 10'd0; // ���������� ������� �����
                    bit_index <= 7'd0; // ���������� ������� ������
                end
            end
            // ����� ���������
            else if (is_transmitting && m_axis_tready) begin
                if (bit_index < 127) begin // ���� �� ��� ���� ������
                    bit_index <= bit_index + 1; // ��������� � ���������� ����
                end else begin // ���� ������ ��������� ���
                    is_transmitting <= 1'b0; // ����������� ������
                    bit_index <= 7'd0; // ���������� �������
                    acc <= 128'd0;
                    result <= 128'd0;
                    reset_pulse <= 1'b1; // ����� ������ ��� ���������� ������
                end
            end
        end
    end
endmodule