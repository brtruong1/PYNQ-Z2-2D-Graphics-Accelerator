`timescale 1ns/1ps

// Lightweight behavioral models used only by open-source simulation/lint.
// Vivado supplies the real 7-series primitives during synthesis and XSim.
module ODDR #(
    parameter DDR_CLK_EDGE = "SAME_EDGE",
    parameter INIT = 1'b0,
    parameter SRTYPE = "SYNC"
) (
    output logic Q,
    input logic C,
    input logic CE,
    input logic D1,
    input logic D2,
    input logic R,
    input logic S
);
    initial Q = INIT;
    always @(posedge C)
        if (R) Q <= 1'b0;
        else if (S) Q <= 1'b1;
        else if (CE) Q <= D1;
    always @(negedge C)
        if (R) Q <= 1'b0;
        else if (S) Q <= 1'b1;
        else if (CE) Q <= D2;
endmodule

module OBUFDS #(
    parameter IOSTANDARD = "DEFAULT"
) (
    input logic I,
    output logic O,
    output logic OB
);
    assign O = I;
    assign OB = ~I;
endmodule
