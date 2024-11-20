module PointAdd(
    input i_clk,
    input i_rst,
    input i_start,
    input [254:0] i_x1,
    input [254:0] i_y1,
    input [254:0] i_z1,
    input [254:0] i_x2,
    input [254:0] i_y2,
    input [254:0] i_z2,
    output [254:0] o_x3,
    output [254:0] o_y3,
    output [254:0] o_z3,
    output o_finished
);

    localparam dR = 255'h164115ad394fe29372c9c903de0c43480850c3bbd7e314b9c076c5ff6fa3f4fd;
    localparam R_pow_8 = 255'h3f44c9b21;

    logic finished_r, finished_w;

    typedef enum logic [3:0] {
        S_IDLE,
        S_1,
        S_2,
        S_3,
        S_4,
        S_5,
        S_6,
        S_7,
        S_8
    } state_t;

    state_t state_r, state_w;

    logic [254:0] x1_r, y1_r, z1_r, x2_r, y2_r, z2_r, x1x2_r, y1y2_r, x1y2_r, x2y1_r, z1z2_r, z1z2z1z2_r, x1x2y1y2_r, dx1x2y1y2_r, z1z2_x1y2_x2y1_r, z1z2_x1x2_y1y2_r, x3_r, y3_r, z3_r;
    logic [254:0] x1_w, y1_w, z1_w, x2_w, y2_w, z2_w, x1x2_w, y1y2_w, x1y2_w, x2y1_w, z1z2_w, z1z2z1z2_w, x1x2y1y2_w, dx1x2y1y2_w, z1z2_x1y2_x2y1_w, z1z2_x1x2_y1y2_w, x3_w, y3_w, z3_w;

    logic [254:0] x1y2_x2y1_r, x1x2_y1y2_r, z1z2z1z2_add_dx1x2y1y2_r, z1z2z1z2_sub_dx1x2y1y2_r;
    logic [254:0] x1y2_x2y1_w, x1x2_y1y2_w, z1z2z1z2_add_dx1x2y1y2_w, z1z2z1z2_sub_dx1x2y1y2_w;

    logic i_montgomery_start_r, i_montgomery_start_w;
    logic [254:0] i_a1_r, i_b1_r, i_a2_r, i_b2_r, i_a1_w, i_b1_w, i_a2_w, i_b2_w;
    logic [254:0] o_montgomery1, o_montgomery2;
    logic o_montgomery_finished;

    assign o_x3 = x3_r;
    assign o_y3 = y3_r;
    assign o_z3 = z3_r;
    assign o_finished = finished_r;
    
    Montgomery montgomery1(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery_start_r),
        .i_a(i_a1_r),
        .i_b(i_b1_r),
        .o_montgomery(o_montgomery1),
        .o_finished(o_montgomery_finished)
    );

    Montgomery montgomery2(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_montgomery_start_r),
        .i_a(i_a2_r),
        .i_b(i_b2_r),
        .o_montgomery(o_montgomery2),
        .o_finished()
    );

    function [254:0] modularAdd;
        input [254:0] a, b;
        logic [256:0] add;
        localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
        begin
            add = a + b;
            modularAdd = add;
            if (add > N) begin
                modularAdd = add - N;
            end
        end
    endfunction

    function [254:0] modularSub;
        input [254:0] a, b;
        logic [256:0] sub;
        localparam N = 257'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
        begin
            sub = a + N - b;
            modularSub = sub;
            if (sub > N) begin
                modularSub = sub - N;
            end
        end
    endfunction

    always_comb begin
        state_w = state_r;
        x1_w = x1_r;
        y1_w = y1_r;
        z1_w = z1_r;
        x2_w = x2_r;
        y2_w = y2_r;
        z2_w = z2_r;
        x1x2_w = x1x2_r;
        y1y2_w = y1y2_r;
        x1y2_w = x1y2_r;
        x2y1_w = x2y1_r;
        z1z2_w = z1z2_r;
        z1z2z1z2_w = z1z2z1z2_r;
        x1x2y1y2_w = x1x2y1y2_r;
        dx1x2y1y2_w = dx1x2y1y2_r;
        z1z2_x1y2_x2y1_w = z1z2_x1y2_x2y1_r;
        z1z2_x1x2_y1y2_w = z1z2_x1x2_y1y2_r;
        x3_w = x3_r;
        y3_w = y3_r;
        z3_w = z3_r;
        x1y2_x2y1_w = x1y2_x2y1_r;
        x1x2_y1y2_w = x1x2_y1y2_r;
        z1z2z1z2_add_dx1x2y1y2_w = z1z2z1z2_add_dx1x2y1y2_r;
        z1z2z1z2_sub_dx1x2y1y2_w = z1z2z1z2_sub_dx1x2y1y2_r;
        i_montgomery_start_w = 0;
        i_a1_w = 0;
        i_b1_w = 0;
        i_a2_w = 0;
        i_b2_w = 0;
        finished_w = 0;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_1;
                    i_montgomery_start_w = 1;
                    i_a1_w = i_x1;
                    i_b1_w = i_y2;
                    i_a2_w = i_x2;
                    i_b2_w = i_y1;
                    x1_w = i_x1;
                    y1_w = i_y1;
                    z1_w = i_z1;
                    x2_w = i_x2;
                    y2_w = i_y2;
                    z2_w = i_z2;
                end
            end
            S_1: begin
                if (o_montgomery_finished) begin
                    state_w = S_2;
                    i_montgomery_start_w = 1;
                    x1y2_w = o_montgomery1;
                    x2y1_w = o_montgomery2;
                    i_a1_w = z1_r;
                    i_b1_w = z2_r;
                    i_a2_w = o_montgomery1;
                    i_b2_w = o_montgomery2;
                end
            end
            S_2: begin
                x1y2_x2y1_w = modularAdd(x1y2_r, x2y1_r);
                if (o_montgomery_finished) begin
                    state_w = S_3;
                    i_montgomery_start_w = 1;
                    z1z2_w = o_montgomery1;
                    x1x2y1y2_w = o_montgomery2;
                    i_a1_w = o_montgomery1;
                    i_b1_w = o_montgomery1;
                    i_a2_w = dR;
                    i_b2_w = o_montgomery2;
                end
            end
            S_3: begin
                if (o_montgomery_finished) begin
                    state_w = S_4;
                    i_montgomery_start_w = 1;
                    z1z2z1z2_w = o_montgomery1;
                    dx1x2y1y2_w = o_montgomery2;
                    i_a1_w = x1_r;
                    i_b1_w = x2_r;
                    i_a2_w = y1_r;
                    i_b2_w = y2_r;
                end
            end
            S_4: begin
                z1z2z1z2_add_dx1x2y1y2_w = modularAdd(z1z2z1z2_r, dx1x2y1y2_r);
                z1z2z1z2_sub_dx1x2y1y2_w = modularSub(z1z2z1z2_r, dx1x2y1y2_r);
                if (o_montgomery_finished) begin
                    state_w = S_5;
                    i_montgomery_start_w = 1;
                    x1x2_w = o_montgomery1;
                    y1y2_w = o_montgomery2;
                    i_a1_w = z1z2_r;
                    i_b1_w = x1y2_x2y1_r;
                    i_a2_w = z1z2z1z2_add_dx1x2y1y2_r;
                    i_b2_w = z1z2z1z2_sub_dx1x2y1y2_r;
                end
            end
            S_5: begin
                x1x2_y1y2_w = modularAdd(x1x2_r, y1y2_r);
                if (o_montgomery_finished) begin
                    state_w = S_6;
                    i_montgomery_start_w = 1;
                    z1z2_x1y2_x2y1_w = o_montgomery1;
                    z3_w = o_montgomery2;
                    i_a1_w = z1z2_r;
                    i_b1_w = x1x2_y1y2_r;
                    i_a2_w = o_montgomery1;
                    i_b2_w = z1z2z1z2_sub_dx1x2y1y2_r;
                end
            end
            S_6: begin
                if (o_montgomery_finished) begin
                    state_w = S_7;
                    i_montgomery_start_w = 1;
                    z1z2_x1x2_y1y2_w = o_montgomery1;
                    x3_w = o_montgomery2;
                    i_a1_w = o_montgomery1;
                    i_b1_w = z1z2z1z2_add_dx1x2y1y2_r;
                    i_a2_w = o_montgomery2;
                    i_b2_w = R_pow_8;
                end
            end
            S_7: begin
                if (o_montgomery_finished) begin
                    state_w = S_8;
                    i_montgomery_start_w = 1;
                    y3_w = o_montgomery1;
                    x3_w = o_montgomery2;
                    i_a1_w = o_montgomery1;
                    i_b1_w = R_pow_8;
                    i_a2_w = z3_r;
                    i_b2_w = R_pow_8;
                end
            end
            S_8: begin
                if (o_montgomery_finished) begin
                    state_w = S_IDLE;
                    finished_w = 1;
                    y3_w = o_montgomery1;
                    z3_w = o_montgomery2;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state_r <= S_IDLE;
            x1_r <= 0;
            y1_r <= 0;
            z1_r <= 0;
            x2_r <= 0;
            y2_r <= 0;
            z2_r <= 0;
            x1x2_r <= 0;
            y1y2_r <= 0;
            x1y2_r <= 0;
            x2y1_r <= 0;
            z1z2_r <= 0;
            z1z2z1z2_r <= 0;
            x1x2y1y2_r <= 0;
            dx1x2y1y2_r <= 0;
            z1z2_x1y2_x2y1_r <= 0;
            z1z2_x1x2_y1y2_r <= 0;
            x3_r <= 0;
            y3_r <= 0;
            z3_r <= 0;
            x1y2_x2y1_r <= 0;
            x1x2_y1y2_r <= 0;
            z1z2z1z2_add_dx1x2y1y2_r <= 0;
            z1z2z1z2_sub_dx1x2y1y2_r <= 0;
            i_montgomery_start_r <= 0;
            i_a1_r <= 0;
            i_b1_r <= 0;
            i_a2_r <= 0;
            i_b2_r <= 0;
            finished_r <= 0;
        end else begin
            state_r <= state_w;
            x1_r <= x1_w;
            y1_r <= y1_w;
            z1_r <= z1_w;
            x2_r <= x2_w;
            y2_r <= y2_w;
            z2_r <= z2_w;
            x1x2_r <= x1x2_w;
            y1y2_r <= y1y2_w;
            x1y2_r <= x1y2_w;
            x2y1_r <= x2y1_w;
            z1z2_r <= z1z2_w;
            z1z2z1z2_r <= z1z2z1z2_w;
            x1x2y1y2_r <= x1x2y1y2_w;
            dx1x2y1y2_r <= dx1x2y1y2_w;
            z1z2_x1y2_x2y1_r <= z1z2_x1y2_x2y1_w;
            z1z2_x1x2_y1y2_r <= z1z2_x1x2_y1y2_w;
            x3_r <= x3_w;
            y3_r <= y3_w;
            z3_r <= z3_w;
            x1y2_x2y1_r <= x1y2_x2y1_w;
            x1x2_y1y2_r <= x1x2_y1y2_w;
            z1z2z1z2_add_dx1x2y1y2_r <= z1z2z1z2_add_dx1x2y1y2_w;
            z1z2z1z2_sub_dx1x2y1y2_r <= z1z2z1z2_sub_dx1x2y1y2_w;
            i_montgomery_start_r <= i_montgomery_start_w;
            i_a1_r <= i_a1_w;
            i_b1_r <= i_b1_w;
            i_a2_r <= i_a2_w;
            i_b2_r <= i_b2_w;
            finished_r <= finished_w;
        end
    end

endmodule

    