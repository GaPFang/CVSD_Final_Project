module ed25519 (
    input i_clk,
    input i_rst,
    input i_in_valid,
    input [63:0] i_in_data,
    input i_out_ready,
    output o_in_ready,
    output o_out_valid,
    output [63:0] o_out_data
);

    typedef enum logic [1:0] {
        S_READ,
        S_WAIT_MUL,
        S_WAIT_RED,
        S_OUTPUT
    } state_t;

    state_t state_r, state_w;

    logic in_ready_r, in_ready_w;
    logic out_valid_r, out_valid_w;
    logic [63:0] out_data_r, out_data_w;
    
    logic [767:0] in_data_r, in_data_w;
    logic [3:0] cnt_r, cnt_w;

    wire [254:0] M = in_data_r[766:512];
    wire [254:0] xp = in_data_r[510:256];
    wire [254:0] yp = in_data_r[254:0];
    wire [254:0] zp = in_data_r[766:512];

    logic scalarMul_start_r, scalarMul_start_w, scalarMul_finished;
    wire [254:0] scalarMul_x, scalarMul_y, scalarMul_z;

    logic reduction_start_r, reduction_start_w, reduction_finished;
    wire [254:0] reduction_x, reduction_y;

    assign o_in_ready = in_ready_r;
    assign o_out_valid = out_valid_r;
    assign o_out_data = out_data_r;

    ScalarMul scalarMul1(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(scalarMul_start_r),
        .i_M(M),
        .i_x(xp),
        .i_y(yp),
        .o_x(scalarMul_x),
        .o_y(scalarMul_y),
        .o_z(scalarMul_z),
        .o_finished(scalarMul_finished)
    );

    Reduction reduction1(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(reduction_start_r),
        .i_x(xp),
        .i_y(yp),
        .i_z(zp),
        .o_x(reduction_x),
        .o_y(reduction_y),
        .o_finished(reduction_finished)
    );

    always_comb begin
        in_ready_w = in_ready_r;
        out_valid_w = 0;
        out_data_w = 64'b0;
        in_data_w = in_data_r;
        state_w = state_r;
        cnt_w = cnt_r;
        scalarMul_start_w = 0;
        reduction_start_w = 0;
        case (state_r)
            S_READ: begin
                in_ready_w = 1'b1;
                if (i_in_valid & o_in_ready) begin
                    in_data_w[767-(64*cnt_r) -: 64] = i_in_data;
                    cnt_w = cnt_r + 1;
                    if (cnt_r == 11) begin
                        cnt_w = 4'b0;
                        state_w = S_WAIT_MUL;
                        scalarMul_start_w = 1;
                    end
                end
            end
            S_WAIT_MUL: begin
                if (scalarMul_finished) begin
                    state_w = S_WAIT_RED;
                    reduction_start_w = 1;
                    in_data_w[766:512] = scalarMul_z;
                    in_data_w[510:256] = scalarMul_x;
                    in_data_w[254:0] = scalarMul_y;
                end
            end
            S_WAIT_RED: begin
                if (reduction_finished) begin
                    state_w = S_OUTPUT;
                    in_data_w[510:256] = reduction_x;
                    in_data_w[254:0] = reduction_y;
                end
            end
            S_OUTPUT: begin
                out_valid_w = 1;
                out_data_w = in_data_r[511-(64*cnt_r) -: 64];
                if (i_out_ready & o_out_valid) begin
                    cnt_w = cnt_r + 1;
                    out_data_w = in_data_r[511-(64*cnt_w) -: 64];
                    if (cnt_r == 7) begin
                        cnt_w = 4'b0;
                        state_w = S_READ;
                        out_valid_w = 0;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            in_ready_r <= 1'b0;
            out_valid_r <= 1'b0;
            out_data_r <= 64'b0;
            in_data_r <= 768'b0;
            cnt_r <= 4'b0;
            state_r <= S_READ;
            scalarMul_start_r <= 1'b0;
            reduction_start_r <= 1'b0;
        end else begin
            in_ready_r <= in_ready_w;
            out_valid_r <= out_valid_w;
            out_data_r <= out_data_w;
            in_data_r <= in_data_w;
            cnt_r <= cnt_w;
            state_r <= state_w;
            scalarMul_start_r <= scalarMul_start_w;
            reduction_start_r <= reduction_start_w;
        end
    end

endmodule