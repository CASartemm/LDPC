`timescale 1ns / 1ps
// �������� ������ . �������� ������� 
module calculate_vector (
    input  wire         aclk,          // �������� ������ - ��� ��� ������ ������, ����� ���� ������
    input  wire         aresetn,       // ������ ������ - ���� 0, �� ���������� � ���������� ������
    // AXI Stream Slave - ���� �������� ������ (640 ��� �� ������ �� ����)
    input  wire         s_axis_tdata,  // ������� ��� - ������ ���� �������� 1 ��� ������
    input  wire         s_axis_tvalid, // �������, ��� ������� ��� ����� � ��� ����� �����
    output wire         s_axis_tready, // ������� �������� ����, ��� �� ������ ��������� ������
    input  wire         s_axis_tlast,  // ����������, ��� ��� ��������� ��� �� 640
    // AXI Stream Master - ������ ������ ������ (128 ��� �� ������ �� ����)
    output wire         m_axis_tdata,  // �������� ��� - ������ ���� ����� 1 ��� ����������
    output wire         m_axis_tvalid, // �������, ��� �������� ��� ����� � ��� ����� �������
    input  wire         m_axis_tready, // ������� ���, ��� ������� ��� ����� ����� ��� ���
    output wire         m_axis_tlast   // ����������, ��� ��� ��������� ��� �� 128
);

    // ������� ��� ������� � ���������� bit_receiver
    wire        br_m_axis_tdata;       // ���, ������� �� �������� �� bit_receiver
    wire        br_m_axis_tvalid;      // �������, ��� ��� �� bit_receiver �����
    wire        br_m_axis_tlast;       // �������, ��� ��� ��������� ��� �� bit_receiver
    wire        br_s_axis_tready;      // ����������, ����� �� bit_receiver ��������� ������
    reg         int_m_axis_tready;     // ��� ������, ����� ������� bit_receiver, ������ �� �� ����� ���

    // ������� ��� ������� � ���������� shift_register_processor
    wire [127:0] out_row;              // ������ �� 128 ���, ������� ��� shift_register_processor
    wire         valid;                // �������, ��� ������ �� shift_register_processor ������
    wire         en = br_m_axis_tvalid;// �������� shift_register_processor, ����� ���� ������

    // ���� ���������� "����������" (��������)
    reg [127:0]  acc;                  // ����������� - ���� ���������� ��������� ����������
    reg [6:0]    bit_index;            // ������� ��� ��������: ����� ��� �� 128 �� ������ ����� (0-127)
    reg [9:0]    buffer_index;         // ������� ��� �����: ����� ��� �� 640 �� ������� (0-639)
    reg [127:0]  result;               // ������� ���������, ������� ����� ��������
    reg          is_transmitting;      // ����: ���� 1, ������, ������ ����� ���������
    reg          m_axis_tvalid_reg;    // �������, ����� ��������� �������� ���������� ������

    // ������ ������ ��� shift_register_processor
    wire srp_rst = ~aresetn | (is_transmitting && bit_index == 0); // ���������� ��� ��� ����� ������ ��� ������ ��������

    // �������������� ������ out_row, ����� �������� reversed_out_row
    reg [127:0] reversed_out_row;      // ������ �� shift_register_processor, �� ����� ������
    integer rev_i;                     // ������� ��� �����
    always @(*) begin                  // ��� �������� ���������, ��� �������� �����
        for (rev_i = 0; rev_i < 128; rev_i = rev_i + 1) begin
            reversed_out_row[rev_i] = out_row[127 - rev_i]; // ���� ���� � �����
        end
    end

    // ���������� ���������
    bit_receiver bit_rx (              // ������, ������� ������ ������� ���� �� ����� � ���
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(br_s_axis_tready),
        .s_axis_tlast (s_axis_tlast),
        .m_axis_tdata (br_m_axis_tdata),
        .m_axis_tvalid(br_m_axis_tvalid),
        .m_axis_tready(int_m_axis_tready),
        .m_axis_tlast (br_m_axis_tlast)
    );

    shift_register_processor shift_reg_proc ( // ������, ������� ����� ������ �� ����� �� ����
        .clk     (aclk),
        .rst     (srp_rst),
        .en      (en),
        .out_row (out_row),
        .valid   (valid)
    );

    // �������� ������� - ������, ��� �������� ������
    assign m_axis_tdata  = is_transmitting ? result[bit_index] : br_m_axis_tdata; // ���� �����, ���� ��� �� ����������, ����� - �� bit_receiver
    assign m_axis_tvalid = is_transmitting ? m_axis_tvalid_reg : br_m_axis_tvalid; // ���� �����, ���������� ��� �������, ����� - �� bit_receiver
    assign m_axis_tlast  = is_transmitting ? 1'b0 : br_m_axis_tlast; // br_m_axis_tlast, ��� ������� �� 128 ���
    assign s_axis_tready = is_transmitting ? 1'b0 : br_s_axis_tready; // �� ��������� ������, ���� ����� ���������

    // �������� ������ ������
    always @(posedge aclk or negedge aresetn) begin // ����������� �� ������ ���� ��� �����
        if (!aresetn) begin            // ���� �����, �������� ��
            int_m_axis_tready <= 1'b1; // ������ ��������� ������
            acc               <= 128'd0; // �������� �����������
            result            <= 128'd0; // �������� ���������
            bit_index         <= 7'd0;   // ���������� ������� �����
            buffer_index      <= 10'd0;  // ���������� ������� ������
            is_transmitting   <= 1'b0;   // �� ����� ������
            m_axis_tvalid_reg <= 1'b0;   // ����� �� �����
        end else begin                 // ���� �� �����, ��������
            // ���������� ����������� � ��������� � ������ ������ ������
            if (buffer_index == 0 && !is_transmitting) begin
                acc    <= 128'd0;      // �������� ���������� � ����
                result <= 128'd0;      // ������� ������ ���������
            end

            // ��������� ������
            if (!is_transmitting && br_m_axis_tvalid && int_m_axis_tready) begin
                int_m_axis_tready <= 1'b1; // ���������� ���� ��������
                buffer_index      <= buffer_index + 1; // �������, ������� ����� �������
                if (br_m_axis_tdata) begin // ���� ������ ��� 1
                    acc <= acc ^ reversed_out_row; // ��������� ������ � ������������ ����� XOR
                end
                // ���� ��� ��������� ��� ������
                if (br_m_axis_tlast) begin
                    result          <= br_m_axis_tdata ? (acc ^ reversed_out_row) : acc; // ��������� ���������
                    is_transmitting <= 1'b1; // ������������� �� ������
                    buffer_index    <= 10'd0; // ���������� ������� �����
                    bit_index       <= 7'd0;  // ���������� ������� ������
                    m_axis_tvalid_reg <= 1'b1; // �������, ��� ����� �����
                    int_m_axis_tready <= 1'b0; // ������ �� ��������� ������
                end
            end

            // ����� ���������
            if (is_transmitting && m_axis_tvalid_reg && m_axis_tready) begin
                if (bit_index < 127) begin // ���� �� ��� ���� ������
                    bit_index <= bit_index + 1; // ��������� � ���������� ����
                end else begin            // ���� ������ ��������� ���
                    is_transmitting   <= 1'b0; // ����������� ������
                    m_axis_tvalid_reg <= 1'b0; // ����� ������ �� �����
                    bit_index         <= 7'd0; // ���������� �������
                    int_m_axis_tready <= 1'b1; // ������ ��������� ����� �����
                end
            end else if (is_transmitting && !m_axis_tvalid_reg && bit_index < 128) begin
                m_axis_tvalid_reg <= 1'b1; // �������� ������, ���� ��� �� ������
            end
        end
    end

endmodule