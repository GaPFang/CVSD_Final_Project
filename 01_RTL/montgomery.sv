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
    logic [256:0] m_r;
    logic [256:0] m_w;
    logic [254:0] a, b;
    logic [254:0] o_montgomery_r;
    logic o_finished_r;
    logic [8:0] cycle_r, cycle_w;
    integer i;

    assign o_finished = o_finished_r;
    assign o_montgomery = o_montgomery_r;

    always_comb begin
        state_w = state_r;
        cycle_w = 0;
        for (i = 0; i < 1; i = i + 1) begin
            tmp[i] = 0;
        end
        m_w = 0;
        case(state_r)
            S_IDLE: begin
                if(i_start) begin
                    state_w = S_CALC;
                end
            end
            S_CALC: begin
                cycle_w = cycle_r + 1;
                if(cycle_r < 255) begin
                    state_w = S_CALC;
                    tmp[0] = a[cycle_r] ? m_r + b : m_r;
                    tmp[1] = tmp[0][0] ? tmp[0] + `N : tmp[0];
                    m_w = tmp[1] >> 1;
                end else begin
                    state_w = S_IDLE;
                    cycle_w = 0;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            m_r <= 0;
            state_r <= S_IDLE;
            cycle_r <= 0;
            o_finished_r <= 0;
            o_montgomery_r <= 0;
            a <= 0;
            b <= 0;
        end else begin
            o_finished_r <= 0;
            o_montgomery_r <= (m_r >= {2'b0, `N}) ? m_r - `N : m_r;
            state_r <= state_w;
            cycle_r <= cycle_w;
            if (state_r == S_IDLE && state_w == S_CALC) begin
                a <= i_a;
                b <= i_b;
                m_r <= 0;
            end else if (state_r == S_CALC && state_w == S_CALC) begin
                m_r <= m_w;
            end else if (state_r == S_CALC && state_w == S_IDLE) begin
                o_finished_r <= 1;
            end
        end
    end

    
    
endmodule