module PointAdd(
    input i_clk,
    input i_rst,
    input i_start,
    input i_doubling,
    input i_initial,
    input [254:0] i_x1,
    input [254:0] i_y1,
    input [254:0] i_z1,
    input [254:0] i_t1,
    input [254:0] i_x2,
    input [254:0] i_y2,
    input [254:0] i_z2,
    input [254:0] i_t2,
    output [254:0] o_x3,
    output [254:0] o_y3,
    output [254:0] o_z3,
    output [254:0] o_t3,
    output o_finished
);
    
    logic finished_r, finished_w;

    typedef enum logic [2:0] {
        S_IDLE,
        S_1,
        S_2,
        S_3,
        S_4,
        S_5,
        S_6,
        S_7
        // S_8,
        // S_9,
        // S_10,
        // S_11,
        // S_12,
        // S_13,
        // S_14,
        // S_15
    } state_t;

    state_t state_r, state_w;

    logic [254:0] x1_r, y1_r, z1_r, t1_r, x2_r, y2_r, z2_r, t2_r;
    logic [254:0] x1_w, y1_w, z1_w, t1_w, x2_w, y2_w, z2_w, t2_w;
    logic [254:0] MA_a [0:1], MA_b [0:1], MA_result [0:1];
    logic [254:0] MS_a [0:1], MS_b [0:1], MS_result [0:1];

    logic i_montgomery1_start;
    logic [254:0] i_a[0:3], i_b[0:3];
    logic [254:0] o_montgomery[0:3];
    logic o_montgomery_finished;

    integer i, j;

    assign o_x3 = x1_r;
    assign o_y3 = y1_r;
    assign o_z3 = z1_r;
    assign o_t3 = t1_r;
    assign o_finished = finished_r;
    
    numberMul numberMul0(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery1_start),
        .i_a(i_a[0]),
        .i_b(i_b[0]),
        .o_montgomery(o_montgomery[0]),
        .o_finished(o_montgomery_finished)
    );

    numberMul numberMul1(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery1_start),
        .i_a(i_a[1]),
        .i_b(i_b[1]),
        .o_montgomery(o_montgomery[1]),
        .o_finished()
    );

    numberMul numberMul2(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery1_start),
        .i_a(i_a[2]),
        .i_b(i_b[2]),
        .o_montgomery(o_montgomery[2]),
        .o_finished()
    );

    numberMul numberMul3(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery1_start),
        .i_a(i_a[3]),
        .i_b(i_b[3]),
        .o_montgomery(o_montgomery[3]),
        .o_finished()
    );

    modularAdd MA0(
        .a(MA_a[0]),
        .b(MA_b[0]),
        .result(MA_result[0])
    );

    modularAdd MA1(
        .a(MA_a[1]),
        .b(MA_b[1]),
        .result(MA_result[1])
    );

    modularSub MS0(
        .a(MS_a[0]),
        .b(MS_b[0]),
        .result(MS_result[0])
    );

    modularSub MS1(
        .a(MS_a[1]),
        .b(MS_b[1]),
        .result(MS_result[1])
    );

    // function [254:0] modularAdd;
    //     input [254:0] a, b;
    //     logic [256:0] add;
    //     localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
    //     begin
    //         add = a + b;
    //         modularAdd = add;
    //         if (add > N) begin
    //             modularAdd = add - N;
    //         end
    //     end
    // endfunction

    // function [254:0] modularSubfunc;
    //     input [254:0] a, b;
    //     logic [256:0] sub;
    //     localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
    //     begin
    //         sub = a + N - b;
    //         modularSubfunc = sub;
    //         if (sub > N) begin
    //             modularSubfunc = sub - N;
    //         end
    //     end
    // endfunction

    always_comb begin
        state_w = state_r;
        x1_w = x1_r;
        y1_w = y1_r;
        z1_w = z1_r;
        t1_w = t1_r;
        x2_w = x2_r;
        y2_w = y2_r;
        z2_w = z2_r;
        t2_w = t2_r;
        for (i=0; i<4; i=i+1) begin
            i_a[i] = 0;
            i_b[i] = 0;
        end
        i_montgomery1_start = 0;
        for(i=0; i<2; i=i+1) begin
            MA_a[i] = 0;
            MA_b[i] = 0;
            MS_a[i] = 0;
            MS_b[i] = 0;
        end
        finished_w = 0;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    // i_montgomery1_start = 1;
                    x1_w = i_x1;
                    y1_w = i_y1;
                    z1_w = i_z1;
                    t1_w = i_t1;
                    x2_w = i_x2;
                    y2_w = i_y2;
                    z2_w = i_z2;
                    t2_w = i_t2;
                    if (i_doubling) begin
                        state_w = S_5;
                    end else if(i_initial) begin    // calculate XR, YR
                        state_w = S_4;
                        i_montgomery1_start = 1;
                        i_a[0] = i_x1;
                        i_b[0] = 1;
                        i_a[1] = i_y1;
                        i_b[1] = 1;
                        i_a[2] = i_x1;
                        i_b[2] = i_y1;
                        i_a[3] = 1;
                        i_b[3] = 1;
                        x1_w = i_x1;
                        y1_w = i_y1;
                        z1_w = 1;
                    end else begin
                        state_w = S_1;
                    end
                end
            end
            S_1: begin
                state_w = S_2;
                i_montgomery1_start = 1;
                MA_a[0] = y2_r;
                MA_b[0] = x2_r;
                MA_a[1] = y1_r;
                MA_b[1] = x1_r;
                MS_a[0] = y1_r;
                MS_b[0] = x1_r;
                MS_a[1] = y2_r;
                MS_b[1] = x2_r;
                i_a[0] = MS_result[0];
                i_b[0] = MA_result[0];
                i_a[1] = MA_result[1];
                i_b[1] = MS_result[1];
                i_a[2] = z1_r;
                i_b[2] = t2_r;
                i_a[3] = t1_r;
                i_b[3] = z2_r;
            end
            S_2: begin
                if (o_montgomery_finished) begin
                    state_w = S_3;
                    MA_a[0] = o_montgomery[3];
                    MA_b[0] = o_montgomery[2];
                    MS_a[0] = o_montgomery[3];
                    MS_b[0] = o_montgomery[2];
                    MA_a[1] = o_montgomery[1];
                    MA_b[1] = o_montgomery[0];
                    MS_a[1] = o_montgomery[1];
                    MS_b[1] = o_montgomery[0];
                    x1_w = MA_result[0];        // E
                    y1_w = MS_result[0];        // H
                    z1_w = MS_result[1];        // F
                    t1_w = MA_result[1];        // G
                end
            end
            S_3: begin
                MA_a[0] = x1_r;
                MA_b[0] = x1_r;
                MA_a[1] = y1_r;
                MA_b[1] = y1_r;
                x1_w = MA_result[0];            // 2 * E
                y1_w = MA_result[1];            // 2 * H
                state_w = S_4;
                i_montgomery1_start = 1;
                i_a[0] = x1_w;    // E*F -> x3
                i_b[0] = z1_r;
                i_a[1] = y1_w;    // H*G -> y3
                i_b[1] = t1_r;
                i_a[2] = x1_w;    // E*H -> t3
                i_b[2] = y1_w;
                i_a[3] = z1_r;    // F*G -> z3
                i_b[3] = t1_r;
            end
            S_4: begin
                if (o_montgomery_finished) begin
                    state_w = S_IDLE;
                    finished_w = 1;
                    x1_w = o_montgomery[0];
                    y1_w = o_montgomery[1];
                    t1_w = o_montgomery[2];
                    z1_w = o_montgomery[3];
                end
            end
            S_5: begin
                state_w = S_6;
                i_montgomery1_start = 1;
                MA_a[0] = y1_r;
                MA_b[0] = x1_r;
                x1_w = MA_result[0];    // x1 + y1
                i_a[0] = x1_r;            // x1^2 (A)
                i_b[0] = x1_r;
                i_a[1] = y1_r;            // y1^2 (B)
                i_b[1] = y1_r;
                i_a[2] = z1_r;            // z1^2 (C)
                i_b[2] = z1_r;
                i_a[3] = x1_w;        // (x1 + y1)^2
                i_b[3] = x1_w;
            end
            S_6: begin
                if (o_montgomery_finished) begin
                    state_w = S_7;
                    MA_a[0] = o_montgomery[1];
                    MA_b[0] = o_montgomery[0];
                    MS_a[0] = o_montgomery[1];
                    MS_b[0] = o_montgomery[0];
                    MA_a[1] = o_montgomery[2];
                    MA_b[1] = o_montgomery[2];
                    x1_w = MA_result[0];    // y1^2 + x1^2 (A+B)
                    y1_w = MS_result[0];    // y1^2 - x1^2 (G)
                    z1_w = MA_result[1];    // 2 * z1^2 (C)
                    t1_w = o_montgomery[3]; // (x1 + y1)^2
                end
            end
            S_7: begin
                state_w = S_4;
                i_montgomery1_start = 1;
                MS_a[0] = t1_r;
                MS_b[0] = x1_r;
                MS_a[1] = y1_r;
                MS_b[1] = z1_r;
                x1_w = MS_result[0];        // E = (x1 + y1)^2 - (A+B)
                y1_w = MS_result[1];        // F = G-C
                z1_w = y1_r; // G
                t1_w = `N - x1_r;        // H = -A-B
                i_a[0] = x1_w; // E*F
                i_b[0] = y1_w;
                i_a[1] = z1_w; // G*H
                i_b[1] = t1_w;
                i_a[2] = x1_w; // E*H
                i_b[2] = t1_w;
                i_a[3] = y1_w; // F*G
                i_b[3] = z1_w;
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state_r <= S_IDLE;
            x1_r <= 0;
            y1_r <= 0;
            z1_r <= 0;
            t1_r <= 0;
            x2_r <= 0;
            y2_r <= 0;
            z2_r <= 0;
            t2_r <= 0;
            finished_r <= 0;
        end else begin
            state_r <= state_w;
            x1_r <= x1_w;
            y1_r <= y1_w;
            z1_r <= z1_w;
            t1_r <= t1_w;
            x2_r <= x2_w;
            y2_r <= y2_w;
            z2_r <= z2_w;
            t2_r <= t2_w;
            finished_r <= finished_w;
        end
    end

endmodule

module modularAdd (
   input [254:0] a, b,
   output [254:0] result
);
    logic [255:0] add;
    logic [255:0] tmp;
    logic [254:0] modularAdd;
    assign result = modularAdd;
    always_comb begin
        add = a + b;
        tmp = add - `N;
        modularAdd = (tmp[255]) ? add : tmp;
    end

endmodule

module modularSub (
    input [254:0] a, b,
    output [254:0] result
);
    logic [255:0] sub;
    logic [254:0] modularSub;
    assign result = modularSub;
    always_comb begin
        sub = a - b;
        modularSub = (sub[255]) ? sub + `N : sub;
    end

endmodule