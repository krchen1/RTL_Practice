// =============================================================================
// q18 - Ready/valid downsizer, 16-bit -> 8-bit
// =============================================================================
//
// Problem:
//   Implement a streaming datapath block that accepts 16-bit words on a
//   standard ready/valid ("AXI-stream-like") input interface and emits each
//   one as two 8-bit beats on a standard ready/valid output interface.
//
// Handshake convention (both interfaces):
//   A transfer happens on any clock cycle where the interface's valid AND
//   ready signals are both 1 at the clock edge. The source of a valid
//   signal must hold both `valid` and the associated data stable from the
//   cycle it first asserts `valid` until the cycle the transfer actually
//   completes (valid must never be retracted, and data must never change,
//   while waiting for the corresponding ready) -- this is the standard
//   streaming-interface driver discipline, expected on the in_* side from
//   whatever drives this module, and guaranteed by this module on the
//   out_* side.
//
// Interface:
//   input  logic        clk
//   input  logic        rst        // synchronous, active-high
//   input  logic        in_valid   // upstream has a 16-bit word for us
//   output logic        in_ready   // we can accept a new 16-bit word
//   input  logic [15:0] in_data    // the 16-bit word
//   output logic        out_valid  // we have an 8-bit beat for downstream
//   input  logic        out_ready  // downstream can accept our beat
//   output logic [7:0]  out_data   // the 8-bit beat
//
// Behavior / assumptions pinned down for testability:
//   - For every accepted 16-bit input word (in_valid && in_ready in the
//     same cycle), this module must produce exactly two 8-bit output
//     beats, in this order: FIRST in_data[15:8] (the high byte), THEN
//     in_data[7:0] (the low byte). "High byte first" is the chosen,
//     required convention.
//   - in_ready must be deasserted for the entire time a previous word's two
//     output beats are still draining out. In other words, this module
//     only accepts a new 16-bit input once BOTH bytes of the word
//     currently in flight have each been accepted on the output side (one
//     word "in flight" at a time, no pipelining across words).
//   - out_valid must stay asserted (with out_data held stable) until the
//     corresponding out_ready is seen; it must never be dropped without a
//     completed transfer.
//   - Synchronous, active-high reset returns the block to its idle state
//     (in_ready asserted, out_valid deasserted, nothing in flight).
//
// =============================================================================

module q18 (
    input  logic        clk,
    input  logic        rst,
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [15:0] in_data,
    output logic        out_valid,
    input  logic        out_ready,
    output logic [7:0]  out_data
);

    // TODO: implement your RTL here

endmodule
