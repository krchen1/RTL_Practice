// =============================================================================
// q23_tb - Self-checking testbench for the divide-by-10, 40%-duty clock.
//   DO NOT EDIT. See q23.sv for the full problem statement.
// =============================================================================
// Problem (summary):
//   clk_out is high for 4 of every 10 input clk cycles (counter in
//   {0,1,2,3}) and low for the other 6 (counter in {4..9}), free-running,
//   repeating from reset. The internal cycle counter reads 0 starting
//   immediately after the last reset-asserting clock edge (i.e. during the
//   interval right after rst is deasserted, before the next posedge), and
//   increments by 1 (mod 10) at every subsequent posedge.
//
// Verification approach:
//   After reset deasserts, sample clk_out at the corresponding point in
//   every input-clk cycle for several full periods and compare against the
//   exact expected 10-cycle pattern (high,high,high,high,low,low,low,low,
//   low,low) repeating, generated behaviorally in this testbench with the
//   same counter recurrence (0..9 wrap, high for 0-3, low for 4-9).
// =============================================================================

module q23_tb;

    localparam time TIMEOUT_NS = 200_000;
    localparam int  NUM_EXTRA_SAMPLES = 39; // + the initial sample = 40 total (4 periods)

    logic clk, rst;
    logic clk_out;

    int errors;
    int idx;

    logic pattern [0:9] = '{1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

    q23 dut (
        .clk     (clk),
        .rst     (rst),
        .clk_out (clk_out)
    );

    always #5 clk = ~clk;

    task automatic check(int cnt_idx);
        if (clk_out !== pattern[cnt_idx]) begin
            errors++;
            $display("[%0t] MISMATCH: counter_idx=%0d expected clk_out=%0b got=%0b",
                      $time, cnt_idx, pattern[cnt_idx], clk_out);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        errors = 0;

        repeat (3) @(posedge clk);
        rst = 0;
        #1;

        // right after the last reset-asserting edge, counter == 0
        idx = 0;
        check(idx);

        for (int i = 0; i < NUM_EXTRA_SAMPLES; i++) begin
            @(posedge clk);
            #1;
            idx = (idx + 1) % 10;
            check(idx);
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
