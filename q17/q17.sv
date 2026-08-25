// =============================================================================
// q17 - Programmable clock divider (/2, /3, /4, /5)
// =============================================================================
// Problem:
//   Generate a divided output clock clk_out from the input clk, where the
//   divide ratio is set by div_sel.
//
// Interface:
//   input  logic clk            - free-running input clock.
//   input  logic rst            - synchronous, active-high. Resets internal
//                                  counters/state; clk_out starts low.
//   input  logic [2:0] div_sel  - the divide ratio, LITERALLY: div_sel==3'd2
//                                  means divide-by-2, div_sel==3'd3 means
//                                  divide-by-3, etc. The numeric value
//                                  directly IS the divide ratio (not an
//                                  encoded index). Only the values 2, 3, 4,
//                                  5 are defined/tested. div_sel may change
//                                  between test phases.
//   output logic clk_out         - the divided clock.
//
// Assumptions / pinned-down behavior:
//   - Requirement is on PERIOD only: in steady state, clk_out's rising
//     edges must occur exactly every div_sel input-clk cycles. A 50% duty
//     cycle is NOT required for the odd ratios (3 and 5) - only the
//     edge-to-edge period (measured in input clk cycles) must be correct.
//   - Changing div_sel mid-stream may cause ONE irregular transitional
//     period before clk_out settles into the new steady-state ratio. The
//     testbench accounts for this: after changing div_sel it lets a full
//     period or two pass before it starts measuring, rather than checking
//     immediately across the div_sel boundary.
//   - On rst, clk_out is driven low and internal counters clear; the
//     div_sel value present at/after reset determines the ratio going
//     forward (steady state begins after reset deasserts, same
//     "allow a period or two to settle" rule applies).
//   - Implementation hint: a free-running counter that counts input clk
//     cycles 0 .. div_sel-1 and toggles/pulses clk_out on a fixed point in
//     that count (e.g. clk_out high for count==0, low otherwise, giving a
//     one-input-clk-cycle-wide pulse every div_sel cycles - any waveform
//     shape is acceptable as long as consecutive rising edges are exactly
//     div_sel input-clk cycles apart in steady state).
// =============================================================================

module q17 (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] div_sel,
    output logic       clk_out
);

    // TODO: implement your RTL here

endmodule
