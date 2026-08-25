// ===========================================================================
// q6_tb.sv -- Self-checking testbench for q6 (DO NOT EDIT)
//
// Title: Reorder buffer (ROB) micro-architecture and RTL
//
// NOTE: This is one concrete scoping of an open-ended interview question
// ("micro-architect a ROB"); the exact interface below is what is being
// tested.
//
// Interface:
//   parameter DEPTH = 8         -- number of ROB entries (circular buffer)
//   localparam IDW = $clog2(DEPTH)
//   input  logic clk, rst
//   -- ALLOCATE (dispatch) port
//   input  logic         alloc_en
//   output logic         alloc_rdy
//   output logic [IDW-1:0] alloc_id
//   -- COMPLETE (out-of-order execution finishing) port
//   input  logic         comp_en
//   input  logic [IDW-1:0] comp_id
//   input  logic [31:0]  comp_data
//   -- COMMIT (in-order retire) port
//   output logic         commit_vld
//   output logic [IDW-1:0] commit_id
//   output logic [31:0]  commit_data
//   input  logic         commit_rdy
//
// Semantics:
//   Internally, DEPTH entries each hold {valid, done, data} in a circular
//   buffer with a head pointer (next to commit) and tail pointer (next to
//   allocate).
//   - alloc_rdy is high when the buffer isn't full. On a cycle where
//     alloc_en && alloc_rdy, a new entry is allocated at the tail (marked
//     valid, not done), its index returned via alloc_id COMBINATIONALLY
//     (so the requester learns its id the same cycle it allocates), and
//     tail advances.
//   - comp_en with comp_id marks that specific entry (identified by its ROB
//     id, which may be ANY currently-allocated, not-yet-done entry --
//     completions can arrive in ANY order relative to allocation order) as
//     done and latches comp_data into it. This can happen for any allocated
//     entry regardless of position (out-of-order completion is the whole
//     point of a ROB).
//   - commit_vld is high whenever the entry at the head is valid AND done;
//     commit_id/commit_data reflect that head entry COMBINATIONALLY. On a
//     cycle where commit_vld && commit_rdy, that head entry is retired
//     (freed) and head advances to the next entry.
//   - If the head entry is valid but not yet done, commit_vld stays low
//     (in-order commit stalls waiting for the oldest instruction to
//     complete, even if younger ones are already done) -- this
//     in-order-commit-despite-out-of-order-completion behavior is the core
//     thing being tested.
//   - On rst: buffer empties, head=tail=0, alloc_rdy high, commit_vld low.
//
// Golden model: a behavioral SV model (an array of DEPTH records
// {valid,done,data}, plus head/tail pointers) implementing the exact same
// allocate/complete/commit rules, driven with the same stimulus as the DUT
// in lockstep. Checks:
//   (a) commit_id sequence always matches allocation order exactly (never
//       skips/reorders even though completions arrive out-of-order),
//   (b) commit_data for each id matches what was written via comp_data for
//       that id,
//   (c) alloc_rdy correctly goes low when full and returns after commits
//       free space.
// ===========================================================================

