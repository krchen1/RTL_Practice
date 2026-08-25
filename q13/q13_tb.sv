// ===========================================================================
// q13_tb.sv -- Self-checking testbench for q13 (DO NOT EDIT)
//
// Title: LRU replacement tracker, 4-way
//
// NOTE: This is one concrete scoping of an open-ended interview question
// ("design an LRU replacement policy"); the exact interface below is what
// is being tested.
//
// Scoping: this module tracks WHICH of 4 "ways" is least-recently-used --
// it is the replacement-policy logic only, not a full cache datapath. It
// models just the LRU state-tracking logic for a 4-way set, as used inside
// a larger cache design -- not the full cache datapath/tag/data arrays.
//
// Interface:
//   input  logic       clk, rst      -- clk 10ns period, rst sync active-high
//   input  logic       access_vld    -- pulses when way access_way was
//                                        touched (hit or fill) this cycle
//   input  logic [1:0] access_way    -- which of the 4 ways (0-3) was touched
//   output logic [1:0] lru_way       -- COMBINATIONAL: currently least-
//                                        recently-used way (next eviction victim)
//
// Semantics:
//   - Whenever access_vld pulses, way access_way becomes the
//     MOST-recently-used way.
//   - lru_way is combinational and always valid: it reflects whichever of
//     the 4 ways is currently least-recently-used.
//   - On rst: the initial recency order LRU -> MRU is way 0, way 1, way 2,
//     way 3. So lru_way == 0 immediately after reset, before any access.
//
// Golden model: this testbench maintains a 4-element recency queue
// (LRU-first) mirroring the DUT's rule: on each access, move the accessed
// way to the MRU (tail) end of the queue. lru_way must always equal the
// head (LRU-end) of that queue.
// ===========================================================================

module q13_tb;

  logic       clk, rst;
  logic       access_vld;
  logic [1:0] access_way;
  logic [1:0] lru_way;

  int errors;

  q13 dut (
    .clk        (clk),
    .rst        (rst),
    .access_vld (access_vld),
    .access_way (access_way),
    .lru_way    (lru_way)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Watchdog
  initial begin
    #200000;
    $display("TEST FAILED: TIMEOUT");
    $finish;
  end

  // Golden model: recency queue, LRU-first (index 0 = LRU, index 3 = MRU)
  logic [1:0] recency_q[4];

  function automatic void golden_reset();
    begin
      recency_q[0] = 2'd0;
      recency_q[1] = 2'd1;
      recency_q[2] = 2'd2;
      recency_q[3] = 2'd3;
    end
  endfunction

  function automatic void golden_access(input [1:0] way);
    int idx;
    int found;
    begin
      found = -1;
      for (idx = 0; idx < 4; idx++) begin
        if (recency_q[idx] === way) found = idx;
      end
      // Shift everything after 'found' down by one, place 'way' at the tail (MRU)
      for (idx = found; idx < 3; idx++) begin
        recency_q[idx] = recency_q[idx+1];
      end
      recency_q[3] = way;
    end
  endfunction

  function automatic [1:0] golden_lru();
    golden_lru = recency_q[0];
  endfunction

  task automatic check_lru(string tag);
    logic [1:0] exp_lru;
    begin
      exp_lru = golden_lru();
      if (lru_way !== exp_lru) begin
        errors++;
        $display("[%0t] MISMATCH (%s): expected lru_way=%0d actual lru_way=%0d (golden queue=%p)",
                  $time, tag, exp_lru, lru_way, recency_q);
      end
    end
  endtask

  task automatic do_access(input [1:0] way);
    begin
      @(negedge clk);
      access_vld = 1'b1;
      access_way = way;
      golden_access(way);
      @(negedge clk);
      access_vld = 1'b0;
      check_lru("after access");
    end
  endtask

  initial begin
    errors     = 0;
    access_vld = 0;
    access_way = 0;
    rst        = 1;

    @(negedge clk);
    @(negedge clk);
    rst = 0;
    golden_reset();
    @(negedge clk);

    // Check immediately after reset, before any access
    check_lru("post-reset");

    // Directed sequence: visit all 4 ways in various orders
    do_access(2'd0);
    do_access(2'd1);
    do_access(2'd2);
    do_access(2'd3);
    // Now LRU order should be 0,1,2,3 again (since access order matches)
    check_lru("after full sweep 0,1,2,3");

    // Repeated access to same way
    do_access(2'd1);
    do_access(2'd1);
    check_lru("after repeated access to way1");

    do_access(2'd3);
    do_access(2'd2);
    do_access(2'd0);
    check_lru("after 3,2,0");

    // Access LRU way itself repeatedly
    do_access(2'd1);
    do_access(2'd1);
    do_access(2'd1);

    // A cycle with no access: lru_way must remain stable/valid
    @(negedge clk);
    check_lru("idle cycle, no access");
    @(negedge clk);
    check_lru("idle cycle, no access 2");

    // Randomized sequence, including repeats and various orders
    for (int i = 0; i < 500; i++) begin
      do_access($urandom_range(0,3));
    end

    // Also verify a couple of idle (no-access) cycles interleaved with randoms
    for (int i = 0; i < 20; i++) begin
      if ($urandom_range(0,1)) begin
        do_access($urandom_range(0,3));
      end else begin
        @(negedge clk);
        check_lru("random idle cycle");
      end
    end

    if (errors == 0) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED: %0d error(s)", errors);
    end
    $finish;
  end

endmodule
