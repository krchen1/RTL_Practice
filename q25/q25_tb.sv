// ===========================================================================
// q25_tb.sv -- Self-checking testbench for q25 (DO NOT EDIT)
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
//     that arrives while tx_busy is high is ignored -- this testbench only
//     issues tx_start once tx_busy is confirmed low).
//   - tx_busy is high for the entire frame (10*CLKS_PER_BIT cycles) and low
//     otherwise, including at idle and immediately once the frame ends.
//   - tx_serial idles high before/after frames and stays high through the
//     stop bit and beyond, until the next start bit.
//   - No parity bit.
//
// Golden model: for each byte, wait for !tx_busy, pulse tx_start with that
// tx_data, then SAMPLE tx_serial at the CENTER of each of the 10 bit
// periods (CLKS_PER_BIT/2 cycles into each bit slot) to reconstruct the
// start bit (expect 0), the 8 data bits (LSB-first, must reassemble to the
// transmitted byte), and the stop bit (expect 1). Also checks tx_busy
// timing and idle-high behavior.
// ===========================================================================

module q25_tb;

  localparam int CLKS_PER_BIT = 4;

  logic       clk, rst;
  logic       tx_start;
  logic [7:0] tx_data;
  logic       tx_busy;
  logic       tx_serial;

  int errors;

  q25 #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
    .clk       (clk),
    .rst       (rst),
    .tx_start  (tx_start),
    .tx_data   (tx_data),
    .tx_busy   (tx_busy),
    .tx_serial (tx_serial)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Watchdog
  initial begin
    #200000;
    $display("TEST FAILED: TIMEOUT");
    $finish;
  end

  task automatic send_and_check(input [7:0] byte_to_send);
    logic [9:0] sampled_bits; // [0]=start bit, [1:8]=data (lsb first), [9]=stop
    logic [7:0] reassembled;
    int busy_cycles;
    begin
      // Wait until not busy
      @(negedge clk);
      while (tx_busy) @(negedge clk);

      // Confirm idle line is high before we start
      if (tx_serial !== 1'b1) begin
        errors++;
        $display("[%0t] MISMATCH: tx_serial not idle-high before tx_start (byte=%0h): actual=%0b",
                  $time, byte_to_send, tx_serial);
      end

      // Pulse tx_start
      tx_data  = byte_to_send;
      tx_start = 1'b1;
      @(negedge clk);
      tx_start = 1'b0;

      // At this point (one negedge after the start pulse's clocked edge),
      // tx_busy should be high (frame begins).
      if (tx_busy !== 1'b1) begin
        errors++;
        $display("[%0t] MISMATCH: tx_busy not asserted right after tx_start (byte=%0h)",
                  $time, byte_to_send);
      end

      // Sample each of the 10 bit periods at their center.
      // We are currently sitting right at the boundary where bit slot 0
      // (the start bit) has just begun (1 cycle in already from the
      // @(negedge clk) above). Re-synchronize: wait to the next negedge
      // that begins bit slot 0 cleanly by using a cycle counter instead.
      busy_cycles = 0;
      for (int bit_idx = 0; bit_idx < 10; bit_idx++) begin
        // Wait CLKS_PER_BIT/2 cycles into this bit slot from its start.
        // Slot start: right after the previous negedge loop iteration.
        for (int c = 0; c < CLKS_PER_BIT/2; c++) begin
          @(negedge clk);
          busy_cycles++;
        end
        sampled_bits[bit_idx] = tx_serial;
        if (tx_busy !== 1'b1) begin
          errors++;
          $display("[%0t] MISMATCH: tx_busy dropped mid-frame (byte=%0h, bit_idx=%0d)",
                    $time, byte_to_send, bit_idx);
        end
        // Advance to the end of this bit slot.
        for (int c = CLKS_PER_BIT/2; c < CLKS_PER_BIT; c++) begin
          @(negedge clk);
          busy_cycles++;
        end
      end

      // Check start bit
      if (sampled_bits[0] !== 1'b0) begin
        errors++;
        $display("[%0t] MISMATCH: start bit not 0 (byte=%0h): sampled=%0b",
                  $time, byte_to_send, sampled_bits[0]);
      end

      // Reassemble data bits (LSB first -> bits[1..8])
      for (int i = 0; i < 8; i++) begin
        reassembled[i] = sampled_bits[1+i];
      end
      if (reassembled !== byte_to_send) begin
        errors++;
        $display("[%0t] MISMATCH: data mismatch: expected=%0h actual=%0h",
                  $time, byte_to_send, reassembled);
      end

      // Check stop bit
      if (sampled_bits[9] !== 1'b1) begin
        errors++;
        $display("[%0t] MISMATCH: stop bit not 1 (byte=%0h): sampled=%0b",
                  $time, byte_to_send, sampled_bits[9]);
      end

      // tx_busy should now be low (frame complete) and tx_serial idle-high
      @(negedge clk);
      if (tx_busy !== 1'b0) begin
        errors++;
        $display("[%0t] MISMATCH: tx_busy still high after frame should have completed (byte=%0h)",
                  $time, byte_to_send);
      end
      if (tx_serial !== 1'b1) begin
        errors++;
        $display("[%0t] MISMATCH: tx_serial not idle-high after frame (byte=%0h): actual=%0b",
                  $time, byte_to_send, tx_serial);
      end
    end
  endtask

  initial begin
    errors   = 0;
    tx_start = 0;
    tx_data  = 8'h00;
    rst      = 1;

    // Hold reset for first few cycles
    @(negedge clk);
    @(negedge clk);
    rst = 0;
    @(negedge clk);

    // Post-reset idle checks
    if (tx_busy !== 1'b0) begin
      errors++;
      $display("[%0t] MISMATCH: tx_busy not low after reset", $time);
    end
    if (tx_serial !== 1'b1) begin
      errors++;
      $display("[%0t] MISMATCH: tx_serial not idle-high after reset", $time);
    end

    // Directed edge cases
    send_and_check(8'h00);
    send_and_check(8'hFF);
    send_and_check(8'hA5);
    send_and_check(8'h01);
    send_and_check(8'h80);

    // Random bytes, back-to-back
    for (int i = 0; i < 40; i++) begin
      send_and_check($urandom_range(0,255));
    end

    if (errors == 0) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED: %0d error(s)", errors);
    end
    $finish;
  end

endmodule
