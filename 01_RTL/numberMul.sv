module numberMul (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [254:0] i_a, i_b,
    output [254:0] o_montgomery,
    output         o_finished
);
  typedef enum logic [2:0] {
      S_IDLE,
      S_PRECOMP,
      S_CALC,
      S_POST1,
      S_POST2,
      S_POST3
  } state_t;

  localparam cycles1_3 = 7'd85;
  // localparam [15:0] LUT1 [0:63] = '{16'h0, 16'h98, 16'h130, 16'h1C8, 16'h260, 16'h2F8, 16'h390, 16'h428, 16'h4C0, 16'h558, 16'h5F0, 16'h688, 16'h720, 16'h7B8, 16'h850, 16'h8E8, 16'h980, 16'hA18, 16'hAB0, 16'hB48, 16'hBE0, 16'hC78, 16'hD10, 16'hDA8, 16'hE40, 16'hED8, 16'hF70, 16'h1008, 16'h10A0, 16'h1138, 16'h11D0, 16'h1268, 16'h1300, 16'h1398, 16'h1430, 16'h14C8, 16'h1560, 16'h15F8, 16'h1690, 16'h1728, 16'h17C0, 16'h1858, 16'h18F0, 16'h1988, 16'h1A20, 16'h1AB8, 16'h1B50, 16'h1BE8, 16'h1C80, 16'h1D18, 16'h1DB0, 16'h1E48, 16'h1EE0, 16'h1F78, 16'h2010, 16'h20A8, 16'h2140, 16'h21D8, 16'h2270, 16'h2308, 16'h23A0, 16'h2438, 16'h24D0, 16'h2568};
  // localparam [15:0] LUT1 [0:31] = '{16'h0, 16'h98, 16'h130, 16'h1C8, 16'h260, 16'h2F8, 16'h390, 16'h428, 16'h4C0, 16'h558, 16'h5F0, 16'h688, 16'h720, 16'h7B8, 16'h850, 16'h8E8, 16'h980, 16'hA18, 16'hAB0, 16'hB48, 16'hBE0, 16'hC78, 16'hD10, 16'hDA8, 16'hE40, 16'hED8, 16'hF70, 16'h1008, 16'h10A0, 16'h1138, 16'h11D0, 16'h1268};
  state_t state_r, state_w;
  logic [254:0] a_r, a_w, b_r, b_w;
  logic [259:0] ms_w, ms_r, mc_w, mc_r;
  logic [259:0] s1, s2, s3, c1, c2, c3;
  logic [257:0] s7b, c7b, tmp;
  logic [260:0] S, C, S_w, C_w;
  logic [254:0] o_montgomery_r, o_montgomery_w;
  logic [15:0] LUT1_result_r, LUT1_result_w;
  logic [2:0] LUT2idx;
  logic o_finished_r, o_finished_w;
  logic [6:0] cycle_r, cycle_w;
  integer i;

  CSA csa0(.a({b_r, 2'b0}), .b({1'b0, b_r, 1'b0}), .cin({2'b0, b_r}), .s(s7b), .cout(c7b));

  assign o_finished = o_finished_r;
  assign o_montgomery = o_montgomery_r;

  always_comb begin
    state_w = state_r;
    o_finished_w = 0;
    o_montgomery_w = 0;
    cycle_w = 0;
    a_w = a_r;
    b_w = b_r;
    s1 = 0;
    s2 = 0;
    s3 = 0;
    c1 = 0;
    c2 = 0;
    c3 = 0;
    S_w = 0;
    C_w = 0;
    LUT1_result_w = 0;
    case(state_r)
      S_IDLE: begin
        if(i_start) begin
          state_w = S_PRECOMP;
          b_w = i_b;
          a_w = i_a;
        end
      end
      S_PRECOMP: begin
        cycle_w = cycles1_3;
        state_w = S_CALC;
      end
      S_CALC: begin
        cycle_w = cycle_r - 1;
        a_w = {a_r[251:0], 3'b0};
        s1 = {S[254:0], 3'b0};
        c1 = {C[254:0], 3'b0};
        s2 = (s1 ^ c1) ^ ms_r;
        c2 = {(s1 & c1) | (s1 & ms_r) | (c1 & ms_r), 1'b0};
        s3 = (s2 ^ c2) ^ mc_r;
        c3 = {(s2 & c2) | (s2 & mc_r) | (c2 & mc_r), 1'b0};
        S_w = (s3 ^ c3) ^ {{244'b0}, LUT1_result_r};
        C_w = {(s3 & c3) | (s3 & {{244'b0}, LUT1_result_r}) | (c3 & {{244'b0}, LUT1_result_r}), 1'b0};
        LUT1_result_w = LUT1[S_w[259:255]+C_w[259:255]];
        if(cycle_r == 1) begin
          state_w = S_POST1;
        end
      end
      S_POST1: begin
        state_w = S_POST2;  // start reduction from the S, C, LUT1_result below
        S_w = S[254:0];
        C_w = C[254:0];
        LUT1_result_w = LUT1[S[259:255]+C[259:255]];
      end
      S_POST2: begin
        state_w = S_POST3;
        S_w = (S ^ C) ^ {{242'b0}, LUT1_result_r[15:3]};
        C_w = {(S & C) | (S & {{242'b0}, LUT1_result_r[15:3]}) | (C & {{242'b0}, LUT1_result_r[15:3]}), {1'b0}};
        // S_w + C_w = S + C + LUT1_result[15:3] (no need to shift -> shift back 3 bits)
        LUT1_result_w = LUT1[S_w[255:255]+C_w[255:255]];  
      end
      S_POST3: begin
        tmp = S+C;
        if(tmp >= `N)
          o_montgomery_w = tmp - `N;
        else
          o_montgomery_w = tmp;
        state_w = S_IDLE;
        o_finished_w = 1;
      end
    endcase
  end

  // LUT2
  // result = i*Y = ms+mc(already shifted)
  always_comb begin
    ms_w = 0;
    mc_w = 0;
    LUT2idx = a_w[254: 252];
    case(LUT2idx)
      3'b000: begin
        ms_w = 0;
        mc_w = 0;
      end
      3'b001: begin
        ms_w = b_r;
        mc_w = 0;
      end
      3'b010: begin
        ms_w = b_r;
        mc_w = b_r;
      end
      3'b011: begin
        ms_w = {b_r, 1'b0};
        mc_w = b_r;
      end
      3'b100: begin
        ms_w = {b_r, 1'b0};
        mc_w = {b_r, 1'b0};
      end
      3'b101: begin
        ms_w = {b_r, 2'b0};
        mc_w = b_r;
      end
      3'b110: begin
        ms_w = {b_r, 2'b0};
        mc_w = {b_r, 1'b0};
      end
      3'b111: begin
        ms_w = s7b;
        mc_w = c7b;
      end
    endcase
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      state_r <= S_IDLE;
      cycle_r <= 0;
      o_finished_r <= 0;
      o_montgomery_r <= 0;
      a_r <= 0;
      b_r <= 0;
      ms_r <= 0;
      mc_r <= 0;
      LUT1_result_r <= 0;
      S <= 0;
      C <= 0;
    end else begin
      o_montgomery_r <= o_montgomery_w;
      state_r <= state_w;
      cycle_r <= cycle_w;
      ms_r <= ms_w;
      mc_r <= mc_w;
      LUT1_result_r <= LUT1_result_w;
      a_r <= a_w;
      b_r <= b_w;
      o_finished_r <= o_finished_w;
      S <= S_w;
      C <= C_w;
    end
  end

    
    
endmodule

module CSA (
  input [256:0] a, b, cin,
  output [257:0] s, cout
);
  assign s = a ^ b ^ cin;
  assign cout = {(a & b) | (a & cin) | (b & cin), 1'b0};
endmodule