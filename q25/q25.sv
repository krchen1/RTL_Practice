// ===========================================================================
// q25.sv -- UART TX interface
//
// Title: UART TX interface
//
// Problem:
//   Implement a UART transmitter. Parameter CLKS_PER_BIT controls how many
//   clk cycles each bit is held for. In a real design this would be
//   clk_freq / baud_rate (e.g. ~868 for a 50MHz clock at 57600 baud), but
//   this testbench uses a SMALL value (default 4) purely to keep simulated
//   frame lengths short.
//
// Interface:
//   parameter int CLKS_PER_BIT = 4
//   input  logic       clk, rst    -- clk 10ns period, rst sync active-high
//   input  logic       tx_start    -- pulse to begin sending tx_data
//   input  logic [7:0] tx_data     -- byte to transmit (latched on tx_start)
//   output logic       tx_busy     -- high for the entire frame duration
//   output logic       tx_serial   -- the serial line, idles high
//
// Frame format (standard UART, no parity):
//   idle: tx_serial = 1
//   1 start bit (0), 8 data bits LSB-FIRST, 1 stop bit (1)
//   each bit held for exactly CLKS_PER_BIT clk cycles
//   total frame duration = 10 * CLKS_PER_BIT cycles
//
// Assumptions / edge cases pinned down for testability:
//   - tx_start is only sampled/honored while !tx_busy (a tx_start pulse
//     that arrives while tx_busy is high is ignored).
//   - tx_busy is high for the entire frame (10*CLKS_PER_BIT cycles) and low
//     otherwise, including at idle and immediately once the frame ends.
//     tx_busy and the start bit assert together on the same clock edge.
//   - tx_serial idles high before/after frames and stays high through the
//     stop bit and beyond, until the next start bit.
//   - No parity bit.
//   - On rst: return to idle (tx_busy=0, tx_serial=1).
// ===========================================================================

module q25 #(
  parameter int CLKS_PER_BIT = 4
) (
  input  logic       clk,
  input  logic       rst,
  input  logic       tx_start,
  input  logic [7:0] tx_data,
  output logic       tx_busy,
  output logic       tx_serial
);

  // TODO: implement your RTL here

endmodule
