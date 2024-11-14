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
        .i_x1(x1),
        .i_y1(y1),
        .i_z1(z1),
        .i_x2(x2),
        .i_y2(y2),
        .i_z2(z2),
        .o_x3(x3),
        .o_y3(y3),
        .o_z3(z3),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    task verify_output;
        input [255:0] x3, y3, z3;
        localparam x = 256'h5DC8E95ACC20971BA02DE2460B05D9909A9608021DFB798DBA7394AF98D6A57F;
        localparam y = 256'h554AA4BB1B239F79C9AFE0C8FE2AE223A98026ADCF5F3B8667BFA55B000B8881;
        localparam z = 256'h69C2DD41EF59BEC7AA8140EF60A6639AAE0C828E81FAEC12BE7068C9640A1AC;
        begin
            if (x3 == x && y3 == y && z3 == z) begin
                $display("Test passed: x3 = %h, y3 = %h, z3 = %h", x3, y3, z3);
            end else begin
                $display("Test failed: x3 = %h, y3 = %h, z3 = %h", x3, y3, z3);
            end
        end
    endtask

    initial begin
        $dumpfile("pointAdd.vcd");
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
        x2 = 7075909580202862594128302673554914659407030209928197693208324339654829354926;
        y2 = 21286769175881002626746167682496214460774588269525023793279114113306181287586;
        z2 = 1;
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