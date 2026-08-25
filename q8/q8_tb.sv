// =============================================================================
// q8_tb - Self-checking testbench for the divisible-by-MOD serial checker.
//   DO NOT EDIT. See q8.sv for the full problem statement.
// =============================================================================
// Problem (summary):
//   A binary number is streamed in MSB-first, one bit per bit_valid pulse:
//       running_value = running_value*2 + bit_in   (only on bit_valid)
//   divisible must indicate whether the value accumulated so far is evenly
//   divisible by MOD. rst/clear reset the running value to 0 (divisible=1).
//   divisible is registered: it reflects the remainder register, which
//   updates synchronously on the bit_valid/clear/rst edge.
//
// Verification approach:
//   Instantiate q8 twice: once with MOD=3 (default) and once with MOD=5.
//   For each instance, repeatedly: pulse clear to start a new number, then
//   stream a random-length sequence of random bits. The golden model tracks
//   ONLY the running remainder mod MOD (not the full value) behaviorally in
//   this testbench, exactly mirroring what the DUT itself must do, so there
//   is no risk of integer overflow even for long bit sequences. After every
//   bit consumed (and after every clear), check divisible against the
//   golden remainder.
// =============================================================================

module q8_tb;

    localparam int NUM_NUMBERS = 30;
    localparam int MAX_BITS    = 24;
    localparam time TIMEOUT_NS = 500_000;

    logic clk, rst;

    logic bit_in3, bit_valid3, clear3, divisible3;
    logic bit_in5, bit_valid5, clear5, divisible5;

    int errors;

    q8 #(.MOD(3)) dut3 (
        .clk       (clk),
        .rst       (rst),
        .bit_in    (bit_in3),
        .bit_valid (bit_valid3),
        .clear     (clear3),
        .divisible (divisible3)
    );

    q8 #(.MOD(5)) dut5 (
        .clk       (clk),
        .rst       (rst),
        .bit_in    (bit_in5),
        .bit_valid (bit_valid5),
        .clear     (clear5),
        .divisible (divisible5)
    );

    always #5 clk = ~clk;

    task automatic check(string label, logic actual, logic expected);
        if (actual !== expected) begin
            errors++;
            $display("[%0t] MISMATCH (%s): expected divisible=%0b, got %0b",
                      $time, label, expected, actual);
        end
    endtask

    task automatic run_test(string label, int modv,
                             ref logic bit_in, ref logic bit_valid,
                             ref logic clear, ref logic divisible);
        int golden_rem;
        int len;
        bit b;
        for (int num = 0; num < NUM_NUMBERS; num++) begin
            // start a new number
            clear = 1;
            @(posedge clk);
            clear = 0;
            golden_rem = 0;
            #1;
            check(label, divisible, (golden_rem % modv) == 0);

            len = $urandom_range(1, MAX_BITS);
            for (int i = 0; i < len; i++) begin
                b = $urandom_range(0, 1);
                bit_in    = b;
                bit_valid = 1;
                @(posedge clk);
                bit_valid = 0;
                golden_rem = (golden_rem * 2 + b) % modv;
                #1;
                check(label, divisible, (golden_rem % modv) == 0);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        errors = 0;
        bit_in3 = 0; bit_valid3 = 0; clear3 = 0;
        bit_in5 = 0; bit_valid5 = 0; clear5 = 0;

        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        // after reset, remainder should be 0 for both -> divisible
        check("reset/MOD3", divisible3, 1'b1);
        check("reset/MOD5", divisible5, 1'b1);

        run_test("MOD3", 3, bit_in3, bit_valid3, clear3, divisible3);
        run_test("MOD5", 5, bit_in5, bit_valid5, clear5, divisible5);

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

    // watchdog
    initial begin
        #(TIMEOUT_NS);
        $display("TEST FAILED: TIMEOUT");
        $finish;
    end

endmodule
