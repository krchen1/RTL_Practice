// =============================================================================
// q15_tb - Self-checking testbench for 3-Input Median
// =============================================================================
// Problem:
//   Implement a purely combinational module that outputs the median (middle)
//   value of three WIDTH-bit unsigned inputs.
//
// Interface:
//   parameter WIDTH           : bit width of a, b, c, med (default 8)
//   input  logic [WIDTH-1:0] a, b, c   : three unsigned inputs, any order
//   output logic [WIDTH-1:0] med       : the median (middle) value of {a,b,c}
//                                         -- neither the min nor the max
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - All values are treated as unsigned.
//   - med is always one of a, b, or c (by value; when there are duplicate
//     values, any one of them being reported is fine as long as the VALUE
//     of med is the mathematically correct median value).
//   - Ties: if exactly two of the three inputs are equal, that repeated
//     value is the median regardless of whether the third (distinct) value
//     is larger or smaller than the pair (e.g. a==b != c => med == a == b,
//     whether c is bigger or smaller). If all three are equal, med equals
//     that common value.
//
// This testbench computes the golden median behaviorally with a direct
// comparison tree, then checks the DUT for: 1000+ random (a,b,c) triples,
// all-equal, each of the 3 two-equal pairings (with the pair both above and
// below the odd one out), and all 6 permutations of 3 distinct values.
// =============================================================================

module q15_tb;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] a, b, c;
    logic [WIDTH-1:0] med;

    int errors;

    q15 #(.WIDTH(WIDTH)) dut (
        .a   (a),
        .b   (b),
        .c   (c),
        .med (med)
    );

    function automatic [WIDTH-1:0] golden_median(input [WIDTH-1:0] ga, gb, gc);
        if (ga <= gb) begin
            if (gb <= gc) golden_median = gb;
            else if (ga <= gc) golden_median = gc;
            else golden_median = ga;
        end else begin
            if (ga <= gc) golden_median = ga;
            else if (gb <= gc) golden_median = gc;
            else golden_median = gb;
        end
    endfunction

    task automatic check(input logic [WIDTH-1:0] ta, tb, tc, input string tag);
        logic [WIDTH-1:0] emed;
        a = ta; b = tb; c = tc;
        emed = golden_median(ta, tb, tc);
        #1;
        if (med !== emed) begin
            errors++;
            $display("MISMATCH (%s): a=%0d b=%0d c=%0d expected med=%0d actual med=%0d",
                      tag, a, b, c, emed, med);
        end
    endtask

    initial begin
        errors = 0;

        // Directed edge cases: ties
        check(8'd50, 8'd50, 8'd50, "all-equal");
        check(8'd50, 8'd50, 8'd10, "a==b, c smaller -> med=a==b");
        check(8'd10, 8'd10, 8'd50, "a==b, c larger  -> med=a==b");
        check(8'd50, 8'd10, 8'd50, "a==c, b smaller -> med=a==c");
        check(8'd10, 8'd50, 8'd10, "a==c, b larger  -> med=a==c");
        check(8'd10, 8'd50, 8'd50, "b==c, a smaller -> med=b==c");
        check(8'd50, 8'd10, 8'd10, "b==c, a larger  -> med=b==c");

        // All 6 permutations of 3 distinct values (10, 20, 30) -> median always 20
        check(8'd10, 8'd20, 8'd30, "perm abc");
        check(8'd10, 8'd30, 8'd20, "perm acb");
        check(8'd20, 8'd10, 8'd30, "perm bac");
        check(8'd20, 8'd30, 8'd10, "perm bca");
        check(8'd30, 8'd10, 8'd20, "perm cab");
        check(8'd30, 8'd20, 8'd10, "perm cba");

        // Extra directed edges
        check(8'd0,   8'd0,   8'd0,   "all-zero");
        check(8'd255, 8'd255, 8'd255, "all-max");
        check(8'd0,   8'd128, 8'd255, "spread");

        // Randomized testing
        for (int i = 0; i < 2000; i++) begin
            check($urandom_range(0, 255), $urandom_range(0, 255), $urandom_range(0, 255), "random");
        end

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
