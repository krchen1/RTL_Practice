// =============================================================================
// q18_tb - Self-checking testbench for q18 (ready/valid downsizer, 16->8)
// =============================================================================
//
// Problem recap (see q18.sv for the full spec the DUT must satisfy):
//   Every accepted 16-bit input word (in_valid && in_ready) must produce
//   exactly two 8-bit output beats, high byte first then low byte. in_ready
//   must stay low while a word is draining (one word in flight at a time).
//   out_valid/out_data must hold stable until out_ready completes the
//   transfer.
//
// Verification approach:
//   Golden model = an SV queue of expected output bytes (exp_bytes[$]).
//   Every cycle, we compute (from currently-driven in_valid/in_data and the
//   DUT's own in_ready/out_valid/out_data, all sampled BEFORE the upcoming
//   clock edge) whether an input transfer and/or an output transfer occurs
//   this cycle:
//     - on an input transfer, push hi_byte then lo_byte of the CURRENT
//       in_data onto exp_bytes (only "commit" a word when it's actually
//       accepted, i.e. in_valid && in_ready truly fires -- respects
//       backpressure).
//     - on an output transfer, pop the front of exp_bytes and compare it
//       against the out_data value sampled before the edge.
//   The driver holds in_valid/in_data stable once asserted, per standard
//   stream discipline, until accepted; it also injects random idle gaps
//   (in_valid deasserted) before presenting each new word. out_ready is
//   driven randomly every cycle by the checker/receiver side to exercise
//   stalling on the output. No second copy of the RTL under test is
//   instantiated.
// =============================================================================

module q18_tb;

    logic        clk;
    logic        rst;
    logic        in_valid;
    logic        in_ready;
    logic [15:0] in_data;
    logic        out_valid;
    logic        out_ready;
    logic [7:0]  out_data;

    int errors;
    logic [7:0] exp_bytes[$];

    q18 dut (
        .clk      (clk),
        .rst      (rst),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .in_data  (in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data (out_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        #200000;
        $display("TEST FAILED: TIMEOUT");
        $finish;
    end

    // Advance one cycle: drive a random out_ready, sample pre-edge signals,
    // compute whether an input and/or output transfer occurs this cycle,
    // update the golden model / check accordingly, then step the clock.
    // in_xfer_out reports (via output arg) whether an input transfer
    // occurred, so the caller's word-presentation loop knows when to stop.
    task automatic step(output bit in_xfer_out);
        bit do_in_xfer, do_out_xfer;
        logic [7:0] sampled_out_data;
        logic [7:0] exp;

        out_ready = ($urandom_range(0, 99) < 60);

        do_in_xfer       = in_valid && in_ready;
        do_out_xfer      = out_valid && out_ready;
        sampled_out_data = out_data;

        if (do_out_xfer) begin
            if (exp_bytes.size() == 0) begin
                errors++;
                $display("[%0t] MISMATCH: unexpected output beat (golden queue empty), out_data=%0h", $time, sampled_out_data);
            end else begin
                exp = exp_bytes.pop_front();
                if (exp !== sampled_out_data) begin
                    errors++;
                    $display("[%0t] MISMATCH: out_data expected=%0h actual=%0h", $time, exp, sampled_out_data);
                end
            end
        end

        if (do_in_xfer) begin
            exp_bytes.push_back(in_data[15:8]);
            exp_bytes.push_back(in_data[7:0]);
        end

        @(posedge clk);
        #1;

        in_xfer_out = do_in_xfer;
    endtask

    localparam int NUM_WORDS = 400;

    initial begin
        bit accepted;
        bit dummy;
        logic [15:0] cur_word;
        int idle_left;

        errors    = 0;
        rst       = 1;
        in_valid  = 0;
        in_data   = '0;
        out_ready = 0;
        @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;
        #1;

        if (in_ready !== 1'b1) begin
            errors++;
            $display("[%0t] MISMATCH: in_ready expected=1 (idle after reset) actual=%0b", $time, in_ready);
        end
        if (out_valid !== 1'b0) begin
            errors++;
            $display("[%0t] MISMATCH: out_valid expected=0 (idle after reset) actual=%0b", $time, out_valid);
        end

        for (int w = 0; w < NUM_WORDS; w++) begin
            cur_word  = 16'($urandom());
            idle_left = $urandom_range(0, 3);

            in_valid = 0;
            for (int k = 0; k < idle_left; k++) begin
                step(dummy);
            end

            in_valid = 1;
            in_data  = cur_word;
            accepted = 0;
            while (!accepted) begin
                step(accepted);
            end
        end

        in_valid = 0;

        // drain any remaining expected output beats
        begin
            int drain_cycles;
            drain_cycles = 0;
            while (exp_bytes.size() > 0 && drain_cycles < 2000) begin
                step(dummy);
                drain_cycles++;
            end
            if (exp_bytes.size() != 0) begin
                errors++;
                $display("[%0t] MISMATCH: %0d expected output byte(s) never drained", $time, exp_bytes.size());
            end
        end

        repeat (5) step(dummy);

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
