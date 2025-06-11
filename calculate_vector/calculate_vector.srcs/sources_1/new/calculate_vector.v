`timescale 1ns / 1ps

module calculate_vector (
    input  wire         aclk,          // �������� ������
    input  wire         aresetn,       // ����� (�������� ������)

    // AXI Stream Slave (����� 640 ��� �� ����)
    input  wire         s_axis_tdata,  // ������� ��� (1 ���)
    input  wire         s_axis_tvalid, // ���������� ������� ������
    output wire         s_axis_tready, // ���������� ������� ������� ���
    input  wire         s_axis_tlast,  // ����� ������� ������������������

    // �������� 128-������ ������ 'result'
    output reg  [127:0] result,        // �������� ������: 128-������ ���������

    // AXI Stream Master (�������� 128 ��� �� �����)
    output wire         m_axis_tdata,  // �������� ��� (1 ���)
    output wire         m_axis_tvalid, // ���������� �������� ������
    input  wire         m_axis_tready, // ���������� �������
    output wire         m_axis_tlast   // ����� �������� ������������������
);

    // ================= ���������� ������� =================
    // ����� � bit_receiver (����� 640 ���)
    wire        br_m_axis_tdata;    // ��� �� bit_receiver
    wire        br_m_axis_tvalid;   // ���������� �� bit_receiver
    wire        br_m_axis_tlast;    // ����� 640-������ ������������������
    reg         int_m_axis_tready;  // ���������� ������ ����������

    // ����� � shift_register_processor
    wire [127:0] out_row;  // �������� (128 ���) �� ����� XOR
    wire         valid;    // ���������� out_row
    wire         en = br_m_axis_tvalid; // ������ ��� ������

    // FSM ��� ����������
    reg [127:0]  acc;       // ����������� XOR (128 ���)
    reg [6:0]    bit_index; // ������ ��� �������� 128 ��� (0..127)
    reg          state;     // FSM: RECEIVING ��� TRANSMITTING
    reg          prev_state;

    localparam RECEIVING    = 1'b0;
    localparam TRANSMITTING = 1'b1;

    // ��� �������� �� RECEIVING � TRANSMITTING ���������� shift
    wire srp_rst = ~aresetn | (state == TRANSMITTING && prev_state == RECEIVING);

    // ================ ����������� =================
    // 1) bit_receiver: ��������� 640 ��� �� s_axis_* � �������� �� ����� br_m_axis_*
    bit_receiver bit_rx (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast),
        .m_axis_tdata (br_m_axis_tdata),
        .m_axis_tvalid(br_m_axis_tvalid),
        .m_axis_tready(int_m_axis_tready),
        .m_axis_tlast (br_m_axis_tlast)
    );

    // 2) shift_register_processor: ��� en=1 ���������� 128-������ ������ out_row
    shift_register_processor shift_reg_proc (
        .clk     (aclk),
        .rst     (srp_rst),
        .en      (en),
        .out_row (out_row),
        .valid   (valid)
    );

    // ============= ����� m_axis_* =================
    // ���� �� � RECEIVING, �������� br_m_axis_tdata.
    // � TRANSMITTING �������� �� ����� ��� result[bit_index].
    assign m_axis_tdata  = (state == RECEIVING) ? br_m_axis_tdata
                         : result[bit_index];
    assign m_axis_tvalid = (state == RECEIVING) ? br_m_axis_tvalid
                         : 1'b1;
    assign m_axis_tlast  = (state == TRANSMITTING) && (bit_index == 127);

    // ==================== FSM ====================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // ������������� ���������
            state             <= RECEIVING;
            prev_state        <= RECEIVING;
            int_m_axis_tready <= 1'b1;
            bit_index         <= 7'd0;
            acc               <= 128'd0;
            result            <= 128'd0;
        end else begin
            prev_state <= state;
            case (state)
                // ------------- RECEIVING -------------
                RECEIVING: begin
                    // ������������� s_axis_tready � 1, ����� �� ����������� ��������
                    int_m_axis_tready <= 1'b1;
                    if (br_m_axis_tvalid && int_m_axis_tready) begin
                        // ���� ��� ����� '1', �� xor � ������� �������������
                        if (br_m_axis_tdata)
                            acc <= acc ^ out_row;
                        // ���� ��� ��������� ��� (640-�), ��������� result
                        if (br_m_axis_tlast) begin
                            result            <= br_m_axis_tdata ? (acc ^ out_row) : acc;
                            acc               <= 128'd0;
                            state             <= TRANSMITTING;
                            bit_index         <= 7'd0;   // ���������� ������ ��� ��������
                            int_m_axis_tready <= 1'b0;   // �� ��������� ������, ���� ��������
                        end
                    end
                end

                // ------------ TRANSMITTING ------------
               TRANSMITTING: begin
    int_m_axis_tready <= 1'b0;
    if (m_axis_tvalid && m_axis_tready) begin
        if (bit_index < 7'd127) begin
            bit_index <= bit_index + 1;
        end else begin
            // �������� ��� 128 ��� - ���������� result � ������������ � RECEIVING
            state     <= RECEIVING;
            bit_index <= 7'd0;
            result    <= 128'd0; 
        end
    end
end

            endcase
        end
    end

endmodule