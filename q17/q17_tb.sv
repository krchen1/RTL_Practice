// =============================================================================
// q17_tb - Self-checking testbench for the programmable clock divider.
//   DO NOT EDIT. See q17.sv for the full problem statement.
// =============================================================================
// Problem (summary):
//   clk_out must have rising edges exactly every div_sel input-clk cycles
//   in steady state (div_sel in {2,3,4,5}, the literal numeric ratio).
//   Duty cycle is unconstrained for odd ratios - only period is checked.
//   One irregular transitional period is allowed right after reset or
//   right after div_sel changes.
//
// Verification approach:
//   For each div_sel in {2,3,4,5}: apply it, let a couple of periods pass
//   (settle time) to flush any transitional behavior, then capture several
//   consecutive rising-edge timestamps of clk_out and check that every
//   edge-to-edge gap equals exactly div_sel input-clk cycles (10ns each).
// =============================================================================

module q17_tb;

    localparam time TIMEOUT_NS = 200_000;
    localparam int  NUM_PERIODS = 6;

    logic clk, rst;
    logic [2:0] div_sel;
    logic clk_out;

    int errors;

    q17 dut (
        .clk     (clk),
        .rst     (rst),
        .div_sel (div_sel),
        .clk_out (clk_out)
    );

    always #5 clk = ~clk;

    task automatic measure_periods(int expected_period, int n_periods);
        realtime edge_times[$];
        int meas;
        edge_times.delete();
        for (int i = 0; i <= n_periods; i++) begin
            @(posedge clk_out);
            edge_times.push_back($time);
        end
        for (int i = 0; i < n_periods; i++) begin
            meas = int'((edge_times[i+1] - edge_times[i]) / 10.0);
            if (meas != expected_period) begin
                errors++;
                $display("[%0t] MISMATCH (div_sel=%0d): expected period=%0d clk cycles, got %0d",
                          $time, expected_period, expected_period, meas);
            end
        end
    endtask

    initial begin
        clk     = 0;
        rst     = 1;
        div_sel = 3'd2;
        errors  = 0;

        repeat (3) @(posedge clk);
        rst = 0;

        // sweep div_sel = 2, 3, 4, 5
        for (int i = 0; i < 4; i++) begin
            int ratio;
            case (i)
                0: ratio = 2;
                1: ratio = 3;
                2: ratio = 4;
                default: ratio = 5;
            endcase
            div_sel = ratio[2:0];
            // let a couple of full periods pass to flush any transitional
            // behavior (after reset or after the div_sel change)
            repeat (2 * ratio) @(posedge clk);
            measure_periods(ratio, NUM_PERIODS);
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
