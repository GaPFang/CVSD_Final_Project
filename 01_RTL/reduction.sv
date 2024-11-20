module Reduction (
    input i_clk,
    input i_rst,
    input i_start,
    input [254:0] i_x, i_y, i_z,
    output [254:0] o_x, o_y, o_z,
    output o_finished
);
    localparam R_2 = 255'd361;                              // R^2 mod p
    localparam R_2_255 = 255'd714209495693373205673756419;   // R^(2^255+1) mod p
    localparam q_minus_2 = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819947;
    localparam q = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949;

    logic [254:0] zR_r, zR_w;
    logic [254:0] r_r, r_w;
    logic [254:0] x_r, x_w, y_r, y_w;
    logic [7:0] cnt_r, cnt_w;
    logic finished_r, finished_w;

    logic montgomery_start, montgomery_finished;
    logic [254:0] o_montgomery;
    logic [254:0] montgomery_a, montgomery_b;

    assign o_x = x_r;
    assign o_y = y_r;
    assign o_finished = finished_r;

    typedef enum logic [2:0] {
        S_1,    // zR = MM(p, R^2)
        S_2,    // r  = MM(r, r)
        S_3,    // r  = MM(r, zR)
        S_4,    // r  = MM(r, R^(2^255+1))
        S_DIV_X,
        S_DIV_Y,
        S_EVEN
    } state_t;

    state_t state_r, state_w;

    Montgomery montgomery1(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(montgomery_start),
        .i_a(montgomery_a),
        .i_b(montgomery_b),
        .o_montgomery(o_montgomery),
        .o_finished(montgomery_finished)
    );

    always_comb begin
        zR_w = zR_r;
        r_w = r_r;
        x_w = x_r;
        y_w = y_r;
        cnt_w = cnt_r;
        state_w = state_r;
        finished_w = 0;
        montgomery_start = 0;
        montgomery_a = 0;
        montgomery_b = 0;
        case(state_r)
            S_1: begin
                if (i_start) begin
                    montgomery_start = 1;
                    x_w = i_x;
                    y_w = i_y;
                    montgomery_a = i_z;
                    montgomery_b = R_2;
                    r_w = 1;
                end
                if (montgomery_finished) begin
                    zR_w = o_montgomery;
                    state_w = S_2;
                    cnt_w = 254;
                    montgomery_start = 1;
                    montgomery_a = r_w;
                    montgomery_b = r_w;
                end
            end
            S_2: begin
                if (montgomery_finished) begin
                    r_w = o_montgomery;
                    if (q_minus_2[cnt_r]) begin
                        state_w = S_3;
                        montgomery_start = 1;
                        montgomery_a = r_w;
                        montgomery_b = zR_w;
                    end else begin
                        cnt_w = cnt_r - 1;
                        montgomery_start = 1;
                        montgomery_a = r_w;
                        if (cnt_r == 0) begin
                            state_w = S_4;
                            montgomery_b = R_2_255;
                        end else begin
                            montgomery_b = r_w;
                        end
                    end
                end
            end
            S_3: begin
                if (montgomery_finished) begin
                    r_w = o_montgomery;
                    state_w = S_2;
                    cnt_w = cnt_r - 1;
                    montgomery_start = 1;
                    montgomery_a = r_w;
                    if (cnt_r == 0) begin
                        state_w = S_4;
                        montgomery_b = R_2_255;
                    end else begin
                        montgomery_b = r_w;
                    end
                end
            end
            S_4: begin
                if (montgomery_finished) begin
                    r_w = o_montgomery;
                    state_w = S_DIV_X;
                    montgomery_start = 1;
                    montgomery_a = x_r;
                    montgomery_b = r_w;
                end
            end
            S_DIV_X: begin
                if (montgomery_finished) begin
                    x_w = o_montgomery;
                    state_w = S_DIV_Y;
                    montgomery_start = 1;
                    montgomery_a = y_r;
                    montgomery_b = r_w;
                end
            end
            S_DIV_Y: begin
                if (montgomery_finished) begin
                    y_w = o_montgomery;
                    state_w = S_EVEN;
                end
            end
            S_EVEN: begin
                state_w = S_1;
                if (x_r[0]) begin
                    x_w = q - x_r;
                end
                if (y_r[0]) begin
                    y_w = q - y_r;
                end
                finished_w = 1;
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state_r <= S_1;
            zR_r <= 0;
            r_r <= 0;
            x_r <= 0;
            y_r <= 0;
            cnt_r <= 0;
            finished_r <= 0;
        end else begin
            state_r <= state_w;
            zR_r <= zR_w;
            r_r <= r_w;
            x_r <= x_w;
            y_r <= y_w;
            cnt_r <= cnt_w;
            finished_r <= finished_w;
        end
    end

endmodule