`timescale 1ns/1ps

module tb_pointAdd();

    // Inputs to the Montgomery module
    reg [255:0] x1, y1, z1, x2, y2, z2;
    wire [255:0] x3, y3, z3;
    reg clk;
    reg reset;
    reg start;

    // Output from the Montgomery module
    wire [255:0] result;
    wire ready;
    parameter MAX_CYCLES = 100000;

    // Instantiate the Montgomery module (assuming it has these ports)
    PointAdd uut (
        .i_clk(clk),
        .i_rst(reset),
        .i_start(start),
        .i_doubling(1),
        .i_x1(x1),
        .i_y1(y1),
        .i_z1(z1),
        .o_x3(x3),
        .o_y3(y3),
        .o_z3(z3),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    task verify_output;
        input [255:0] x3, y3, z3;
        localparam x = 256'h06b6f8d452485937ee2bdce38b932964d659d42349698c40a187786b532b415b;
        localparam y = 256'h578262c1f319aa7e3a73eb4970ae2f55b8da108830a23b9c7f627e3ba96bf69c;
        localparam z = 256'h032a6a5213a6f749cbb37819442d304e9ee2dd362be2965926c4d2e4918582f4;
        begin
            if (x3 == x && y3 == y && z3 == z) begin
                $display("Test passed: x3 = %h, y3 = %h, z3 = %h", x3, y3, z3);
            end else begin
                $display("Test failed: x3 = %h, y3 = %h, z3 = %h", x3, y3, z3);
            end
        end
    endtask

    initial begin
        $dumpfile("pointDoubling.vcd");
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
        x1 = 51169388680954780618255949183088705830597642531673777941256840852923233932582;
        y1 = 38023371316134590270444440476521181483750022538757642829225406787274294448402;
        z1 = 47908574844383975721735585330619112154511882220818545990695845831320904662833;
        start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(ready);

        // End simulation
        verify_output(x3, y3, z3);
        #100;
        $finish;
    end
    

endmodule