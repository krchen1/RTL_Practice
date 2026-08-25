// =============================================================================
// q2 - Fixed-Priority Arbiter (MSB = highest priority)
// =============================================================================
// Problem:
//   Implement a purely combinational fixed-priority arbiter. Given a vector of
//   request signals, grant access to exactly one requester: the one
//   corresponding to the MOST-significant SET bit of req. Priority decreases
//   from bit WIDTH-1 (highest priority) toward bit 0 (lowest priority).
//
// Interface:
//   parameter WIDTH        : number of requesters / width of req and gnt (default 8)
//   input  logic [WIDTH-1:0] req  : one bit per requester, 1 = requesting
//   output logic [WIDTH-1:0] gnt  : one-hot grant vector (or all-zero)
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - If req == 0, gnt == 0 (no grant).
//   - If multiple bits of req are set, exactly ONE bit of gnt is set: the
//     bit at the position of the most-significant '1' in req (bit WIDTH-1
//     wins over bit WIDTH-2, which wins over bit WIDTH-3, etc.).
//   - gnt is otherwise all zero (one-hot output, never more than one bit set).
// =============================================================================

module q2 #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] req,
    output logic [WIDTH-1:0] gnt
);

    // TODO: implement your RTL here

endmodule
