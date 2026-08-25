// ===========================================================================
// q6.sv -- Reorder buffer (ROB) micro-architecture and RTL
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
//   input  logic           alloc_en
//   output logic           alloc_rdy
//   output logic [IDW-1:0] alloc_id
//   -- COMPLETE (out-of-order execution finishing) port
//   input  logic           comp_en
//   input  logic [IDW-1:0] comp_id
//   input  logic [31:0]    comp_data
//   -- COMMIT (in-order retire) port
//   output logic           commit_vld
//   output logic [IDW-1:0] commit_id
//   output logic [31:0]    commit_data
//   input  logic           commit_rdy
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
// ===========================================================================

module q6 #(
  parameter int DEPTH = 8
) (
  input  logic                    clk,
  input  logic                    rst,
  // Allocate (dispatch) port
  input  logic                    alloc_en,
  output logic                    alloc_rdy,
  output logic [$clog2(DEPTH)-1:0] alloc_id,
  // Complete (out-of-order execution finishing) port
  input  logic                    comp_en,
  input  logic [$clog2(DEPTH)-1:0] comp_id,
  input  logic [31:0]             comp_data,
  // Commit (in-order retire) port
  output logic                    commit_vld,
  output logic [$clog2(DEPTH)-1:0] commit_id,
  output logic [31:0]             commit_data,
  input  logic                    commit_rdy
);

  // TODO: implement your RTL here

endmodule
