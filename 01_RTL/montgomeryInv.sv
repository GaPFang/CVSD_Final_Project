module MontgomeryInv (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [254:0] i_x,
    output [254:0] o_montgomeryInv,
    output         o_finished
);

	logic [10:0] k_r, k_w;
	logic signed [256:0] Luv_r, Ruv_r, Lrs_r, Rrs_r;
	logic signed [256:0] Luv_w, Ruv_w, Lrs_w, Rrs_w;
	logic signed [256:0] hLuv_r, addLuv_r, subLuv_r;
	logic signed [256:0] hLuv_w, addLuv_w, subLuv_w;
	logic SLuv_r, SRuv_r;
	logic SLuv_w, SRuv_w;
	logic o_finished_r, o_finished_w;
	wire [256:0] subLrs, hLrs, addLrs;
	wire nSLrs;

	wire hLuv = Luv_r >>> 1;

	assign subLrs = Lrs_r - Rrs_r;
	assign nSLrs = subLrs[256];
	assign hLrs = Lrs_r >>> 1;
	assign addLrs = Lrs_r + Rrs_r;
	assign o_finished = o_finished_r;
	assign o_montgomeryInv = Lrs_r;

	typedef enum logic [1:0] {
		S_IDLE,
		S_PHASE1_1,
		S_PHASE1_2,
		S_PHASE2
	} state_t;

	state_t state_r, state_w;

	always_comb begin
		state_w = state_r;
		k_w = k_r;
		Luv_w = Luv_r;
		Ruv_w = Ruv_r;
		Lrs_w = Lrs_r;
		Rrs_w = Rrs_r;
		hLuv_w = hLuv_r;
		SLuv_w = SLuv_r;
		SRuv_w = SRuv_r;
		o_finished_w = 0;
		addLuv_w = addLuv_r;
		subLuv_w = subLuv_r;
		case(state_r)
			S_IDLE: begin
				if(i_start) begin
					k_w = 0;
					Luv_w = i_x << 1;
					Ruv_w = `N;
					Lrs_w = 1;
					Rrs_w = 0;
					state_w = S_PHASE1_1;
				end
			end
			S_PHASE1_1: begin
				SLuv_w = Luv_r[256];
				SRuv_w = Ruv_r[256];
				hLuv_w = Luv_r >>> 1;
				addLuv_w = hLuv_w + Ruv_r;
				subLuv_w = hLuv_w - Ruv_r;
				state_w = S_PHASE1_2;
			end
			S_PHASE1_2: begin
				if (Luv_r[1] == 1'b0) begin
					if (SLuv_r == (Luv_r > 0)) begin
						Lrs_w = (subLrs[256]) ? subLrs + `N : subLrs;
						Rrs_w = `N;
						state_w = S_PHASE2;
					end else begin
						Luv_w = hLuv_r;
						Rrs_w = Rrs_r << 1;
						k_w = k_r + 1;
						state_w =  S_PHASE1_1;
					end
				end else begin
					Lrs_w = Lrs_r + Rrs_r;
					Luv_w = (SLuv_r ^ SRuv_r) ? addLuv_r : subLuv_r;
					k_w = k_r + 1;
					if (Luv_w[256] != SLuv_r) begin
						Ruv_w = hLuv_r;
						Rrs_w = Lrs_r << 1;
					end else begin
						Rrs_w = Rrs_r << 1;
					end
					state_w =  S_PHASE1_1;
				end
			end
			S_PHASE2: begin
				if (k_r == 255) begin
					o_finished_w = 1;
					state_w = S_IDLE;
				end else begin
					k_w = k_r - 1;
					Lrs_w = (Lrs_r[0]) ? addLrs >>> 1 : hLrs;
				end
			end
		endcase
	end

	always_ff @(posedge i_clk) begin
		if(i_rst) begin
			state_r <= S_IDLE;
			k_r <= 0;
			Luv_r <= 0;
			Ruv_r <= 0;
			Lrs_r <= 0;
			Rrs_r <= 1;
			hLuv_r <= 0;
			addLuv_r <= 0;
			subLuv_r <= 0;
			SLuv_r <= 0;
			SRuv_r <= 0;
			o_finished_r <= 0;
		end else begin
			state_r <= state_w;
			k_r <= k_w;
			Luv_r <= Luv_w;
			Ruv_r <= Ruv_w;
			Lrs_r <= Lrs_w;
			Rrs_r <= Rrs_w;
			hLuv_r <= hLuv_w;
			addLuv_r <= addLuv_w;
			subLuv_r <= subLuv_w;
			SLuv_r <= SLuv_w;
			SRuv_r <= SRuv_w;
			o_finished_r <= o_finished_w;
		end
	end

endmodule
