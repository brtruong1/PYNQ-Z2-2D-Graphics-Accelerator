`timescale 1ns/1ps

module demo_scene #(
    parameter int COORD_W = 10,
    parameter int COLOR_W = 12
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   cmd_ready,
    input  logic                   draw_done,
    output logic                   cmd_valid,
    output logic [1:0]             cmd_shape,
    output logic [COORD_W-1:0]     cmd_x0,
    output logic [COORD_W-1:0]     cmd_y0,
    output logic [COORD_W-1:0]     cmd_x1,
    output logic [COORD_W-1:0]     cmd_y1,
    output logic [COORD_W-1:0]     cmd_x2,
    output logic [COORD_W-1:0]     cmd_y2,
    output logic [COLOR_W-1:0]     cmd_color,
    output logic                   scene_complete
);

    logic [3:0] command_index;
    logic       waiting_for_done;

    always_comb begin
        cmd_shape = 2'd0;
        cmd_x0 = 10'd0;
        cmd_y0 = 10'd0;
        cmd_x1 = 10'd0;
        cmd_y1 = 10'd0;
        cmd_x2 = 10'd0;
        cmd_y2 = 10'd0;
        cmd_color = 12'hFFF;

        case (command_index)
            4'd0: begin
                cmd_shape = 2'd1;
                cmd_x0 = 10'd32;  cmd_y0 = 10'd32;
                cmd_x1 = 10'd607; cmd_y1 = 10'd447;
                cmd_color = 12'h27F;
            end
            4'd1: begin
                cmd_shape = 2'd0;
                cmd_x0 = 10'd60;  cmd_y0 = 10'd400;
                cmd_x1 = 10'd580; cmd_y1 = 10'd80;
                cmd_color = 12'hF33;
            end
            4'd2: begin
                cmd_shape = 2'd0;
                cmd_x0 = 10'd60;  cmd_y0 = 10'd80;
                cmd_x1 = 10'd580; cmd_y1 = 10'd400;
                cmd_color = 12'h3F6;
            end
            4'd3: begin
                cmd_shape = 2'd1;
                cmd_x0 = 10'd190; cmd_y0 = 10'd130;
                cmd_x1 = 10'd450; cmd_y1 = 10'd350;
                cmd_color = 12'hFD2;
            end
            4'd4: begin
                cmd_shape = 2'd2;
                cmd_x0 = 10'd320; cmd_y0 = 10'd105;
                cmd_x1 = 10'd220; cmd_y1 = 10'd330;
                cmd_x2 = 10'd420; cmd_y2 = 10'd330;
                cmd_color = 12'hB4F;
            end
            default: begin
                cmd_shape = 2'd0;
                cmd_color = 12'hFFF;
            end
        endcase
    end

    assign cmd_valid = !scene_complete && !waiting_for_done && cmd_ready;

    always_ff @(posedge clk) begin
        if (rst) begin
            command_index   <= 4'd0;
            waiting_for_done <= 1'b0;
            scene_complete   <= 1'b0;
        end else begin
            if (cmd_valid)
                waiting_for_done <= 1'b1;

            if (draw_done) begin
                waiting_for_done <= 1'b0;
                if (command_index == 4'd4)
                    scene_complete <= 1'b1;
                else
                    command_index <= command_index + 1'b1;
            end
        end
    end

endmodule
