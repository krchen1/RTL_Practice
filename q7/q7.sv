// =============================================================================
// q7 - Pulse Synchronizer (Clock Domain Crossing)
// =============================================================================
// Problem:
//   src_pulse is a single-src_clk-cycle pulse generated in the source clock
//   domain (src_clk). Design a circuit that safely crosses this pulse into
//   an independent, asynchronous destination clock domain (dst_clk),
//   producing a corresponding single-dst_clk-cycle pulse dst_pulse.
//
//   HINT: the standard, robust technique for this is "toggle + double-flop
//   synchronizer + edge detect":
//     1. In the src_clk domain, toggle a flip-flop each time src_pulse fires.
//     2. Synchronize that toggle signal into the dst_clk domain with a
//        2-flop (or more) synchronizer chain to avoid metastability.
//     3. Edge-detect the synchronized toggle signal (XOR it with a
//        one-cycle-delayed version of itself) in the dst_clk domain to
//        produce a single-cycle dst_pulse.
//
// Interface:
//   input  logic src_clk    : source domain clock
//   input  logic src_rst    : source domain synchronous active-high reset
//   input  logic src_pulse  : single src_clk-cycle-wide pulse, source domain
//   input  logic dst_clk    : destination domain clock (independent, async)
//   input  logic dst_rst    : destination domain synchronous active-high reset
//   output logic dst_pulse  : single dst_clk-cycle-wide pulse, destination domain
//
// Assumptions / edge-case behavior:
//   - src_rst and dst_rst are each synchronous to their own clock and are
//     asserted/deasserted independently by the testbench.
//   - On reset (in either domain), that domain's registers reset such that
//     no spurious dst_pulse is produced.
//   - DOCUMENTED ASSUMPTION: consecutive src_pulse events are spaced at
//     least ~3 dst_clk periods apart, so the synchronizer never has to
//     absorb two source pulses before the previous one has been observed
//     in the destination domain (otherwise pulses could be lost/coalesced,
//     which is a fundamental limitation of this class of synchronizer, not
//     a bug to fix here).
//   - Every asserted src_pulse eventually produces exactly one dst_pulse
//     (given the spacing assumption above); no extra/missing dst_pulse.
// =============================================================================

module q7 (
    input  logic src_clk,
    input  logic src_rst,
    input  logic src_pulse,
    input  logic dst_clk,
    input  logic dst_rst,
    output logic dst_pulse
);

    // TODO: implement your RTL here

endmodule
