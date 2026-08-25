// =============================================================================
// q14_tb - Self-checking testbench for 3-Input Sort
// =============================================================================
// Problem:
//   Implement a purely combinational sorting network that takes three
//   WIDTH-bit unsigned values and outputs them sorted in ascending order.
//
// Interface:
//   parameter WIDTH           : bit width of a, b, c, lo, mid, hi (default 8)
//   input  logic [WIDTH-1:0] a, b, c   : three unsigned inputs, any order
//   output logic [WIDTH-1:0] lo        : the smallest of {a,b,c}
//   output logic [WIDTH-1:0] mid       : the middle value of {a,b,c}
//   output logic [WIDTH-1:0] hi        : the largest of {a,b,c}
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - All values are treated as unsigned.
//   - lo <= mid <= hi always holds.
//   - {lo, mid, hi} is always a permutation of {a, b, c} (same multiset of
//     values, just reordered) -- ties are fine: e.g. if a==b, both copies
//     still appear among {lo,mid,hi}.
//
// This testbench computes the golden lo/mid/hi behaviorally with a direct
// comparison tree (no dynamic-array .sort()), and checks the DUT against it
// for: 1000+ random (a,b,c) triples, all-equal, each of the 3 two-equal
// pairings, strictly ascending input, strictly descending input, and an
// already-sorted input.
// =============================================================================

module q14_tb;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] a, b, c;
    logic [WIDTH-1:0] lo, mid, hi;

    int errors;

    q14 #(.WIDTH(WIDTH)) dut (
        .a   (a),
        .b   (b),
        .c   (c),
        .lo  (lo),
        .mid (mid),
        .hi  (hi)
    );

    task automatic golden(
        input  logic [WIDTH-1:0] ga, gb, gc,
        output logic [WIDTH-1:0] glo, gmid, ghi
    );
        if (ga <= gb) begin
            if (gb <= gc) begin
                glo = ga; gmid = gb; ghi = gc;         // a<=b<=c
            end else if (ga <= gc) begin
                glo = ga; gmid = gc; ghi = gb;         // a<=c<b
            end else begin
                glo = gc; gmid = ga; ghi = gb;         // c<a<=b
            end
        end else begin
            if (ga <= gc) begin
                glo = gb; gmid = ga; ghi = gc;         // b<a<=c
            end else if (gb <= gc) begin
                glo = gb; gmid = gc; ghi = ga;         // b<=c<a
            end else begin
                glo = gc; gmid = gb; ghi = ga;         // c<b<a
            end
        end
    endtask

    task automatic check(input logic [WIDTH-1:0] ta, tb, tc, input string tag);
        logic [WIDTH-1:0] elo, emid, ehi;
        a = ta; b = tb; c = tc;
        golden(ta, tb, tc, elo, emid, ehi);
        #1;
        if (lo !== elo || mid !== emid || hi !== ehi) begin
            errors++;
            $display("MISMATCH (%s): a=%0d b=%0d c=%0d expected lo=%0d mid=%0d hi=%0d actual lo=%0d mid=%0d hi=%0d",
                      tag, a, b, c, elo, emid, ehi, lo, mid, hi);
        end
    endtask

    initial begin
        errors = 0;

        // Directed edge cases
        check(8'd50, 8'd50, 8'd50, "all-equal");
        check(8'd50, 8'd50, 8'd10, "a==b>c");
        check(8'd10, 8'd10, 8'd50, "a==b<c");
        check(8'd50, 8'd10, 8'd50, "a==c>b");
        check(8'd10, 8'd50, 8'd10, "a==c<b");
        check(8'd10, 8'd50, 8'd50, "b==c>a");
        check(8'd50, 8'd10, 8'd10, "b==c<a");
        check(8'd10, 8'd20, 8'd30, "ascending / already-sorted");
        check(8'd30, 8'd20, 8'd10, "descending");
        check(8'd0,  8'd0,  8'd0,  "all-zero");
        check(8'd255,8'd255,8'd255,"all-max");
        check(8'd0,  8'd255,8'd128,"spread");

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