module q6_tb;

  localparam int DEPTH = 8;
  localparam int IDW   = $clog2(DEPTH);

  logic             clk, rst;
  logic             alloc_en, alloc_rdy;
  logic [IDW-1:0]   alloc_id;
  logic             comp_en;
  logic [IDW-1:0]   comp_id;
  logic [31:0]      comp_data;
  logic             commit_vld;
  logic [IDW-1:0]   commit_id;
  logic [31:0]      commit_data;
  logic             commit_rdy;

  int errors;

  q6 #(.DEPTH(DEPTH)) dut (
    .clk         (clk),
    .rst         (rst),
    .alloc_en    (alloc_en),
    .alloc_rdy   (alloc_rdy),
    .alloc_id    (alloc_id),
    .comp_en     (comp_en),
    .comp_id     (comp_id),
    .comp_data   (comp_data),
    .commit_vld  (commit_vld),
    .commit_id   (commit_id),
    .commit_data (commit_data),
    .commit_rdy  (commit_rdy)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Watchdog
  initial begin
    #2_000_000;
    $display("TEST FAILED: TIMEOUT");
    $finish;
  end

  // ----------------------------------------------------------------------
  // Golden model
  // ----------------------------------------------------------------------
  typedef struct {
    logic valid;
    logic done;
    logic [31:0] data;
  } rob_entry_t;

  rob_entry_t gold_buf [DEPTH];
  int gold_head, gold_tail;
  int gold_count; // number of valid entries currently allocated

  // Expected outputs, computed combinationally from golden state (mirrors
  // what the DUT should be driving THIS cycle, before any edge).
  logic               exp_alloc_rdy;
  logic [IDW-1:0]     exp_alloc_id;
  logic               exp_commit_vld;
  logic [IDW-1:0]     exp_commit_id;
  logic [31:0]        exp_commit_data;

  function automatic void gold_reset();
    int i;
    begin
      for (i = 0; i < DEPTH; i++) begin
        gold_buf[i].valid = 1'b0;
        gold_buf[i].done  = 1'b0;
        gold_buf[i].data  = 32'd0;
      end
      gold_head  = 0;
      gold_tail  = 0;
      gold_count = 0;
    end
  endfunction

  function automatic void gold_recompute_outputs();
    begin
      exp_alloc_rdy = (gold_count < DEPTH);
      exp_alloc_id  = gold_tail[IDW-1:0];
      if (gold_buf[gold_head].valid && gold_buf[gold_head].done) begin
        exp_commit_vld  = 1'b1;
        exp_commit_id   = gold_head[IDW-1:0];
        exp_commit_data = gold_buf[gold_head].data;
      end else begin
        exp_commit_vld  = 1'b0;
        exp_commit_id   = 'x;
        exp_commit_data = 'x;
      end
    end
  endfunction

  // Reference model queue tracking the golden allocation order, used to
  // independently verify commit_id sequence == allocation order.
  int alloc_order_q[$];

  // Track expected data per id (id space reused, so this is only valid
  // while that id is currently allocated -- but since commit always
  // matches head and we check data at commit time using the golden buf
  // itself, we don't strictly need this; kept for clarity/documentation.)

  // ----------------------------------------------------------------------
  // Checking task: call once per cycle, right after applying this cycle's
  // stimulus and before advancing the clock, to check combinational
  // outputs against golden expectations for THIS cycle.
  // ----------------------------------------------------------------------
  task automatic check_outputs(string tag);
    begin
      gold_recompute_outputs();
      if (alloc_rdy !== exp_alloc_rdy) begin
        errors++;
        $display("[%0t] MISMATCH alloc_rdy (%s): expected=%0b actual=%0b",
                  $time, tag, exp_alloc_rdy, alloc_rdy);
      end
      if (alloc_en && exp_alloc_rdy && (alloc_id !== exp_alloc_id)) begin
        errors++;
        $display("[%0t] MISMATCH alloc_id (%s): expected=%0d actual=%0d",
                  $time, tag, exp_alloc_id, alloc_id);
      end
      if (commit_vld !== exp_commit_vld) begin
        errors++;
        $display("[%0t] MISMATCH commit_vld (%s): expected=%0b actual=%0b",
                  $time, tag, exp_commit_vld, commit_vld);
      end
      if (exp_commit_vld) begin
        if (commit_id !== exp_commit_id) begin
          errors++;
          $display("[%0t] MISMATCH commit_id (%s): expected=%0d actual=%0d",
                    $time, tag, exp_commit_id, commit_id);
        end
        if (commit_data !== exp_commit_data) begin
          errors++;
          $display("[%0t] MISMATCH commit_data (%s): expected=%0h actual=%0h",
                    $time, tag, exp_commit_data, commit_data);
        end
        // Cross-check against strict allocation-order queue
        if (alloc_order_q.size() > 0) begin
          int expected_next_id;
          expected_next_id = alloc_order_q[0];
          if (commit_id !== expected_next_id[IDW-1:0]) begin
            errors++;
            $display("[%0t] MISMATCH commit ORDER (%s): expected oldest-allocated id=%0d, DUT commit_id=%0d",
                      $time, tag, expected_next_id, commit_id);
          end
        end
      end
    end
  endtask

  // Apply this cycle's golden-model state updates for an edge that is
  // about to happen (call BEFORE the @(posedge) completes, using this
  // cycle's stimulus values), then this function commits the golden state
  // transition that mirrors what happens at the clock edge.
  task automatic gold_edge_update();
    begin
      // Allocate
      if (alloc_en && exp_alloc_rdy) begin
        gold_buf[gold_tail].valid = 1'b1;
        gold_buf[gold_tail].done  = 1'b0;
        gold_buf[gold_tail].data  = 32'd0;
        alloc_order_q.push_back(gold_tail);
        gold_tail = (gold_tail + 1) % DEPTH;
        gold_count = gold_count + 1;
      end
      // Complete (may target any valid, not-done entry -- including the
      // one just allocated this very cycle is NOT expected in our
      // stimulus generator, since a real completion always targets an
      // already-allocated id from a prior cycle; but even if same-cycle,
      // rule applies to whichever entries are valid post-allocation).
      if (comp_en) begin
        if (gold_buf[comp_id].valid) begin
          gold_buf[comp_id].done = 1'b1;
          gold_buf[comp_id].data = comp_data;
        end
      end
      // Commit
      if (exp_commit_vld && commit_rdy) begin
        gold_buf[gold_head].valid = 1'b0;
        gold_buf[gold_head].done  = 1'b0;
        gold_head  = (gold_head + 1) % DEPTH;
        gold_count = gold_count - 1;
        if (alloc_order_q.size() > 0) void'(alloc_order_q.pop_front());
      end
    end
  endtask

  // ----------------------------------------------------------------------
  // Stimulus
  // ----------------------------------------------------------------------

  // List of currently-allocated-but-not-yet-completed ids (from the TB's
  // perspective), used to pick out-of-order completion targets.
  int pending_ids[$];

  task automatic do_cycle();
    begin
      check_outputs("pre-edge");
      gold_edge_update();
      @(posedge clk);
      #1; // allow combinational settle after the edge
    end
  endtask

  initial begin
    errors      = 0;
    alloc_en    = 0;
    comp_en     = 0;
    comp_id     = 0;
    comp_data   = 0;
    commit_rdy  = 1;
    rst         = 1;

    repeat (3) @(posedge clk);
    #1;
    rst = 0;
    gold_reset();
    alloc_order_q.delete();
    pending_ids.delete();
    @(negedge clk);
    #1;

    // Post-reset checks
    check_outputs("post-reset");
    if (commit_vld !== 1'b0) begin
      errors++;
      $display("[%0t] MISMATCH: commit_vld not low after reset", $time);
    end
    if (alloc_rdy !== 1'b1) begin
      errors++;
      $display("[%0t] MISMATCH: alloc_rdy not high after reset", $time);
    end

    // -------------------------------------------------------------
    // Phase 1: fill the buffer completely, confirm alloc_rdy blocks,
    // then commit some out and confirm alloc_rdy returns.
    // -------------------------------------------------------------
    commit_rdy = 0; // hold off commits so we can fill deterministically
    for (int i = 0; i < DEPTH; i++) begin
      alloc_en = 1;
      check_outputs("filling");
      gold_edge_update();
      if (alloc_en && exp_alloc_rdy) pending_ids.push_back(exp_alloc_id);
      @(negedge clk);
      #1;
    end
    alloc_en = 0;
    @(negedge clk);
    #1;
    check_outputs("full - alloc_en deasserted");
    if (alloc_rdy !== 1'b0) begin
      errors++;
      $display("[%0t] MISMATCH: alloc_rdy should be low when buffer full", $time);
    end
    // Try to allocate while full -- must be blocked (alloc_rdy low)
    alloc_en = 1;
    @(negedge clk);
    #1;
    check_outputs("alloc attempted while full");
    if (alloc_rdy !== 1'b0) begin
      errors++;
      $display("[%0t] MISMATCH: alloc_rdy still not low while full (2nd check)", $time);
    end
    alloc_en = 0;

    // Complete all entries out of order (shuffle pending_ids), then allow
    // commits and confirm alloc_rdy returns as space frees up.
    begin
      int shuffled[$];
      shuffled = pending_ids;
      // Fisher-Yates shuffle
      for (int i = shuffled.size()-1; i > 0; i--) begin
        int j;
        int tmp;
        j = $urandom_range(0, i);
        tmp = shuffled[i]; shuffled[i] = shuffled[j]; shuffled[j] = tmp;
      end
      foreach (shuffled[k]) begin
        comp_en   = 1;
        comp_id   = shuffled[k][IDW-1:0];
        comp_data = 32'hA000_0000 + shuffled[k];
        do_cycle();
        comp_en = 0;
      end
      pending_ids.delete();
    end
    comp_en = 0;

    commit_rdy = 1;
    // Drain the buffer, checking commit order matches allocation order
    for (int i = 0; i < DEPTH; i++) begin
      do_cycle();
    end
    do_cycle(); // one extra to observe commit_vld drop to 0
    if (commit_vld !== 1'b0) begin
      errors++;
      $display("[%0t] MISMATCH: commit_vld should be low, buffer drained", $time);
    end
    if (alloc_rdy !== 1'b1) begin
      errors++;
      $display("[%0t] MISMATCH: alloc_rdy should be high again after drain", $time);
    end

    // -------------------------------------------------------------
    // Phase 2: randomized mixed traffic -- allocate, complete
    // out-of-order, commit with backpressure toggling.
    // -------------------------------------------------------------
    pending_ids.delete();
    for (int cyc = 0; cyc < 3000; cyc++) begin
      // Randomly decide to allocate
      alloc_en = ($urandom_range(0,99) < 55);
      // Randomly decide to complete a pending (not-yet-done) entry
      comp_en = 1'b0;
      comp_id = 'x;
      comp_data = 'x;
      if (pending_ids.size() > 0 && $urandom_range(0,99) < 60) begin
        int pick_idx;
        pick_idx = $urandom_range(0, pending_ids.size()-1);
        comp_en   = 1'b1;
        comp_id   = pending_ids[pick_idx][IDW-1:0];
        comp_data = 32'hB000_0000 + pending_ids[pick_idx];
        // remove from pending (it will become done this edge)
        pending_ids.delete(pick_idx);
      end
      // Randomly toggle commit_rdy (backpressure)
      commit_rdy = ($urandom_range(0,99) < 70);

      check_outputs("random");
      // Track newly allocated id for future completion targeting
      if (alloc_en && exp_alloc_rdy) begin
        pending_ids.push_back(exp_alloc_id);
      end
      gold_edge_update();
      @(posedge clk);
      #1;
    end

    // Final drain: stop allocating/completing new work incorrectly;
    // complete everything still pending, then drain all commits.
    alloc_en = 0;
    commit_rdy = 1;
    while (pending_ids.size() > 0) begin
      comp_en   = 1'b1;
      comp_id   = pending_ids[0][IDW-1:0];
      comp_data = 32'hC000_0000 + pending_ids[0];
      pending_ids.delete(0);
      do_cycle();
      comp_en = 0;
    end
    comp_en = 0;
    // Drain remaining commits
    for (int i = 0; i < DEPTH+2; i++) begin
      do_cycle();
    end

    check_outputs("final drain");
    if (commit_vld !== 1'b0) begin
      errors++;
      $display("[%0t] MISMATCH: commit_vld should be low after full drain", $time);
    end
    if (alloc_rdy !== 1'b1) begin
      errors++;
      $display("[%0t] MISMATCH: alloc_rdy should be high after full drain", $time);
    end

    if (errors == 0) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED: %0d error(s)", errors);
    end
    $finish;
  end

endmodule
