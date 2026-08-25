// =============================================================================
// q16_tb - Self-checking testbench for the iterative Fibonacci/factorial unit.
//   DO NOT EDIT. See q16.sv for the full problem statement.
// =============================================================================
// Problem (summary):
//   q16 computes fib(n) (mode==0) or n! (mode==1) iteratively over multiple
//   cycles, started by a start pulse (only valid while not busy), signaling
//   completion via a level-held done with result stable until the next
//   start. mode==1 (factorial) is only exercised for n in [0,12] (32-bit
//   safe); mode==0 (fib) is exercised across the full n in [0,31] range
//   (32-bit safe for all of it).
//
// Verification approach:
//   Golden fib(n)/n! values are computed behaviorally with plain SystemVerilog
//   for-loops (functions below), mirroring the natural iterative definitions
//   - NOT by instantiating a second copy of the RTL. The test alternates
//   between fib and factorial calls across a curated list of n values
//   (including edge cases 0, 1, and the max safe n for each mode), pulsing
//   start only when the DUT isn't busy, waiting for done, checking result,
//   and then checking done/result remain stable for a few extra idle
//   cycles before the next start.
// =============================================================================

module q16_tb;

    localparam time TIMEOUT_NS = 500_000;

    logic clk, rst;
    logic start;
    logic [4:0] n;
    logic mode;
    logic done;
    logic [31:0] result;

    int errors;

    q16 dut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .n      (n),
        .mode   (mode),
        .done   (done),
        .result (result)
    );

    always #5 clk = ~clk;

    // ---- golden models (behavioral, independent of the RTL) ----------------
    function automatic logic [31:0] gold_fib(input int nn);
        logic [31:0] a, b, t;
        a = 32'd0;
        b = 32'd1;
        for (int i = 0; i < nn; i++) begin
            t = a + b;
            a = b;
            b = t;
        end
        return a;
    endfunction

    function automatic logic [31:0] gold_fact(input int nn);
        logic [31:0] acc;
        acc = 32'd1;
        for (int i = 0; i < nn; i++) begin
            acc = acc * (i + 1);
        end
        return acc;
    endfunction

    // curated n lists: edge cases + a spread of values, each within its
    // mode's documented 32-bit-safe range.
    int fib_ns [0:13] = '{0, 1, 2, 3, 4, 5, 7, 10, 13, 17, 20, 23, 27, 31};
    int fact_ns[0:12] = '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

    task automatic check_val(string label, logic [31:0] actual, logic [31:0] expected);
        if (actual !== expected) begin
            errors++;
            $display("[%0t] MISMATCH (%s): expected=%0d, got=%0d", $time, label, expected, actual);
        end
    endtask

    task automatic check_bit(string label, logic actual, logic expected);
        if (actual !== expected) begin
            errors++;
            $display("[%0t] MISMATCH (%s): expected=%0b, got=%0b", $time, label, expected, actual);
        end
    endtask

    // run one computation: assumes DUT is currently not-busy (done==1, or
    // fresh out of reset). Pulses start, waits for done, checks result, then
    // checks done/result hold stable for a few idle cycles.
    task automatic do_one(string label, logic [4:0] nn, logic md, logic [31:0] expected);
        @(negedge clk);
        n     = nn;
        mode  = md;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        // done must be low starting at the clock edge that sampled the
        // start pulse (a new computation must actually take effect)
        #1;
        check_bit({label, "/done-drops"}, done, 1'b0);

        // wait for completion
        while (!done) @(posedge clk);
        #1;
        check_val(label, result, expected);

        // done/result must hold stable for a few idle cycles
        for (int k = 0; k < 3; k++) begin
            @(posedge clk);
            #1;
            check_bit({label, "/done-holds"}, done, 1'b1);
            check_val({label, "/result-holds"}, result, expected);
        end
    endtask

    initial begin
        clk    = 0;
        rst    = 1;
        start  = 0;
        n      = 5'd0;
        mode   = 1'b0;
        errors = 0;

        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        // reset behavior
        check_bit("reset/done", done, 1'b0);
        check_val("reset/result", result, 32'd0);

        // alternate fib / factorial across the curated lists
        for (int i = 0; i < 26; i++) begin
            if (i % 2 == 0) begin
                automatic int idx = (i / 2) % 14;
                automatic int nn  = fib_ns[idx];
                do_one($sformatf("fib(%0d)", nn), nn[4:0], 1'b0, gold_fib(nn));
            end else begin
                automatic int idx = (i / 2) % 13;
                automatic int nn  = fact_ns[idx];
                do_one($sformatf("fact(%0d)", nn), nn[4:0], 1'b1, gold_fact(nn));
            end
        end

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
