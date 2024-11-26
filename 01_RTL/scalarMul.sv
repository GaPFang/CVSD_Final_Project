module ScalarMul (
    input         i_clk,
    input         i_rst,
    input         i_start,
    input  [254:0] i_M,
    input  [254:0] i_x,
    input  [254:0] i_y,
    output [254:0] o_x,
    output [254:0] o_y,
    output [254:0] o_z,
    output         o_finished
);

    typedef enum logic {
        S_1,    // r = r + r
        S_2     // r = r + p
    } state_t;

    state_t state_r, state_w;
    logic [254:0] M_r, M_w;
    logic [254:0] x_r, y_r, z_r, x_w, y_w, z_w;
    logic [254:0] xp_r, yp_r, xp_w, yp_w;
    logic finished_r, finished_w;
    logic [254:0] pointAdd_x2, pointAdd_y2, pointAdd_z2, pointAdd_x3, pointAdd_y3, pointAdd_z3;
    logic pointAdd_start, pointAdd_finished, pointAdd_doubling;

    assign o_x = x_r;
    assign o_y = y_r;
    assign o_z = z_r;
    assign o_finished = finished_r;

    reg [7:0] cnt_r, cnt_w;

    PointAdd pointAdd(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(pointAdd_start),
        .i_doubling(pointAdd_doubling),
        .i_x1(x_w),
        .i_y1(y_w),
        .i_z1(z_w),
        .i_x2(pointAdd_x2),
        .i_y2(pointAdd_y2),
        .i_z2(pointAdd_z2),
        .o_x3(pointAdd_x3),
        .o_y3(pointAdd_y3),
        .o_z3(pointAdd_z3),
        .o_finished(pointAdd_finished)
    );

    always_comb begin
        state_w = state_r;
        M_w = M_r;
        x_w = x_r;
        y_w = y_r;
        z_w = z_r;
        xp_w = xp_r;
        yp_w = yp_r;
        finished_w = 0;
        cnt_w = cnt_r;
        pointAdd_start = 0;
        pointAdd_x2 = 0;
        pointAdd_y2 = 0;
        pointAdd_z2 = 0;
        pointAdd_doubling = 0;
        case(state_r)
            S_1: begin
                if (i_start) begin
                    cnt_w = 254;
                    xp_w = i_x;
                    yp_w = i_y;
                    M_w = i_M;
                    pointAdd_start = 1;
                    // pointAdd_x2 = x_r;
                    // pointAdd_y2 = y_r;
                    // pointAdd_z2 = z_r;
                    pointAdd_doubling = 1;
                end
                if(pointAdd_finished) begin
                    x_w = pointAdd_x3;
                    y_w = pointAdd_y3;
                    z_w = pointAdd_z3;
                    if (M_r[cnt_r]) begin
                        state_w = S_2;
                        pointAdd_start = 1;
                        pointAdd_x2 = xp_r;
                        pointAdd_y2 = yp_r;
                        pointAdd_z2 = 1;
                    end else begin
                        cnt_w = cnt_r - 1;
                        if (cnt_r == 0) begin
                            finished_w = 1;
                        end else begin
                            pointAdd_start = 1;
                            // pointAdd_x2 = pointAdd_x3;
                            // pointAdd_y2 = pointAdd_y3;
                            // pointAdd_z2 = pointAdd_z3;
                            pointAdd_doubling = 1;
                        end
                    end
                end
            end
            S_2: begin
                if (pointAdd_finished) begin
                    x_w = pointAdd_x3;
                    y_w = pointAdd_y3;
                    z_w = pointAdd_z3;
                    state_w = S_1;
                    cnt_w = cnt_r - 1;
                    if (cnt_r == 0) begin
                        finished_w = 1;
                    end else begin
                        pointAdd_start = 1;
                        // pointAdd_x2 = pointAdd_x3;
                        // pointAdd_y2 = pointAdd_y3;
                        // pointAdd_z2 = pointAdd_z3;
                        pointAdd_doubling = 1;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state_r <= S_1;
            M_r <= 0;
            x_r <= 0;
            y_r <= 1;
            z_r <= 1;
            xp_r <= 0;
            yp_r <= 0;
            finished_r <= 0;
            cnt_r <= 255;
        end else begin
            state_r <= state_w;
            M_r <= M_w;
            x_r <= x_w;
            y_r <= y_w;
            z_r <= z_w;
            xp_r <= xp_w;
            yp_r <= yp_w;
            finished_r <= finished_w;
            cnt_r <= cnt_w;
        end
    end

    
    
endmodule