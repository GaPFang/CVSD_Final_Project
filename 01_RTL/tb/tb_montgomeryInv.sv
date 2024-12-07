`timescale 1ns/1ps

module tb_montgomeryInv();

    // Inputs to the montgomeryInv module
    reg [254:0] i_x;
    wire [254:0] o_x;
    reg clk;
    reg reset;
    reg start;

    // Output from the montgomeryInv module
    wire ready;
    parameter MAX_CYCLES = 1000000;

    // Instantiate the montgomeryInv module (assuming it has these ports)
    MontgomeryInv uut (
        .i_clk(clk),
        .i_rst(reset),
        .i_start(start),
        .i_x(i_x),
        .o_montgomeryInv(o_x),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    task verify_output;
        input [254:0] o_x;
        localparam x = 255'd17772197799916813694116762636308399019648115697425271362926582537713341395839;
        begin
            if (o_x == x) begin
                $display("Test passed: o_x = %h", o_x);
            end else begin
                $display("Test failed: o_x = %h, expected %h", o_x, x);
            end
        end
    endtask

    initial begin
        $dumpfile("montgomeryInv.vcd");
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
        i_x = 255'd41122485346044635394807010149486965121812469313531572554546452885248451587758;
        start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(ready);

        // End simulation
        verify_output(o_x);
        #100;
        $finish;
    end
    

endmodule