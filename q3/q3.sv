// =============================================================================
// q3 - Round-Robin Arbiter (3 requesters)
// =============================================================================
// Problem:
//   Implement a round-robin arbiter for 3 requesters. The arbiter keeps a
//   registered 2-bit "pointer" (valid values 0, 1, 2) indicating which
//   requester has top priority THIS cycle.
//
//   Each cycle, gnt is a COMBINATIONAL function of the current req and the
//   current pointer register: scan the 3 requesters starting at "pointer"
//   and wrapping around (order: pointer, (pointer+1)%3, (pointer+2)%3),
//   and grant the FIRST one found with its req bit asserted. gnt is one-hot
//   (or all-zero if req == 3'b000).
//
//   On the next clock edge:
//     - If a grant happened this cycle at index i, pointer <= (i+1) % 3
//       (so the next requester in line gets top priority next cycle).
//     - If req was all-zero this cycle (no grant), pointer holds its value.
//
// Interface:
//   input  logic       clk   : clock
//   input  logic       rst   : synchronous, active-high reset
//   input  logic [2:0] req   : one bit per requester, 1 = requesting
//   output logic [2:0] gnt   : one-hot grant vector (or all-zero), combinational
//                              function of req and the current pointer state
//
// Assumptions / edge-case behavior:
//   - Synchronous active-high reset: on rst, pointer resets to 0 and gnt is 0.
//   - gnt is one-hot: never more than one bit set, all-zero when req==3'b000.
//   - pointer only ever takes values 0, 1, or 2.
// =============================================================================

module q3 (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] req,
    output logic [2:0] gnt
);

    // TODO: implement your RTL here

endmodule
