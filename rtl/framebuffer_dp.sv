`timescale 1ns/1ps
//dual-port pixel memory that lets the rasterizer write colors while the diplay reads them
module framebuffer_dp #(
    parameter int WIDTH   = 640,
    parameter int HEIGHT  = 480,
    parameter int COLOR_W = 12,
    parameter int ADDR_W  = $clog2(WIDTH * HEIGHT)
) (
    input  logic                 wr_clk,
    input  logic                 wr_en,
    input  logic [ADDR_W-1:0]    wr_addr,
    input  logic [COLOR_W-1:0]   wr_data,
    input  logic                 rd_clk,
    input  logic                 rd_en,
    input  logic [ADDR_W-1:0]    rd_addr,
    output logic [COLOR_W-1:0]   rd_data
);

    (* ram_style = "block" *) logic [COLOR_W-1:0] memory [0:WIDTH*HEIGHT-1];  //use fpga's block ram
    integer i;

    initial begin
        for (i = 0; i < WIDTH * HEIGHT; i = i + 1)
            memory[i] = '0;   //fill array with 0's
    end

    always_ff @(posedge wr_clk) begin
        if (wr_en)
            memory[wr_addr] <= wr_data;
    end

    always_ff @(posedge rd_clk) begin
        if (rd_en)
            rd_data <= memory[rd_addr];
    end

endmodule
