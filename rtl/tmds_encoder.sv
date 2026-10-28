`timescale 1ns/1ps

module tmds_encoder (
    input  logic       clk,
    input  logic       rst,
    input  logic       ce,
    input  logic [7:0] video_data,
    input  logic [1:0] control_data,
    input  logic       video_enable,
    output logic [9:0] tmds_code
);

    logic [8:0] q_m;
    logic [9:0] next_code;
    logic [3:0] ones_data;
    logic [3:0] ones_qm;
    integer balance;
    integer disparity;
    integer next_disparity;
    integer k;

    always_comb begin
        ones_data = video_data[0] + video_data[1] + video_data[2] + video_data[3]
                  + video_data[4] + video_data[5] + video_data[6] + video_data[7];

        q_m[0] = video_data[0];
        if ((ones_data > 4) || ((ones_data == 4) && !video_data[0])) begin
            for (k = 1; k < 8; k = k + 1)
                q_m[k] = ~(q_m[k-1] ^ video_data[k]);
            q_m[8] = 1'b0;
        end else begin
            for (k = 1; k < 8; k = k + 1)
                q_m[k] = q_m[k-1] ^ video_data[k];
            q_m[8] = 1'b1;
        end

        ones_qm = q_m[0] + q_m[1] + q_m[2] + q_m[3]
                + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        balance = (2 * ones_qm) - 8;

        next_code      = 10'b1101010100;
        next_disparity = disparity;

        if (!video_enable) begin
            case (control_data)
                2'b00: next_code = 10'b1101010100;
                2'b01: next_code = 10'b0010101011;
                2'b10: next_code = 10'b0101010100;
                default: next_code = 10'b1010101011;
            endcase
            next_disparity = 0;
        end else if ((disparity == 0) || (balance == 0)) begin
            next_code[9]   = ~q_m[8];
            next_code[8]   = q_m[8];
            next_code[7:0] = q_m[8] ? q_m[7:0] : ~q_m[7:0];
            next_disparity = q_m[8] ? (disparity + balance)
                                      : (disparity - balance);
        end else if (((disparity > 0) && (balance > 0)) ||
                     ((disparity < 0) && (balance < 0))) begin
            next_code[9]   = 1'b1;
            next_code[8]   = q_m[8];
            next_code[7:0] = ~q_m[7:0];
            next_disparity = disparity + (q_m[8] ? 2 : 0) - balance;
        end else begin
            next_code[9]   = 1'b0;
            next_code[8]   = q_m[8];
            next_code[7:0] = q_m[7:0];
            next_disparity = disparity - (q_m[8] ? 0 : 2) + balance;
        end
    end

    assign tmds_code = next_code;

    always_ff @(posedge clk) begin
        if (rst)
            disparity <= 0;
        else if (ce)
            disparity <= next_disparity;
    end

endmodule
