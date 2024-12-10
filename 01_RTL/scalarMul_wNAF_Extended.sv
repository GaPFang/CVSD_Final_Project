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

    typedef enum logic [2:0] {
        S_IDLE,
        S_CALC_T,               // T = XY/Z, Z = 1 -> T = XY
        S_DOUBLE,               // P_double = P + P
        S_NAF_AND_PRECOMPUTE,   // r = NAF(M), precompute Ps
        S_4,                    // r = r + r
        S_5                     // r = r + Ps[M[(cnt+1) +: (w-2)]]
    } state_t;

    localparam w = 3'd3;
    localparam two_pow_wMinus2 = 1 << (w-2);

    state_t state_r, state_w;
    logic [254:0] M_r, M_w;
    logic [254:0][(w-1):0] NAF_r, NAF_w;
    logic [7:0] cnt_r, cnt_w;
    logic [2:0] precompute_cnt_r, precompute_cnt_w;
    logic [(two_pow_wMinus2-1):0][254:0] Ps_x_r, Ps_x_w, Ps_y_r, Ps_y_w, Ps_z_r, Ps_z_w, Ps_t_r, Ps_t_w;
    logic [254:0] x_r, y_r, z_r, x_w, y_w, z_w, t_r, t_w;
    logic finished_r, finished_w;
    logic [254:0] pointAdd_x1, pointAdd_y1, pointAdd_z1, pointAdd_t1, pointAdd_x2, pointAdd_y2, pointAdd_z2, pointAdd_t2, pointAdd_x3, pointAdd_y3, pointAdd_z3, pointAdd_t3;
    logic pointAdd_start, pointAdd_finished, pointAdd_doubling, pointAdd_initial;
    wire [(w-1):0] naf_tmp = NAF_r[cnt_r];
    wire [(w-2):0] naf = naf_tmp[(w-1):1];

    assign o_x = x_r;
    assign o_y = y_r;
    assign o_z = z_r;
    assign o_finished = finished_r;

    PointAdd pointAdd(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(pointAdd_start),
        .i_doubling(pointAdd_doubling),
        .i_initial(pointAdd_initial),
        .i_x1(pointAdd_x1),
        .i_y1(pointAdd_y1),
        .i_z1(pointAdd_z1),
        .i_t1(pointAdd_t1),
        .i_x2(pointAdd_x2),
        .i_y2(pointAdd_y2),
        .i_z2(pointAdd_z2),
        .i_t2(pointAdd_t2),
        .o_x3(pointAdd_x3),
        .o_y3(pointAdd_y3),
        .o_z3(pointAdd_z3),
        .o_t3(pointAdd_t3),
        .o_finished(pointAdd_finished)
    );

    

    always_comb begin
        state_w = state_r;
        M_w = M_r;
        NAF_w = NAF_r;
        x_w = x_r;
        y_w = y_r;
        z_w = z_r;
        t_w = t_r;
        finished_w = 0;
        cnt_w = cnt_r;
        precompute_cnt_w = precompute_cnt_r;
        pointAdd_start = 0;
        pointAdd_doubling = 0;
        pointAdd_initial = 0;
        pointAdd_x2 = 0;
        pointAdd_y2 = 0;
        pointAdd_z2 = 0;
        pointAdd_t2 = 0;
        Ps_x_w = Ps_x_r;
        Ps_y_w = Ps_y_r;
        Ps_z_w = Ps_z_r;
        Ps_t_w = Ps_t_r;
        NAF_w = NAF_r;
        pointAdd_x1 = pointAdd_x3;
        pointAdd_y1 = pointAdd_y3;
        pointAdd_z1 = pointAdd_z3;
        pointAdd_t1 = pointAdd_t3;
        case(state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_CALC_T;
                    pointAdd_start = 1;
                    // pointAdd_doubling = 1;
                    pointAdd_initial = 1;
                    pointAdd_x1 = i_x;
                    pointAdd_y1 = i_y;
                    pointAdd_z1 = 1;
                    Ps_x_w[0] = i_x;
                    Ps_y_w[0] = i_y;
                    Ps_z_w[0] = 1;
                    M_w = i_M;
                    x_w = 0;
                    y_w = 1;
                    z_w = 1;
                    t_w = 0;
                end
            end
            S_CALC_T: begin
                if (pointAdd_finished) begin
                    state_w = S_DOUBLE;
                    Ps_x_w[0] = pointAdd_x3;
                    Ps_y_w[0] = pointAdd_y3;
                    Ps_z_w[0] = pointAdd_z3;
                    Ps_t_w[0] = pointAdd_t3;
                    pointAdd_doubling = 1;
                    pointAdd_start = 1;
                end
            end
            S_DOUBLE: begin
                if (pointAdd_finished) begin
                    Ps_x_w[two_pow_wMinus2-1] = pointAdd_x3;
                    Ps_y_w[two_pow_wMinus2-1] = pointAdd_y3;
                    Ps_z_w[two_pow_wMinus2-1] = pointAdd_z3;
                    Ps_t_w[two_pow_wMinus2-1] = pointAdd_t3;
                    precompute_cnt_w = 1;
                    state_w = S_NAF_AND_PRECOMPUTE;
                    pointAdd_start = 1;
                    pointAdd_x1 = Ps_x_r[0];    // original x, y, z, t
                    pointAdd_y1 = Ps_y_r[0];
                    pointAdd_z1 = Ps_z_r[0];
                    pointAdd_t1 = Ps_t_r[0];
                    pointAdd_x2 = pointAdd_x3;      // P_double
                    pointAdd_y2 = pointAdd_y3;
                    pointAdd_z2 = pointAdd_z3;
                    pointAdd_t2 = pointAdd_t3;
                    cnt_w = 0;
                    NAF_w = 0;
                end
            end
            S_NAF_AND_PRECOMPUTE: begin
                if (pointAdd_finished) begin
                    Ps_x_w[precompute_cnt_r] = pointAdd_x3;
                    Ps_y_w[precompute_cnt_r] = pointAdd_y3;
                    Ps_z_w[precompute_cnt_r] = pointAdd_z3;
                    Ps_t_w[precompute_cnt_r] = pointAdd_t3;
                    if (precompute_cnt_r == (two_pow_wMinus2 - 1)) begin
                        state_w = S_4;
                        precompute_cnt_w = 0;
                        pointAdd_start = 1;
                        pointAdd_doubling = 1;
                        pointAdd_x1 = x_r;
                        pointAdd_y1 = y_r;
                        pointAdd_z1 = z_r;
                        pointAdd_t1 = t_r;
                    end else begin
                        pointAdd_start = 1;
                        pointAdd_x1 = pointAdd_x3;
                        pointAdd_y1 = pointAdd_y3;
                        pointAdd_z1 = pointAdd_z3;
                        pointAdd_t1 = pointAdd_t3;
                        pointAdd_x2 = Ps_x_r[two_pow_wMinus2-1];
                        pointAdd_y2 = Ps_y_r[two_pow_wMinus2-1];
                        pointAdd_z2 = Ps_z_r[two_pow_wMinus2-1];
                        pointAdd_t2 = Ps_t_r[two_pow_wMinus2-1];
                        precompute_cnt_w = precompute_cnt_r + 1;
                    end
                end
                if (|M_r) begin
                    if (M_r[0]) begin
                        NAF_w[cnt_r] = M_r[(w-1):0];
                        if (M_r[w-1]) begin
                            M_w = (M_r >> w) + 1;
                        end else begin
                            M_w = M_r >> w;
                        end
                        if (|M_w) begin
                            cnt_w = cnt_r + w;
                        end
                    end else begin
                        NAF_w[cnt_r] = 0;
                        M_w = M_r >> 1;
                        cnt_w = cnt_r + 1;
                    end
                end
            end
            S_4: begin
                if(pointAdd_finished) begin
                    x_w = pointAdd_x3;
                    y_w = pointAdd_y3;
                    z_w = pointAdd_z3;
                    t_w = pointAdd_t3;
                    if (naf_tmp) begin
                        state_w = S_5;
                        pointAdd_start = 1;
                        if (naf_tmp[w-1]) begin
                            pointAdd_x2 = Ps_x_r[~naf];
                            pointAdd_y2 = `N - Ps_y_r[~naf];
                            pointAdd_z2 = Ps_z_r[~naf];
                            pointAdd_t2 = `N - Ps_t_r[~naf];
                        end else begin
                            pointAdd_x2 = Ps_x_r[naf];
                            pointAdd_y2 = Ps_y_r[naf];
                            pointAdd_z2 = Ps_z_r[naf];
                            pointAdd_t2 = Ps_t_r[naf];
                        end
                    end else begin
                        cnt_w = cnt_r - 1;
                        if (cnt_r == 0) begin
                            finished_w = 1;
                        end else begin
                            pointAdd_start = 1;
                            pointAdd_doubling = 1;
                        end
                    end
                end
            end
            S_5: begin
                if (pointAdd_finished) begin
                    x_w = pointAdd_x3;
                    y_w = pointAdd_y3;
                    z_w = pointAdd_z3;
                    t_w = pointAdd_t3;
                    state_w = S_4;
                    cnt_w = cnt_r - 1;
                    if (cnt_r == 0) begin
                        finished_w = 1;
                    end else begin
                        pointAdd_start = 1;
                        pointAdd_doubling = 1;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state_r <= S_IDLE;
            M_r <= 0;
            x_r <= 0;
            y_r <= 1;
            z_r <= 1;
            t_r <= 0;
            finished_r <= 0;
            cnt_r <= 0;
            precompute_cnt_r <= 0;
            Ps_x_r <= 0;
            Ps_y_r <= 0;
            Ps_z_r <= 0;
            Ps_t_r <= 0;
            NAF_r <= 0;
        end else begin
            state_r <= state_w;
            M_r <= M_w;
            x_r <= x_w;
            y_r <= y_w;
            z_r <= z_w;
            t_r <= t_w;
            finished_r <= finished_w;
            cnt_r <= cnt_w;
            precompute_cnt_r <= precompute_cnt_w;
            Ps_x_r <= Ps_x_w;
            Ps_y_r <= Ps_y_w;
            Ps_z_r <= Ps_z_w;
            Ps_t_r <= Ps_t_w;
            NAF_r <= NAF_w;
        end
    end

    
    
endmodule