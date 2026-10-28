`timescale 1ns/1ps

module graphics_accelerator #(
    parameter int SCREEN_WIDTH  = 640,
    parameter int SCREEN_HEIGHT = 480,
    parameter int COORD_W       = 10,
    parameter int COLOR_W       = 12
) (
    input  logic                   clk,
    input  logic                   rst,

    input  logic                   cmd_valid,
    output logic                   cmd_ready,
    input  logic [1:0]             cmd_shape,
    input  logic [COORD_W-1:0]     cmd_x0,
    input  logic [COORD_W-1:0]     cmd_y0,
    input  logic [COORD_W-1:0]     cmd_x1,
    input  logic [COORD_W-1:0]     cmd_y1,
    input  logic [COORD_W-1:0]     cmd_x2,
    input  logic [COORD_W-1:0]     cmd_y2,
    input  logic [COLOR_W-1:0]     cmd_color,

    output logic                   pixel_valid,
    output logic [COORD_W-1:0]     pixel_x,
    output logic [COORD_W-1:0]     pixel_y,
    output logic [COLOR_W-1:0]     pixel_color,
    output logic                   busy,
    output logic                   done
);

    localparam logic [1:0] SHAPE_LINE     = 2'd0;
    localparam logic [1:0] SHAPE_RECT     = 2'd1;
    localparam logic [1:0] SHAPE_TRIANGLE = 2'd2;

    typedef enum logic [2:0] {
        IDLE,
        DRAW_LINE,
        DRAW_RECT,
        DRAW_TRIANGLE
    } state_t;

    state_t state;

    integer line_x;
    integer line_y;
    integer line_x1;
    integer line_y1;
    integer line_dx;
    integer line_dy;
    integer line_sx;
    integer line_sy;
    integer line_err;
    integer line_e2;

    integer rect_min_x;
    integer rect_max_x;
    integer rect_min_y;
    integer rect_max_y;
    integer rect_cursor;
    logic [1:0] rect_edge;

    integer tri_x0;
    integer tri_y0;
    integer tri_x1;
    integer tri_y1;
    integer tri_x2;
    integer tri_y2;
    integer tri_min_x;
    integer tri_max_x;
    integer tri_min_y;
    integer tri_max_y;
    integer tri_scan_x;
    integer tri_scan_y;
    integer tri_e0;
    integer tri_e1;
    integer tri_e2;
    logic   tri_inside;

    logic [COLOR_W-1:0] color_reg;

    function automatic integer clamp_x(input integer value);
        if (value < 0)
            clamp_x = 0;
        else if (value >= SCREEN_WIDTH)
            clamp_x = SCREEN_WIDTH - 1;
        else
            clamp_x = value;
    endfunction

    function automatic integer clamp_y(input integer value);
        if (value < 0)
            clamp_y = 0;
        else if (value >= SCREEN_HEIGHT)
            clamp_y = SCREEN_HEIGHT - 1;
        else
            clamp_y = value;
    endfunction

    function automatic integer min2(input integer a, input integer b);
        min2 = (a < b) ? a : b;
    endfunction

    function automatic integer max2(input integer a, input integer b);
        max2 = (a > b) ? a : b;
    endfunction

    function automatic integer min3(input integer a, input integer b, input integer c);
        min3 = min2(min2(a, b), c);
    endfunction

    function automatic integer max3(input integer a, input integer b, input integer c);
        max3 = max2(max2(a, b), c);
    endfunction

    always_comb begin
        tri_e0 = (tri_scan_x - tri_x0) * (tri_y1 - tri_y0)
               - (tri_scan_y - tri_y0) * (tri_x1 - tri_x0);
        tri_e1 = (tri_scan_x - tri_x1) * (tri_y2 - tri_y1)
               - (tri_scan_y - tri_y1) * (tri_x2 - tri_x1);
        tri_e2 = (tri_scan_x - tri_x2) * (tri_y0 - tri_y2)
               - (tri_scan_y - tri_y2) * (tri_x0 - tri_x2);
        tri_inside = ((tri_e0 >= 0) && (tri_e1 >= 0) && (tri_e2 >= 0)) ||
                     ((tri_e0 <= 0) && (tri_e1 <= 0) && (tri_e2 <= 0));
    end

    assign cmd_ready = (state == IDLE);
    assign busy      = (state != IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            pixel_valid <= 1'b0;
            pixel_x     <= '0;
            pixel_y     <= '0;
            pixel_color <= '0;
            color_reg   <= '0;
            done        <= 1'b0;
            rect_edge   <= '0;
        end else begin
            pixel_valid <= 1'b0;
            done        <= 1'b0;

            case (state)
                IDLE: begin
                    if (cmd_valid) begin
                        color_reg <= cmd_color;
                        case (cmd_shape)
                            SHAPE_LINE: begin
                                line_x   <= clamp_x(cmd_x0);
                                line_y   <= clamp_y(cmd_y0);
                                line_x1  <= clamp_x(cmd_x1);
                                line_y1  <= clamp_y(cmd_y1);
                                line_dx  <= (clamp_x(cmd_x1) >= clamp_x(cmd_x0))
                                          ? clamp_x(cmd_x1) - clamp_x(cmd_x0)
                                          : clamp_x(cmd_x0) - clamp_x(cmd_x1);
                                line_dy  <= -((clamp_y(cmd_y1) >= clamp_y(cmd_y0))
                                          ? clamp_y(cmd_y1) - clamp_y(cmd_y0)
                                          : clamp_y(cmd_y0) - clamp_y(cmd_y1));
                                line_sx  <= (clamp_x(cmd_x0) < clamp_x(cmd_x1)) ? 1 : -1;
                                line_sy  <= (clamp_y(cmd_y0) < clamp_y(cmd_y1)) ? 1 : -1;
                                line_err <= ((clamp_x(cmd_x1) >= clamp_x(cmd_x0))
                                          ? clamp_x(cmd_x1) - clamp_x(cmd_x0)
                                          : clamp_x(cmd_x0) - clamp_x(cmd_x1))
                                          - ((clamp_y(cmd_y1) >= clamp_y(cmd_y0))
                                          ? clamp_y(cmd_y1) - clamp_y(cmd_y0)
                                          : clamp_y(cmd_y0) - clamp_y(cmd_y1));
                                state <= DRAW_LINE;
                            end

                            SHAPE_RECT: begin
                                rect_min_x <= min2(clamp_x(cmd_x0), clamp_x(cmd_x1));
                                rect_max_x <= max2(clamp_x(cmd_x0), clamp_x(cmd_x1));
                                rect_min_y <= min2(clamp_y(cmd_y0), clamp_y(cmd_y1));
                                rect_max_y <= max2(clamp_y(cmd_y0), clamp_y(cmd_y1));
                                rect_cursor <= min2(clamp_x(cmd_x0), clamp_x(cmd_x1));
                                rect_edge <= 2'd0;
                                state <= DRAW_RECT;
                            end

                            SHAPE_TRIANGLE: begin
                                tri_x0 <= clamp_x(cmd_x0);
                                tri_y0 <= clamp_y(cmd_y0);
                                tri_x1 <= clamp_x(cmd_x1);
                                tri_y1 <= clamp_y(cmd_y1);
                                tri_x2 <= clamp_x(cmd_x2);
                                tri_y2 <= clamp_y(cmd_y2);
                                tri_min_x <= min3(clamp_x(cmd_x0), clamp_x(cmd_x1), clamp_x(cmd_x2));
                                tri_max_x <= max3(clamp_x(cmd_x0), clamp_x(cmd_x1), clamp_x(cmd_x2));
                                tri_min_y <= min3(clamp_y(cmd_y0), clamp_y(cmd_y1), clamp_y(cmd_y2));
                                tri_max_y <= max3(clamp_y(cmd_y0), clamp_y(cmd_y1), clamp_y(cmd_y2));
                                tri_scan_x <= min3(clamp_x(cmd_x0), clamp_x(cmd_x1), clamp_x(cmd_x2));
                                tri_scan_y <= min3(clamp_y(cmd_y0), clamp_y(cmd_y1), clamp_y(cmd_y2));
                                state <= DRAW_TRIANGLE;
                            end

                            default: state <= IDLE;
                        endcase
                    end
                end

                DRAW_LINE: begin
                    pixel_valid <= 1'b1;
                    pixel_x     <= line_x[COORD_W-1:0];
                    pixel_y     <= line_y[COORD_W-1:0];
                    pixel_color <= color_reg;

                    if ((line_x == line_x1) && (line_y == line_y1)) begin
                        state <= IDLE;
                        done  <= 1'b1;
                    end else begin
                        line_e2 = 2 * line_err;
                        if (line_e2 >= line_dy) begin
                            line_err <= line_err + line_dy;
                            line_x   <= line_x + line_sx;
                        end
                        if (line_e2 <= line_dx) begin
                            if (line_e2 >= line_dy)
                                line_err <= line_err + line_dy + line_dx;
                            else
                                line_err <= line_err + line_dx;
                            line_y <= line_y + line_sy;
                        end
                    end
                end

                DRAW_RECT: begin
                    pixel_valid <= 1'b1;
                    pixel_color <= color_reg;

                    case (rect_edge)
                        2'd0: begin
                            pixel_x <= rect_cursor[COORD_W-1:0];
                            pixel_y <= rect_min_y[COORD_W-1:0];
                            if (rect_cursor == rect_max_x) begin
                                if (rect_min_y == rect_max_y) begin
                                    state <= IDLE;
                                    done  <= 1'b1;
                                end else begin
                                    rect_edge   <= 2'd1;
                                    rect_cursor <= rect_min_x;
                                end
                            end else begin
                                rect_cursor <= rect_cursor + 1;
                            end
                        end

                        2'd1: begin
                            pixel_x <= rect_cursor[COORD_W-1:0];
                            pixel_y <= rect_max_y[COORD_W-1:0];
                            if (rect_cursor == rect_max_x) begin
                                if ((rect_max_y - rect_min_y <= 1) ||
                                    (rect_min_x == rect_max_x)) begin
                                    state <= IDLE;
                                    done  <= 1'b1;
                                end else begin
                                    rect_edge   <= 2'd2;
                                    rect_cursor <= rect_min_y + 1;
                                end
                            end else begin
                                rect_cursor <= rect_cursor + 1;
                            end
                        end

                        2'd2: begin
                            pixel_x <= rect_min_x[COORD_W-1:0];
                            pixel_y <= rect_cursor[COORD_W-1:0];
                            if (rect_cursor == rect_max_y - 1) begin
                                rect_edge   <= 2'd3;
                                rect_cursor <= rect_min_y + 1;
                            end else begin
                                rect_cursor <= rect_cursor + 1;
                            end
                        end

                        default: begin
                            pixel_x <= rect_max_x[COORD_W-1:0];
                            pixel_y <= rect_cursor[COORD_W-1:0];
                            if (rect_cursor == rect_max_y - 1) begin
                                state <= IDLE;
                                done  <= 1'b1;
                            end else begin
                                rect_cursor <= rect_cursor + 1;
                            end
                        end
                    endcase
                end

                DRAW_TRIANGLE: begin
                    pixel_valid <= tri_inside;
                    pixel_x     <= tri_scan_x[COORD_W-1:0];
                    pixel_y     <= tri_scan_y[COORD_W-1:0];
                    pixel_color <= color_reg;

                    if ((tri_scan_x == tri_max_x) && (tri_scan_y == tri_max_y)) begin
                        state <= IDLE;
                        done  <= 1'b1;
                    end else if (tri_scan_x == tri_max_x) begin
                        tri_scan_x <= tri_min_x;
                        tri_scan_y <= tri_scan_y + 1;
                    end else begin
                        tri_scan_x <= tri_scan_x + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
