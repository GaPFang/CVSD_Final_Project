module Montgomery (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [254:0] i_a, i_b,
    output [254:0] o_montgomery,
    output         o_finished
);
    typedef enum logic {
        S_IDLE,
        S_CALC
    } state_t;

    state_t state_r, state_w;
    logic [256:0] tmp [0:1];
    logic [256:0] m_r, m_w;
    logic [254:0] a_r, a_w, b_r, b_w;
    logic o_finished_r, o_finished_w;
    logic [8:0] cycle_r, cycle_w;
    integer i;

    wire [256:0] m_minus_N = m_r - `N;
    wire [256:0] tmp0 = a_r[cycle_r] ? m_r + b_r : m_r;
    wire [256:0] tmp1 = tmp0[0] ? tmp0 + `N : tmp0;

    assign o_finished = o_finished_r;
    assign o_montgomery = m_minus_N[256] ? m_r : m_minus_N;

    always_comb begin
        state_w = state_r;
        cycle_w = 0;
        a_w = a_r;
        b_w = b_r;
        m_w = 0;
        o_finished_w = 0;
        case(state_r)
            S_IDLE: begin
                a_w = i_a;
                b_w = i_b;
                if(i_start) begin
                    state_w = S_CALC;
                end
            end
            S_CALC: begin
                cycle_w = cycle_r + 1;
                m_w = tmp1 >> 1;
                if(cycle_r == 254) begin
                    state_w = S_IDLE;
                    o_finished_w = 1;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state_r <= S_IDLE;
            cycle_r <= 0;
            a_r <= 0;
            b_r <= 0;
            m_r <= 0;
            o_finished_r <= 0;
        end else begin
            state_r <= state_w;
            cycle_r <= cycle_w;
            a_r <= a_w;
            b_r <= b_w;
            m_r <= m_w;
            o_finished_r <= o_finished_w;
        end
    end

    
    
endmodule