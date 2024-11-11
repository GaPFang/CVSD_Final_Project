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

    typedef enum logic {
        S_READ,
        S_WAIT
    } state_t;

    logic in_ready_r, in_ready_w;
    logic out_valid_r, out_valid_w;
    logic [63:0] out_data_r, out_data_w;
    
    logic [767:0] in_data_r, in_data_w;
    logic [3:0] read_cnt_r, read_cnt_w;

    logic [255:0] M = in_data_r[767:512];
    logic [255:0] xp = in_data_r[511:256];
    logic [255:0] yp = in_data_r[255:0];
    state_t [3:0] state_r, state_w;

    assign o_in_ready = in_ready_r;
    assign o_out_valid = out_valid_r;
    assign o_out_data = out_data_r;

    always_comb begin
        in_ready_w = in_ready_r;
        out_valid_w = 0;
        out_data_w = 64'b0;
        in_data_w = in_data_r;
        state_w = state_r;
        read_cnt_w = read_cnt_r;

        case (state_r)
            S_READ: begin
                in_ready_w = 1'b1;
                if (i_in_valid & o_in_ready) begin
                    in_data_w[767-(64*read_cnt_r) -: 64] = i_in_data;
                    read_cnt_w = read_cnt_r + 1;
                    if (read_cnt_r == 12) begin
                        read_cnt_w = 4'b0;
                        state_w = S_WAIT;
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
            read_cnt_r <= 4'b0;
            state_r <= S_READ;
        end else begin
            in_ready_r <= in_ready_w;
            out_valid_r <= out_valid_w;
            out_data_r <= out_data_w;
            in_data_r <= in_data_w;
            read_cnt_r <= read_cnt_w;
            state_r <= state_w;
        end
    end

endmodule