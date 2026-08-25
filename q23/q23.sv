// =============================================================================
// q23 - Clock divide-by-10, 40% duty cycle
// =============================================================================
// Problem:
//   Generate a free-running divided clock clk_out with a FIXED (not
//   programmable) divide ratio of 10 and a 40% duty cycle.
//
// Interface:
//   input  logic clk     - free-running input clock.
//   input  logic rst     - synchronous, active-high. Resets the internal
//                           cycle counter and clk_out.
//   output logic clk_out - the divided, 40%-duty-cycle output clock.
//
// Assumptions / pinned-down behavior (exact reset-relative phase, so the
// waveform is unambiguous and testable):
//   - Internally maintain a cycle counter that counts 0..9 (wrapping 9->0),
//     starting at 0 on the first clock cycle after rst deasserts.
//   - clk_out is HIGH while the counter is in {0,1,2,3} (4 of 10 cycles =
//     40% duty) and LOW while the counter is in {4,5,6,7,8,9} (6 of 10
//     cycles = 60%).
//   - The counter wraps 9 -> 0 and the pattern repeats indefinitely,
//     free-running (no external control once out of reset).
// =============================================================================

module q23 (
    input  logic clk,
    input  logic rst,
    output logic clk_out
);

    // TODO: implement your RTL here

endmodule
