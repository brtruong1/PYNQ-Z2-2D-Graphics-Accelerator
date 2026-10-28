`timescale 1ns/1ps

module tmds_serializer (
    input  logic       clk_5x,
    input  logic       rst,
    input  logic [9:0] red_code,
    input  logic [9:0] green_code,
    input  logic [9:0] blue_code,
    output logic       pixel_ce,
    output logic       tmds_clk_p,
    output logic       tmds_clk_n,
    output logic [2:0] tmds_data_p,
    output logic [2:0] tmds_data_n
);

    logic [2:0] phase;
    logic [9:0] red_latched;
    logic [9:0] green_latched;
    logic [9:0] blue_latched;
    logic [9:0] clock_latched;
    logic [3:0] serial_rise;
    logic [3:0] serial_fall;
    logic [3:0] serial_single;
    logic       unused_clock_single;
    logic [2:0] unused_data_single;

    assign pixel_ce = (phase == 3'd4);

    always_ff @(posedge clk_5x) begin
        if (rst) begin
            phase         <= 3'd0;
            red_latched   <= 10'b0;
            green_latched <= 10'b0;
            blue_latched  <= 10'b0;
            clock_latched <= 10'b1111100000;
        end else begin
            if (phase == 3'd4) begin
                phase         <= 3'd0;
                red_latched   <= red_code;
                green_latched <= green_code;
                blue_latched  <= blue_code;
                clock_latched <= 10'b1111100000;
            end else begin
                phase <= phase + 1'b1;
            end
        end
    end

    always_comb begin
        serial_rise[0] = blue_latched[2 * phase];
        serial_rise[1] = green_latched[2 * phase];
        serial_rise[2] = red_latched[2 * phase];
        serial_rise[3] = clock_latched[2 * phase];
        serial_fall[0] = blue_latched[2 * phase + 1];
        serial_fall[1] = green_latched[2 * phase + 1];
        serial_fall[2] = red_latched[2 * phase + 1];
        serial_fall[3] = clock_latched[2 * phase + 1];
    end

    genvar lane;
    generate
        for (lane = 0; lane < 4; lane = lane + 1) begin : gen_ddr
            ODDR #(
                .DDR_CLK_EDGE("SAME_EDGE"),
                .INIT(1'b0),
                .SRTYPE("SYNC")
            ) oddr_inst (
                .Q(serial_single[lane]),
                .C(clk_5x),
                .CE(1'b1),
                .D1(serial_rise[lane]),
                .D2(serial_fall[lane]),
                .R(rst),
                .S(1'b0)
            );
        end
    endgenerate

    OBUFDS #(.IOSTANDARD("TMDS_33")) clk_out (
        .I(serial_single[3]),
        .O(tmds_clk_p),
        .OB(tmds_clk_n)
    );

    generate
        for (lane = 0; lane < 3; lane = lane + 1) begin : gen_tmds_out
            OBUFDS #(.IOSTANDARD("TMDS_33")) data_out (
                .I(serial_single[lane]),
                .O(tmds_data_p[lane]),
                .OB(tmds_data_n[lane])
            );
        end
    endgenerate

endmodule
