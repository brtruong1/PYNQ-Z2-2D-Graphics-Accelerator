`timescale 1ns/1ps
//sends 5 drawing commmands sequentially and waits for completion before going on to the next command
module demo_scene #(
    parameter int COORD_W = 10,   //10 bits per x or y cord
    parameter int COLOR_W = 12    //4 bits each for red, green, blue
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   cmd_ready,
    input  logic                   draw_done,
    output logic                   cmd_valid,
    output logic [1:0]             cmd_shape,
    output logic [COORD_W-1:0]     cmd_x0,   //3 x and y pairs so we can make triangle
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

    always_comb begin  //puts a command on the wires
        cmd_shape = 2'd0;
        cmd_x0 = 10'd0;
        cmd_y0 = 10'd0;
        cmd_x1 = 10'd0;
        cmd_y1 = 10'd0;
        cmd_x2 = 10'd0;
        cmd_y2 = 10'd0;
        cmd_color = 12'hFFF; //white

        case (command_index)
            4'd0: begin
                cmd_shape = 2'd1; //rectangle
                cmd_x0 = 10'd32;  cmd_y0 = 10'd32;   //blue outline from (32,32) to (607,447)
                cmd_x1 = 10'd607; cmd_y1 = 10'd447;
                cmd_color = 12'h27F; //blue
            end
            4'd1: begin
                cmd_shape = 2'd0;   //line
                cmd_x0 = 10'd60;  cmd_y0 = 10'd400; 
                cmd_x1 = 10'd580; cmd_y1 = 10'd80;
                cmd_color = 12'hF33; //red
            end
            4'd2: begin
                cmd_shape = 2'd0; //line 
                cmd_x0 = 10'd60;  cmd_y0 = 10'd80;
                cmd_x1 = 10'd580; cmd_y1 = 10'd400;
                cmd_color = 12'h3F6; //green
            end
            4'd3: begin
                cmd_shape = 2'd1; //rectangle
                cmd_x0 = 10'd190; cmd_y0 = 10'd130; //yellow outline
                cmd_x1 = 10'd450; cmd_y1 = 10'd350;
                cmd_color = 12'hFD2; //yellow
            end
            4'd4: begin
                cmd_shape = 2'd2; //filled triangle
                cmd_x0 = 10'd320; cmd_y0 = 10'd105; //3 points 
                cmd_x1 = 10'd220; cmd_y1 = 10'd330;
                cmd_x2 = 10'd420; cmd_y2 = 10'd330;
                cmd_color = 12'hB4F; //purple
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
                    command_index <= command_index + 1'b1;   //this just cycles thru and draws the outer blue rectangle, red diag line, green diag line, inner yellow rect, and purple triangle
            end
        end
    end

endmodule
