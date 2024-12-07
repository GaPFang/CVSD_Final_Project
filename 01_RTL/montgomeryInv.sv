module MontgomeryInv (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [254:0] i_x,
    output reg [254:0] o_montgomeryInv,
    output reg         o_finished
);

	localparam N = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949;

	// Phase1
	logic [10:0] k_r, k_w;
	logic [256:0] Luv_r, Ruv_r, Lrs_r, Rrs_r;
	logic [256:0] Luv_w, Ruv_w, Lrs_w, Rrs_w;
	logic [256:0] hLuv_r, dLuv_r, hRrs_r, dRrs_r, dLrs_r, addLuv_r, subLuv_r;
	logic [256:0] hLuv_w, dLuv_w, hRrs_w, dRrs_w, dLrs_w, addLuv_w, subLuv_w;
	logic SLuv_r, SRuv_r, nSLuv_r;
	logic SLuv_w, SRuv_w, nSLuv_w;
	wire [256:0] subLrs, hLrs, addLrs;
	wire nSLrs;

	// S_PHASE1_END state
	assign subLrs = Lrs_r - Rrs_r;
	assign nSLrs = subLrs[256];
	// S_LOOP2 state
	assign hLrs = { Lrs_r[256], Lrs_r[256:1] };
	assign addLrs = Lrs_r + Rrs_r;

	typedef enum logic [2:0] {
		S_IDLE,
		S_READY,
		S_LOOP1_STEP1,
		S_LOOP1_STEP2,
		S_LOOP1_UPDATE,
		S_PHASE1_END,
		S_LOOP2
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
		dLuv_w = dLuv_r;
		hRrs_w = hRrs_r;
		dRrs_w = dRrs_r;
		dLrs_w = dLrs_r;
		addLuv_w = addLuv_r;
		subLuv_w = subLuv_r;
		SLuv_w = SLuv_r;
		SRuv_w = SRuv_r;
		nSLuv_w = nSLuv_r;
		case(state_r)
			S_IDLE: begin
				if(i_start) begin
					Ruv_w = { i_x, 1'b0 };
					state_w = S_READY;
				end
			end
			S_READY: begin
				state_w = S_LOOP1_STEP1;
				Luv_w = { Luv_r[256], Luv_r[256:1] } + Ruv_r;
				Ruv_w = N;
				Lrs_w = Lrs_r + Rrs_r;
				Rrs_w = 0;
			end
			S_LOOP1_STEP1: begin
				SLuv_w = Luv_r[256];
				SRuv_w = Ruv_r[256];
				hLuv_w = { Luv_r[256], Luv_r[256:1] };
				dLuv_w = { Luv_r[255:0], 1'b0 };
				hRrs_w = { Rrs_r[256], Rrs_r[256:1] };
				dRrs_w = { Rrs_r[255:0], 1'b0 };
				dLrs_w = { Lrs_r[255:0], 1'b0 };
				addLuv_w = { Luv_r[256], Luv_r[256:1] } + Ruv_r;
				subLuv_w = { Luv_r[256], Luv_r[256:1] } - Ruv_r;
				state_w = S_LOOP1_STEP2;
			end
			S_LOOP1_STEP2: begin
				nSLuv_w = (SLuv_r ^ SRuv_r) ? addLuv_r[256] : subLuv_r[256];
				state_w = S_LOOP1_UPDATE;
			end
			S_LOOP1_UPDATE: begin
				if (Luv_r[1] == 1'b0) begin
					if (Luv_r == 0) begin
						state_w =  S_PHASE1_END;
					end else begin
						Luv_w = hLuv_r;
						Rrs_w = dRrs_r;
						k_w = k_r + 1;
						state_w =  S_LOOP1_STEP1;
					end
				end
				else begin
					Lrs_w = Lrs_r + Rrs_r;
					Luv_w = (SLuv_r ^ SRuv_r) ? addLuv_r : subLuv_r;
					k_w = k_r + 1;
					if (nSLuv_r == ((~SLuv_r & ~SRuv_r) | (~SLuv_r & SRuv_r))) begin
						Ruv_w = hLuv_r;
						Rrs_w = dLrs_r;
					end else begin
						Rrs_w = dRrs_r;
					end
					state_w =  S_LOOP1_STEP1;
				end
			end
			S_PHASE1_END: begin
				Lrs_w = (nSLrs) ? subLrs + N : subLrs;
				Rrs_w = N;
				state_w = S_LOOP2;
			end
			S_LOOP2: begin
				if (k_r == N) begin
					o_montgomeryInv = Lrs_r;
					o_finished = 1;
					state_w = S_IDLE;
					k_w = 0;
					Luv_w = 0;
					Ruv_w = 0;
					Lrs_w = 0;
					Rrs_w = 1;
				end else begin
					k_w = k_r + 1;
					Lrs_w = (Lrs_r[0]) ? addLrs[256:1] : hLuv_r;
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
			dLuv_r <= 0;
			hRrs_r <= 0;
			dRrs_r <= 0;
			dLrs_r <= 0;
			addLuv_r <= 0;
			subLuv_r <= 0;
			SLuv_r <= 0;
			SRuv_r <= 0;
			nSLuv_r <= 0;
			o_finished <= 0;
		end else begin
			state_r <= state_w;
			k_r <= k_w;
			Luv_r <= Luv_w;
			Ruv_r <= Ruv_w;
			Lrs_r <= Lrs_w;
			Rrs_r <= Rrs_w;
			hLuv_r <= hLuv_w;
			dLuv_r <= dLuv_w;
			hRrs_r <= hRrs_w;
			dRrs_r <= dRrs_w;
			dLrs_r <= dLrs_w;
			addLuv_r <= addLuv_w;
			subLuv_r <= subLuv_w;
			SLuv_r <= SLuv_w;
			SRuv_r <= SRuv_w;
			nSLuv_r <= nSLuv_w;
		end
	end

endmodule
