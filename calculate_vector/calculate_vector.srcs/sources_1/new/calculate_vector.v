`timescale 1ns / 1ps

module calculate_vector (
    input  wire         aclk,          // �������� ������ ��� ������������� ������ ������
    input  wire         aresetn,       // ������ ������ (�������� ������ �������)

    // AXI Stream Slave (���� 640 ���)
    input  wire         s_axis_tdata,  // ������� ������ (1 ��� �� ����)
    input  wire         s_axis_tvalid, // ������ ���������� ������� ������
    output wire         s_axis_tready, // ������ ���������� ������ � ������ ������
    input  wire         s_axis_tlast,  // ������, ������������ ����� ������ ������

    // ����� 128-������� ����������
    output reg  [127:0] result,        // �������� 128-������ ��������� ��������� ������

    // AXI Stream Master (����� 128 ���)
    output wire         m_axis_tdata,  // �������� ������ (1 ��� �� ����)
    output wire         m_axis_tvalid, // ������ ���������� �������� ������
    input  wire         m_axis_tready, // ������ ���������� �������� ���������� � ������ ������
    output wire         m_axis_tlast   // ������ ����� ������ �������� ������
);

    // ���������� ������� ��� ����������� � ������ bit_receiver
    wire        br_m_axis_tdata;       // �������� ������ �� bit_receiver (1 ���)
    wire        br_m_axis_tvalid;      // ������ ���������� ������ �� bit_receiver
    wire        br_m_axis_tlast;       // ������ ����� ������ �� bit_receiver
    wire        br_s_axis_tready;      // ������ ���������� bit_receiver � ������ ������
    reg         int_m_axis_tready;     // ���������� ������ ���������� � ������ ������ �� bit_receiver

    // ���������� ������� ��� ����������� � shift_register_processor
    wire [127:0] out_row;              // 128-������ �������� ��� �� shift_register_processor
    wire         valid;                // ������ ���������� ������ �� shift_register_processor
    wire         en = br_m_axis_tvalid;// ������ ��������� ��� shift_register_processor, ������ � ����������� ������� ������

    // ����������� ��������� ��������� �������� (FSM)
    localparam RECEIVING    = 2'b00;   // ��������� ������ ������
    localparam TRANSMITTING = 2'b01;   // ��������� �������� ����������

    reg [1:0]    state;                // ������� ��������� ��������� ��������
    reg [127:0]  acc;                  // ����������� ��� �������������� �������� ���������� ���������
    reg [6:0]    bit_index;            // ������ �������� ���� ��� �������� ���������� (�� 127)
    reg [9:0]    buffer_index;         // ������ ��� ������ ������� ������ (�� 639)
    reg [639:0]  input_buffer;         // ����� ��� �������� 640 ��� ������� ������

    // ������ ������ ��� shift_register_processor
    wire srp_rst = ~aresetn | (state == TRANSMITTING && (bit_index == 0)); // ����� ��� ������ aresetn ��� � ������ ��������

    // ����������� ������ bit_receiver ��� ������ 640 ��� ������
    bit_receiver bit_rx (
        .aclk         (aclk),          // �������� ������
        .aresetn      (aresetn),       // ������ ������
        .s_axis_tdata (s_axis_tdata),  // ������� ������ �� AXI Stream Slave
        .s_axis_tvalid(s_axis_tvalid), // ���������� ������� ������
        .s_axis_tready(br_s_axis_tready), // ���������� bit_receiver � ������
        .s_axis_tlast (s_axis_tlast),  // ������ ����� ������
        .m_axis_tdata (br_m_axis_tdata), // �������� ������ bit_receiver
        .m_axis_tvalid(br_m_axis_tvalid), // ���������� �������� ������
        .m_axis_tready(int_m_axis_tready), // ���������� � ������ ������ ������
        .m_axis_tlast (br_m_axis_tlast)   // ������ ����� ������
    );

    // ����������� ������ shift_register_processor ��� ��������� ������
    shift_register_processor shift_reg_proc (
        .clk     (aclk),               // �������� ������
        .rst     (srp_rst),            // ������ ������
        .en      (en),                 // ������ ��������� ���������
        .out_row (out_row),            // �������� 128-������ ���
        .valid   (valid)               // ������ ���������� ����������
    );

    // ������ ������������ �������� AXI Stream Master
    reg m_axis_tvalid_reg;             // ������� ��� ���������� �������� m_axis_tvalid
    assign m_axis_tdata  = (state == RECEIVING) ? br_m_axis_tdata : result[bit_index]; // ����� ����� ������� �� bit_receiver � ����� ����������
    assign m_axis_tvalid = (state == RECEIVING) ? br_m_axis_tvalid : m_axis_tvalid_reg; // ���������� ������� �� ���������
    assign m_axis_tlast  = (state == RECEIVING) ? br_m_axis_tlast : (bit_index == 127 && m_axis_tvalid_reg && m_axis_tready); // ����� ������

    // ������ ������� s_axis_tready
    assign s_axis_tready = (state == RECEIVING) ? br_s_axis_tready : 1'b0; // ���������� � ������ ������ � ��������� RECEIVING

    // �������� ������� ��� ���������� ������� � ��������� ������
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin            // ����������� ����� ��� ������ aresetn
            state        <= RECEIVING; // ��������� ��������� - ����� ������
            int_m_axis_tready <= 1'b1; // ������ ����� ��������� ������
            acc          <= 128'd0;    // ����� ������������
            result       <= 128'd0;    // ����� ����������
            bit_index    <= 7'd0;      // ����� ������� �����
            buffer_index <= 10'd0;     // ����� ������� ������
            input_buffer <= 640'd0;    // ����� ������
            m_axis_tvalid_reg <= 0;    // �������� ������ �� �������
        end else begin
            case (state)
                RECEIVING: begin       // ��������� ������ ������
                    int_m_axis_tready <= 1'b1; // ���������� � ������ �� bit_receiver
                    m_axis_tvalid_reg <= 0;    // �������� ������ �� �������
                    if (buffer_index == 0) begin // ��� ������ ������ ������
                        acc <= 128'd0;     // ����� ������������
                        result <= 128'd0;  // ����� ����������
                    end
                    if (br_m_axis_tvalid && int_m_axis_tready) begin // ���� ������ ������� � ������ �����
                        input_buffer[buffer_index] <= br_m_axis_tdata; // ������ ���� � �����
                        buffer_index <= buffer_index + 1; // ���������� ������� ������
                        if (br_m_axis_tdata)      // ���� ������� ��� ����� 1
                            acc <= acc ^ out_row; // ���������� �������� XOR � ������� shift_register_processor
                        if (br_m_axis_tlast) begin // ���� ������� ��������� ��� ������
                            result <= br_m_axis_tdata ? (acc ^ out_row) : acc; // ������������ �������������� ����������
                            state        <= TRANSMITTING; // ������� � ��������� ��������
                            bit_index    <= 7'd0; // ����� ������� �����
                            buffer_index <= 10'd0; // ����� ������� ������
                            m_axis_tvalid_reg <= 1; // ���������� � �������� ������� ���� ����������
                        end
                    end
                end
                TRANSMITTING: begin    // ��������� �������� ����������
                    if (m_axis_tvalid_reg && m_axis_tready) begin // ���� ������ ������� � ������� ���������� ������
                        if (bit_index < 127) begin // ���� �� ��� ���� ��������
                            bit_index <= bit_index + 1; // ���������� ������� �����
                            m_axis_tvalid_reg <= 1; // ���������� ��������
                        end else begin         // ���� ������� ��������� ���
                            m_axis_tvalid_reg <= 0; // �������� ���������
                            state <= RECEIVING; // ������� � ��������� ������
                            bit_index <= 0;     // ����� ������� �����
                        end
                    end else if (!m_axis_tvalid_reg && bit_index < 128) begin // ���� ������ ��� �� ��������
                        m_axis_tvalid_reg <= 1; // ���������� � �������� ���������� ����
                    end
                end
            endcase
        end
    end

endmodule