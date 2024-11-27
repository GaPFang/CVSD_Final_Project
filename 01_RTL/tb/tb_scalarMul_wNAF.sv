`timescale 1ns/1ps

module tb_scalarMul();

    // Inputs to the ScalarMul module
    reg [254:0] xp, yp, M;
    wire [254:0] o_x, o_y, o_z;
    reg clk;
    reg reset;
    reg start;

    // Output from the ScalarMul module
    wire [254:0] result;
    wire ready;
    parameter MAX_CYCLES = 1000000;

    // Instantiate the ScalarMul module (assuming it has these ports)
    ScalarMul uut (
        .i_clk(clk),
        .i_rst(reset),
        .i_start(start),
        .i_M(M),
        .i_x(xp),
        .i_y(yp),
        .o_x(o_x),
        .o_y(o_y),
        .o_z(o_z),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    task verify_output;
        input [254:0] o_x, o_y, o_z;
        localparam x = 255'h16577cc519967d24524c6b69b58c2dea2915f21983862ea2088985c0c9dbc1c7;
        localparam y = 255'h6d9028936e888c2df582decfa254b82fc15b2020d4b2be4ff7ff4030373fb800;
        localparam z = 255'h78dad67d9cd896d79961a2d261e8b3d7a721543f6add2ba832d49f9f66287f3e;
        begin
            if (o_x == x && o_y == y && o_z == z) begin
                $display("Test passed: o_x = %h, o_y = %h, o_z = %h", o_x, o_y, o_z);
            end else begin
                $display("Test failed: o_x = %h, o_y = %h, o_z = %h", o_x, o_y, o_z);
            end
        end
    endtask

    initial begin
        $dumpfile("scalarMul_wNAF.vcd");
        $dumpvars();
    end

    initial begin
        #(MAX_CYCLES * 10);
        $display("Test failed: Timeout");
        $finish;
    end

    // Initialize the simulation
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        start = 0;

        // Apply reset
        #10 reset = 1;
        #10 reset = 0;

        // Test case 1
        xp = 255'h0fa4d2a95dafe3275eaf3ba907dbb1da819aba3927450d7399a270ce660d2fae;
        yp = 255'h2f0fe2678dedf6671e055f1a557233b324f44fb8be4afe607e5541eb11b0bea2;
        M = 255'h259f4329e6f4590b9a164106cf6a659eb4862b21fb97d43588561712e8e5216a;
        start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(ready);

        // End simulation
        verify_output(o_x, o_y, o_z);
        #100;
        $finish;
    end
    

endmodule