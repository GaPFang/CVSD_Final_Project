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
        localparam x = 255'd32550001060033536116573324601327423096500964215453530490263698861761376554278;
        localparam y = 255'd31803597324864083720364488970779197587133653988662377891460026891000616404072;
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
        i_x = 255'h2f8a66a8da71da5f8c006b1aa2fd5320e6dab0b39ff360b34fe0392898690125;
        i_y = 255'h45a22939c0fc3f79f416185ad1e5404ad7266f50b66617b28733045dbbf700a2;
        i_z = 255'h52310c49eea9ed11b646027438b6ae9e7e7885841a35ed71e541e372bdd37189;
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