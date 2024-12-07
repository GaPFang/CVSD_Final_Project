`timescale 1ns/1ps

module tb_reduction();

    // Inputs to the reduction module
    reg [254:0] i_x, i_y, i_z;
    wire [254:0] o_x, o_y;
    reg clk;
    reg reset;
    reg start;

    // Output from the reduction module
    wire [254:0] result;
    wire ready;
    parameter MAX_CYCLES = 1000000;

    // Instantiate the reduction module (assuming it has these ports)
    Reduction uut (
        .i_clk(clk),
        .i_rst(reset),
        .i_start(start),
        .i_x(i_x),
        .i_y(i_y),
        .i_z(i_z),
        .o_x(o_x),
        .o_y(o_y),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    task verify_output;
        input [254:0] o_x, o_y;
        localparam x = 255'h47f6a5d15e1a09495f9216eba5253538db62c06ad333adbcc86932c069f00d26;
        localparam y = 255'h465032bc1d1cace745d1b3bad5ca1115805ab1512361151d1c84c68aa2f54468;
        begin
            if (o_x == x && o_y == y) begin
                $display("Test passed: o_x = %h, o_y = %h", o_x, o_y);
            end else begin
                $display("Test failed: o_x = %h, o_y = %h", o_x, o_y);
            end
        end
    endtask

    initial begin
        $dumpfile("reduction.vcd");
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
        i_x = 255'd57475566640496713142128147175679266297846140052097596853905232615831683015848;
        i_y = 255'd47748599448122480002225940985014935240714516551619989634383054318968500801555;
        i_z = 255'd47871744980311373740609968300770856527438808121359779097393596470768259151947;
        start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(ready);

        // End simulation
        verify_output(o_x, o_y);
        #100;
        $finish;
    end
    

endmodule