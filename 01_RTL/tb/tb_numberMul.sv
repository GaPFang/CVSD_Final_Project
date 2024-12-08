`timescale 1ns/1ps

module tb_Montgomery();

    // Inputs to the Montgomery module
    reg [255:0] N;
    reg [511:0] a;
    reg [255:0] a_prime, b_prime;
    reg [511:0] b;
    reg [10:0] error;
    reg clk;
    reg reset;
    reg start;

    // Output from the Montgomery module
    wire [255:0] result;
    reg [255:0] expected_result;
    wire ready;
    parameter PATTERN = 1000;
    parameter MAX_CYCLES = 1000*PATTERN;
    

    integer i;

    // Instantiate the Montgomery module (assuming it has these ports)
    numberMul uut (
        .i_a(a_prime),
        .i_b(b_prime),
        .i_clk(clk),
        .i_rst(reset),
        .i_start(start),
        .o_montgomery(result),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to check if the output is correct
    task verify_output;
        input [255:0] a, b, calculated;
        logic [511:0] tmp;
        localparam N = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
        logic [255:0] expected;
        begin
            tmp = a*b;
            expected = tmp % N;
            
            // for (int i = 1; i < 257; i = i + 1) begin
            //     tmp[i] = (tmp[i - 1] * ((N >> 1) + 1)) % N;
            // end
            // expected = tmp[256];
        end
        
        begin
            if (calculated == expected) begin
                // $display("Test passed: \na = %h, b = %h, result = %h", a, b, result);
                // $display("Test passed\n");
            end else begin
                $display("Test failed: \na = %h, b = %h, result = %h, expected = %h", a, b, result, expected);
                error = error + 1;
            end
        end
    endtask

    initial begin
        $fsdbDumpfile("numberMul.fsdb");
        $fsdbDumpvars(0, tb_Montgomery, "+mda");
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
        error = 0;

        // Test case 1
        // a = 256'h7120d900391ee9587819a1bb4521c1f99fe27d82cf1933d35d0df3e45cd51526;

        for (i=0; i<PATTERN; i=i+1) begin
            a = { $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom };
            b = { $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom };
            // b = 256'h5410772b8e893245d3fe41917772bb74539c33160ac14e5d45a07a153c7c5112;
            N = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
            // expected_result = 255'h7741bbcd3587a6ccd3244d59823d594127b329ff9ff328362e4382c71e498a13;
            a_prime = (a << 256) % N;
            b_prime = (b << 256) % N;  
            // b_prime = b;
            // a_prime = a;
            #5 start = 1;
            #10 start = 0;

            // Wait for the computation to complete
            wait(ready);

            // Verify result using expected value for (a * b) mod N
            verify_output(a_prime, b_prime, result);
        end

        // Add more test cases here...
        $display("Simulation complete with %d errors", error);
        // End simulation
        #100;
        $finish;
    end
    

endmodule