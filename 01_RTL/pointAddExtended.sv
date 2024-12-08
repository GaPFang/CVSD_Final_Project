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

    localparam dR = 255'h164115ad394fe29372c9c903de0c43480850c3bbd7e314b9c076c5ff6fa3f4fd;
    localparam R_pow_8 = 255'h3f44c9b21;
    localparam R_pow_4 = 255'h1FD11;
    localparam R_pow_2 = 255'h169;
    localparam R_pow_1 = 255'h13;
    
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

    // logic [254:0] x1_r, y1_r, z1_r, t1_r, x2_r, y2_r, z2_r, t2_r, x1x2_r, y1y2_r, x1y2_r, x2y1_r, z1z2_r, z1z2z1z2_r, x1x2y1y2_r, dx1x2y1y2_r, z1z2_x1y2_x2y1_r, z1z2_x1x2_y1y2_r, x3_r, y3_r, z3_r, t3_r;
    // logic [254:0] x1_w, y1_w, z1_w, t1_w, x2_w, y2_w, z2_w, t2_w, x1x2_w, y1y2_w, x1y2_w, x2y1_w, z1z2_w, z1z2z1z2_w, x1x2y1y2_w, dx1x2y1y2_w, z1z2_x1y2_x2y1_w, z1z2_x1x2_y1y2_w, x3_w, y3_w, z3_w, t3_w;
    logic [254:0] x1_r, y1_r, z1_r, t1_r, x2_r, y2_r, z2_r, t2_r, x3_r, y3_r, z3_r, t3_r;
    logic [254:0] x1_w, y1_w, z1_w, t1_w, x2_w, y2_w, z2_w, t2_w, x3_w, y3_w, z3_w, t3_w;
    logic [254:0] MA_a [0:1], MA_b [0:1], MA_result [0:1];
    logic [254:0] MS_a [0:1], MS_b [0:1], MS_result [0:1];

    // logic [254:0] x1y2_x2y1_r, x1x2_y1y2_r, z1z2z1z2_add_dx1x2y1y2_r, z1z2z1z2_sub_dx1x2y1y2_r;
    // logic [254:0] x1y2_x2y1_w, x1x2_y1y2_w, z1z2z1z2_add_dx1x2y1y2_w, z1z2z1z2_sub_dx1x2y1y2_w;

    logic [254:0] tmp_r[0:3], tmp_w[0:3];

    logic i_montgomery_start_r, i_montgomery_start_w;
    // logic [254:0] i_a1_r, i_b1_r, i_a2_r, i_b2_r, i_a1_w, i_b1_w, i_a2_w, i_b2_w;
    logic [254:0] i_a_r[0:3], i_b_r[0:3], i_a_w[0:3], i_b_w[0:3];
    logic [254:0] o_montgomery[0:3];
    logic o_montgomery_finished;

    integer i, j;

    assign o_x3 = x3_r;
    assign o_y3 = y3_r;
    assign o_z3 = z3_r;
    assign o_t3 = t3_r;
    assign o_finished = finished_r;
    
    numberMul numberMul0(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery_start_r),
        .i_a(i_a_r[0]),
        .i_b(i_b_r[0]),
        .o_montgomery(o_montgomery[0]),
        .o_finished(o_montgomery_finished)
    );

    numberMul numberMul1(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery_start_r),
        .i_a(i_a_r[1]),
        .i_b(i_b_r[1]),
        .o_montgomery(o_montgomery[1]),
        .o_finished()
    );

    numberMul numberMul2(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery_start_r),
        .i_a(i_a_r[2]),
        .i_b(i_b_r[2]),
        .o_montgomery(o_montgomery[2]),
        .o_finished()
    );

    numberMul numberMul3(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery_start_r),
        .i_a(i_a_r[3]),
        .i_b(i_b_r[3]),
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

    function [254:0] modularSubfunc;
        input [254:0] a, b;
        logic [256:0] sub;
        localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
        begin
            sub = a + N - b;
            modularSubfunc = sub;
            if (sub > N) begin
                modularSubfunc = sub - N;
            end
        end
    endfunction

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
        // x1x2_w = x1x2_r;
        // y1y2_w = y1y2_r;
        // x1y2_w = x1y2_r;
        // x2y1_w = x2y1_r;
        // z1z2_w = z1z2_r;
        // z1z2z1z2_w = z1z2z1z2_r;
        // x1x2y1y2_w = x1x2y1y2_r;
        // dx1x2y1y2_w = dx1x2y1y2_r;
        // z1z2_x1y2_x2y1_w = z1z2_x1y2_x2y1_r;
        // z1z2_x1x2_y1y2_w = z1z2_x1x2_y1y2_r;
        x3_w = x3_r;
        y3_w = y3_r;
        z3_w = z3_r;
        t3_w = t3_r;
        // x1y2_x2y1_w = x1y2_x2y1_r;
        // x1x2_y1y2_w = x1x2_y1y2_r;
        // z1z2z1z2_add_dx1x2y1y2_w = z1z2z1z2_add_dx1x2y1y2_r;
        // z1z2z1z2_sub_dx1x2y1y2_w = z1z2z1z2_sub_dx1x2y1y2_r;
        i_montgomery_start_w = 0;
        for(i=0; i<4; i=i+1) begin
            i_a_w[i] = i_a_r[i];
            i_b_w[i] = i_b_r[i];
            tmp_w[i] = tmp_r[i];
        end
        for(i=0; i<2; i=i+1) begin
            MA_a[i] = 0;
            MA_b[i] = 0;
            MS_a[i] = 0;
            MS_b[i] = 0;
        end
        // i_a1_w = 0;
        // i_b1_w = 0;
        // i_a2_w = 0;
        // i_b2_w = 0;
        finished_w = 0;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    // i_montgomery_start_w = 1;
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
                        i_montgomery_start_w = 1;
                        i_a_w[0] = i_x1;
                        i_b_w[0] = 1;
                        i_a_w[1] = i_y1;
                        i_b_w[1] = 1;
                        i_a_w[2] = i_x1;
                        i_b_w[2] = i_y1;
                        i_a_w[3] = 1;
                        i_b_w[3] = 1;
                        x3_w = i_x1;
                        y3_w = i_y1;
                        z3_w = 1;
                    end else begin
                        state_w = S_1;

                    end
                end
            end
            S_1: begin
                state_w = S_2;
                i_montgomery_start_w = 1;
                MA_a[0] = y2_r;
                MA_b[0] = x2_r;
                MA_a[1] = y1_r;
                MA_b[1] = x1_r;
                MS_a[0] = y1_r;
                MS_b[0] = x1_r;
                MS_a[1] = y2_r;
                MS_b[1] = x2_r;
                // i_a_w[0] = modularSub(y1_r, x1_r);
                // i_b_w[0] = modularAdd(y2_r, x2_r);
                // i_a_w[1] = modularAdd(y1_r, x1_r);
                // i_b_w[1] = modularSub(y2_r, x2_r);
                i_a_w[0] = MS_result[0];
                i_b_w[0] = MA_result[0];
                i_a_w[1] = MA_result[1];
                i_b_w[1] = MS_result[1];
                i_a_w[2] = z1_r;
                i_b_w[2] = t2_r;
                i_a_w[3] = t1_r;
                i_b_w[3] = z2_r;
            end
            S_2: begin
                if (o_montgomery_finished) begin
                    state_w = S_3;
                    // i_montgomery_start_w = 1;
                    MA_a[0] = o_montgomery[3];
                    MA_b[0] = o_montgomery[2];
                    MS_a[0] = o_montgomery[3];
                    MS_b[0] = o_montgomery[2];
                    MA_a[1] = o_montgomery[1];
                    MA_b[1] = o_montgomery[0];
                    MS_a[1] = o_montgomery[1];
                    MS_b[1] = o_montgomery[0];
                    tmp_w[0] = MA_result[0];
                    tmp_w[1] = MS_result[0];
                    tmp_w[2] = MS_result[1];
                    tmp_w[3] = MA_result[1];
                    // tmp_w[0] = modularAdd(o_montgomery[3], o_montgomery[2]);    // E
                    // tmp_w[1] = modularSub(o_montgomery[3], o_montgomery[2]);    // H
                    // tmp_w[2] = modularSub(o_montgomery[1], o_montgomery[0]);    // F
                    // tmp_w[3] = modularAdd(o_montgomery[1], o_montgomery[0]);    // G
                end
            end
            S_3: begin
                MA_a[0] = tmp_r[0];
                MA_b[0] = tmp_r[0];
                MA_a[1] = tmp_r[1];
                MA_b[1] = tmp_r[1];
                tmp_w[0] = MA_result[0];
                tmp_w[1] = MA_result[1];
                // tmp_w[0] = modularAdd(tmp_r[0], tmp_r[0]);  // 2 * E
                // tmp_w[1] = modularAdd(tmp_r[1], tmp_r[1]);  // 2 * H
                state_w = S_4;
                i_montgomery_start_w = 1;
                i_a_w[0] = tmp_w[0];    // E*F -> x3
                i_b_w[0] = tmp_r[2];
                i_a_w[1] = tmp_w[1];    // H*G -> y3
                i_b_w[1] = tmp_r[3];
                i_a_w[2] = tmp_w[0];    // E*H -> t3
                i_b_w[2] = tmp_w[1];
                i_a_w[3] = tmp_r[2];    // F*G -> z3
                i_b_w[3] = tmp_r[3];
            end
            S_4: begin
                if (o_montgomery_finished) begin
                    state_w = S_IDLE;
                    finished_w = 1;
                    x3_w = o_montgomery[0];
                    y3_w = o_montgomery[1];
                    t3_w = o_montgomery[2];
                    z3_w = o_montgomery[3];
                end
            end
            S_5: begin
                state_w = S_6;
                i_montgomery_start_w = 1;
                MA_a[0] = y1_r;
                MA_b[0] = x1_r;
                tmp_w[0] = MA_result[0];
                // tmp_w[0] = modularAdd(x1_r, y1_r); // x1 + y1
                i_a_w[0] = x1_r;    // x1^2 (A)
                i_b_w[0] = x1_r;
                i_a_w[1] = y1_r;    // y1^2 (B)
                i_b_w[1] = y1_r;
                i_a_w[2] = z1_r;    // z1^2 (C)
                i_b_w[2] = z1_r;
                i_a_w[3] = tmp_w[0];    // (x1 + y1)^2
                i_b_w[3] = tmp_w[0];
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
                    tmp_w[0] = MA_result[0];
                    tmp_w[1] = MS_result[0];
                    tmp_w[2] = MA_result[1];
                    // tmp_w[0] = modularAdd(o_montgomery[1], o_montgomery[0]); // y1^2 + x1^2 (A+B)
                    // tmp_w[1] = modularSub(o_montgomery[1], o_montgomery[0]); // y1^2 - x1^2 (G)
                    // tmp_w[2] = modularAdd(o_montgomery[2], o_montgomery[2]); // 2 * z1^2 (C)
                    tmp_w[3] = o_montgomery[3]; // (x1 + y1)^2
                end
            end
            S_7: begin
                state_w = S_4;
                i_montgomery_start_w = 1;
                MS_a[0] = tmp_r[3];
                MS_b[0] = tmp_r[0];
                MS_a[1] = tmp_r[1];
                MS_b[1] = tmp_r[2];
                tmp_w[0] = MS_result[0];
                tmp_w[1] = MS_result[1];
                // tmp_w[0] = modularSub(tmp_r[3], tmp_r[0]); // E = (x1 + y1)^2 - (A+B)
                // tmp_w[1] = modularSub(tmp_r[1], tmp_r[2]); // F = G-C
                tmp_w[2] = tmp_r[1]; // G
                tmp_w[3] = modularSubfunc(0, tmp_r[0]); // H = -A-B
                i_a_w[0] = tmp_w[0]; // E*F
                i_b_w[0] = tmp_w[1];
                i_a_w[1] = tmp_w[2]; // G*H
                i_b_w[1] = tmp_w[3];
                i_a_w[2] = tmp_w[0]; // E*H
                i_b_w[2] = tmp_w[3];
                i_a_w[3] = tmp_w[1]; // F*G
                i_b_w[3] = tmp_w[2];
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
            // x1x2_r <= 0;
            // y1y2_r <= 0;
            // x1y2_r <= 0;
            // x2y1_r <= 0;
            // z1z2_r <= 0;
            // z1z2z1z2_r <= 0;
            // x1x2y1y2_r <= 0;
            // dx1x2y1y2_r <= 0;
            // z1z2_x1y2_x2y1_r <= 0;
            // z1z2_x1x2_y1y2_r <= 0;
            x3_r <= 0;
            y3_r <= 0;
            z3_r <= 0;
            t3_r <= 0;
            // x1y2_x2y1_r <= 0;
            // x1x2_y1y2_r <= 0;
            // z1z2z1z2_add_dx1x2y1y2_r <= 0;
            // z1z2z1z2_sub_dx1x2y1y2_r <= 0;
            i_montgomery_start_r <= 0;
            for(j=0; j<4; j=j+1) begin
                i_a_r[j] <= 0;
                i_b_r[j] <= 0;
                tmp_r[j] <= 0;
            end
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
            // x1x2_r <= x1x2_w;
            // y1y2_r <= y1y2_w;
            // x1y2_r <= x1y2_w;
            // x2y1_r <= x2y1_w;
            // z1z2_r <= z1z2_w;
            // z1z2z1z2_r <= z1z2z1z2_w;
            // x1x2y1y2_r <= x1x2y1y2_w;
            // dx1x2y1y2_r <= dx1x2y1y2_w;
            // z1z2_x1y2_x2y1_r <= z1z2_x1y2_x2y1_w;
            // z1z2_x1x2_y1y2_r <= z1z2_x1x2_y1y2_w;
            x3_r <= x3_w;
            y3_r <= y3_w;
            z3_r <= z3_w;
            t3_r <= t3_w;
            // x1y2_x2y1_r <= x1y2_x2y1_w;
            // x1x2_y1y2_r <= x1x2_y1y2_w;
            // z1z2z1z2_add_dx1x2y1y2_r <= z1z2z1z2_add_dx1x2y1y2_w;
            // z1z2z1z2_sub_dx1x2y1y2_r <= z1z2z1z2_sub_dx1x2y1y2_w;
            i_montgomery_start_r <= i_montgomery_start_w;
            for(j=0; j<4; j=j+1) begin
                i_a_r[j] <= i_a_w[j];
                i_b_r[j] <= i_b_w[j];
                tmp_r[j] <= tmp_w[j];
            end
            finished_r <= finished_w;
        end
    end

endmodule

module modularAdd (
   input [254:0] a, b,
   output [254:0] result
);
    logic [256:0] add;
    logic [254:0] modularAdd;
    localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
    assign result = modularAdd;
    always_comb begin
        add = a + b;
        modularAdd = add;
        if (add > N) begin
            modularAdd = add - N;
    end
    end
    

endmodule

module modularSub (
    input [254:0] a, b,
    output [254:0] result
);
    logic [256:0] sub;
    logic [254:0] modularSub;
    localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
    assign result = modularSub;
    always_comb begin
        sub = a + N - b;
        modularSub = sub;
        if (sub > N) begin
            modularSub = sub - N;
        end
    end
endmodule

    