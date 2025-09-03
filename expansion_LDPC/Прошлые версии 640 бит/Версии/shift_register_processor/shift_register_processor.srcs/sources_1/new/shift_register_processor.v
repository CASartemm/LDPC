module shift_register_processor (
    input clk,
    input rst,
    output reg [127:0] out_row,
    output reg valid
);

    reg [31:0] sr0, sr1, sr2, sr3; // Четыре 32-битных сдвиговых регистра
    reg [127:0] base_rows [0:19];  // Массив для хранения базовых строк
    reg [4:0] base_idx;            // Индекс текущей базовой строки (0-19)
    reg [4:0] shift_cnt;           // Счетчик сдвигов (0-31)

    initial begin
        $readmemb("base_rows.txt", base_rows);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            base_idx <= 0;
            shift_cnt <= 0;
            valid <= 0;
            sr0 <= base_rows[0][127:96];
            sr1 <= base_rows[0][95:64];
            sr2 <= base_rows[0][63:32];
            sr3 <= base_rows[0][31:0];
            out_row <= base_rows[0];
        end
        else begin
            out_row <= {sr0, sr1, sr2, sr3};
            valid <= 1;

            if (shift_cnt == 31) begin
                if (base_idx < 19) begin
                    sr0 <= base_rows[base_idx + 1][127:96];
                    sr1 <= base_rows[base_idx + 1][95:64];
                    sr2 <= base_rows[base_idx + 1][63:32];
                    sr3 <= base_rows[base_idx + 1][31:0];
                    base_idx <= base_idx + 1;
                end
                shift_cnt <= 0;
            end
            else begin
                // Циклический сдвиг вправо на 1 бит
                sr0 <= (sr0 >> 1) | (sr0 << 31);
                sr1 <= (sr1 >> 1) | (sr1 << 31);
                sr2 <= (sr2 >> 1) | (sr2 << 31);
                sr3 <= (sr3 >> 1) | (sr3 << 31);
                shift_cnt <= shift_cnt + 1;
            end
        end
    end
endmodule