`timescale 1ns/1ps

module video_timing_640x480 (
    input  logic       clk,
    input  logic       rst,
    input  logic       pixel_ce,
    output logic [9:0] x,
    output logic [9:0] y,
    output logic       active_video,
    output logic       hsync,
    output logic       vsync,
    output logic       frame_start
);

    localparam int H_ACTIVE = 640;
    localparam int H_FRONT  = 16;
    localparam int H_SYNC   = 96;
    localparam int H_BACK   = 48;
    localparam int H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

    localparam int V_ACTIVE = 480;
    localparam int V_FRONT  = 10;
    localparam int V_SYNC   = 2;
    localparam int V_BACK   = 33;
    localparam int V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    assign active_video = (x < H_ACTIVE) && (y < V_ACTIVE);
    assign hsync = ~((x >= H_ACTIVE + H_FRONT) &&
                     (x <  H_ACTIVE + H_FRONT + H_SYNC));
    assign vsync = ~((y >= V_ACTIVE + V_FRONT) &&
                     (y <  V_ACTIVE + V_FRONT + V_SYNC));
    assign frame_start = pixel_ce && (x == 0) && (y == 0);

    always_ff @(posedge clk) begin
        if (rst) begin
            x <= 10'd0;
            y <= 10'd0;
        end else if (pixel_ce) begin
            if (x == H_TOTAL - 1) begin
                x <= 10'd0;
                if (y == V_TOTAL - 1)
                    y <= 10'd0;
                else
                    y <= y + 1'b1;
            end else begin
                x <= x + 1'b1;
            end
        end
    end

endmodule
