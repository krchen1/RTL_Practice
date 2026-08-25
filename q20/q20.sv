// =============================================================================
// q20 - "11011" Sequence Detector (Moore FSM, overlapping matches)
// =============================================================================
// Problem:
//   bit_in is a serial bit stream, sampled on every rising clock edge.
//   Detect the pattern 11011 in the stream. OVERLAPPING matches are allowed:
//   e.g. in the stream 1101101..., a match completing at one position can
//   share bits with the start of the next match (the trailing "11" of one
//   match is also the leading "11" of the next potential match).
//
//   Precise timing contract (Moore-style registered output):
//   On the clock edge where bit_in is sampled as the 5th and final bit that
//   completes a 11011 pattern (using overlap with prior bits), detected
//   shall be driven high starting the cycle immediately AFTER that edge,
//   held high for exactly one cycle, then low again (until the next match).
//
// Interface:
//   input  logic clk       : clock
//   input  logic rst       : synchronous, active-high reset
//   input  logic bit_in    : serial input bit, sampled every clock edge
//   output logic detected  : registered (Moore), high for exactly 1 cycle
//                             the cycle after a 11011 match completes
//
// Assumptions / edge-case behavior:
//   - Synchronous active-high reset: on rst, FSM state resets and detected
//     is driven to 0.
//   - Overlapping matches are allowed and must all be detected (e.g. the
//     stream 1101101 contains a match ending at bit index 4 (0-indexed)
//     and, if continued as 1101101101, another overlapping match later).
//   - detected is a registered output: it is never combinationally derived
//     from the same-cycle bit_in; it reflects the match completed on the
//     PREVIOUS clock edge.
// =============================================================================

module q20 (
    input  logic clk,
    input  logic rst,
    input  logic bit_in,
    output logic detected
);

    // TODO: implement your RTL here

endmodule
