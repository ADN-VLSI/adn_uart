/*

| TEST CASE | TEST NAME | DATE | AUTHOR | DESCRIPTION |
|-----------|-----------|------------|-------------------------|-------------------------------------------------------|
| TC_001 | `reset` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies UART reset behavior. |
| TC_002 | `tx` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies basic UART TX operation using 8-bit data. |
| TC_003 | `rx` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies basic UART RX operation by receiving an 8-bit UART frame. |
| TC_004 | `loopback` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies TX-to-RX loopback operation. |
| TC_005 | `data_width` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies configurable UART data widths of 5, 6, 7, and 8 bits for both TX and RX operation. |
| TC_006 | `even_parity` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies even-parity operation in both TX and RX paths. |
| TC_006A | `even_parity_tx` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies even-parity generation and transmission on the TX path. |
| TC_006B | `even_parity_rx` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies even-parity detection and reception on the RX path. |
| TC_007 | `odd_parity` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies odd-parity operation in both TX and RX paths. |
| TC_007A | `odd_parity_tx` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies odd-parity generation and transmission on the TX path. |
| TC_007B | `odd_parity_rx` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies odd-parity detection and reception on the RX path. |
| TC_008 | `extra_stop` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies transmission and reception of a UART frame containing an additional stop bit. |
| TC_009 | `multiple_bytes` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies transmission and reception of multiple consecutive bytes while maintaining correct byte order and data integrity. |
| TC_010 | `bad_parity` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies RX rejection of a UART frame containing an incorrect parity bit and ensures `rx_valid` is not asserted. |
| TC_011 | `bad_stop` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies RX rejection of a UART frame containing an incorrect stop bit and ensures `rx_valid` is not asserted. |
| TC_012 | `tx_back_to_back` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies TX back-to-back transmission of two consecutive 8-bit frames and checks that both frames are transmitted correctly. |
| TC_013 | `rx_back_to_back` | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies RX back-to-back reception of two consecutive 8-bit frames and checks that both bytes are received correctly and in the correct order. |
| -------| `all` | 2026-08-16 | Md. Sakib Hasan Shawon | Runs the complete directed UART test suite. |

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-13 | Md. Sakib Hasan Shawon | Initial version                                 |
| 1.0      | 2026-08-16 | Md. Sakib Hasan Shawon | Stable release                                  |

Author : Md. Sakib Hasan Shawon (mdsakibhasanshawon20@gmail.com)
This file is part of ADN-VLSI/adn_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_uart_tx_rx_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Common testbench header providing test selection, pass/fail counters,
  // note_case(), VCD/debug handling, and final test summary.
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // RX clock is the reference clock for the UART receiver.
  localparam time RX_CLK_PERIOD = 10ns;

  // Receiver samples each UART bit using 8x oversampling.
  localparam int OVERSAMPLE = 8;

  // One UART bit period equals 8 RX clock cycles.
  localparam time UART_BIT_TIME = RX_CLK_PERIOD * OVERSAMPLE;

  // TX clock is configured to have exactly one UART bit per clock cycle.
  localparam time TX_CLK_PERIOD = UART_BIT_TIME;

  // Maximum number of RX clock cycles to wait for rx_valid.
  localparam int RX_TIMEOUT_CYCLES = 200;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic tx_clk;
  logic rx_clk;

  logic tx_arst_ni;
  logic rx_arst_ni;

  // UART interface shared between TX, RX, and the testbench.
  adn_uart_if uart_if ();

  // TX input/control signals and serial output.
  logic       tx_valid;
  logic       tx_ready;
  logic [7:0] tx_data;
  logic [1:0] tx_data_bits;
  logic       tx_parity_en;
  logic       tx_parity_type;
  logic       tx_extra_stop;
  logic       tx_serial;

  // RX configuration signals and received data/status.
  logic [1:0] rx_data_bits;
  logic       rx_parity_en;
  logic       rx_parity_type;
  logic [7:0] rx_data;
  logic       rx_valid;

  // Testbench-controlled RX line.
  // rx_tb_enable selects between direct RX stimulus and TX-RX loopback.
  logic       rx_tb_line;
  logic       rx_tb_enable;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Stores the result of the TX and RX monitors for the current test.
  bit         tx_result;
  bit         rx_result;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // UART channel model:
  //   0 -> connect TX directly to RX for loopback testing.
  //   1 -> allow the testbench to drive the RX line directly.
  assign uart_if.line = rx_tb_enable ? rx_tb_line : tx_serial;

  //////////////////////////////////////////////////////////////////////////////
  // TX DUT
  //////////////////////////////////////////////////////////////////////////////

  adn_uart_transmitter #(
      .DATA_WIDTH(8)
  ) u_tx (
      .arst_ni(tx_arst_ni),
      .clk_i  (tx_clk),

      .data_ready_o(tx_ready),
      .data_valid_i(tx_valid),

      .data_i(tx_data),

      .data_bits_i  (tx_data_bits),
      .parity_en_i  (tx_parity_en),
      .parity_type_i(tx_parity_type),
      .extra_stop_i (tx_extra_stop),

      .tx_o(tx_serial)
  );

  //////////////////////////////////////////////////////////////////////////////
  // RX DUT
  //////////////////////////////////////////////////////////////////////////////

  adn_uart_receiver #(
      .OVERSAMPLE(OVERSAMPLE)
  ) u_rx (
      .arst_ni(rx_arst_ni),
      .clk_i  (rx_clk),

      .data_bits_i  (rx_data_bits),
      .parity_en_i  (rx_parity_en),
      .parity_type_i(rx_parity_type),

      .rx_i(uart_if.line),

      .data_o(rx_data),
      .data_valid_o(rx_valid)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // DATA WIDTH CONFIGURATION
  //////////////////////////////////////////////////////////////////////////////

  // Converts the testbench data-width value into the encoding expected
  // by the UART TX/RX configuration inputs.
  function automatic logic [1:0] data_bits_cfg(input int nbits);

    case (nbits)

      5: return 2'b00;
      6: return 2'b01;
      7: return 2'b10;
      8: return 2'b11;

      default: begin
        $error("Invalid UART data width: %0d", nbits);
        return 2'b00;
      end

    endcase

  endfunction

  //////////////////////////////////////////////////////////////////////////////
  // RESET
  //////////////////////////////////////////////////////////////////////////////

  // Initializes the DUT and testbench signals, applies reset, and waits
  // for both TX and RX domains to become stable before releasing reset.
  task automatic reset_dut();

    tx_arst_ni = 1'b0;
    rx_arst_ni = 1'b0;

    tx_valid = 1'b0;
    tx_data = 8'h00;

    // Default UART configuration: 8 data bits, no parity, one stop bit.
    tx_data_bits = data_bits_cfg(8);
    tx_parity_en = 1'b0;
    tx_parity_type = 1'b0;
    tx_extra_stop = 1'b0;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b0;
    rx_parity_type = 1'b0;

    // Default RX line state is UART idle/high.
    rx_tb_enable = 1'b0;
    rx_tb_line = 1'b1;

    tx_result = 1'b0;
    rx_result = 1'b0;

    // Keep reset asserted long enough for both clock domains.
    repeat (5) @(posedge rx_clk);
    repeat (2) @(posedge tx_clk);

    // Release reset.
    tx_arst_ni = 1'b1;
    rx_arst_ni = 1'b1;

    // Allow both DUTs to operate for a few cycles after reset.
    repeat (2) @(posedge tx_clk);
    repeat (2) @(posedge rx_clk);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TX DRIVER
  //////////////////////////////////////////////////////////////////////////////

  // Sends one byte to the UART transmitter.
  // The task waits until TX is ready, configures the frame, and generates
  // a one-cycle data_valid pulse.
  task automatic send_tx(input logic [7:0] data, input int nbits = 8, input bit parity_en = 0,
                         input bit parity_type = 0, input bit extra_stop = 0);

    // Wait until the transmitter can accept a new byte.
    wait (tx_ready === 1'b1);

    @(negedge tx_clk);

    tx_data = data;
    tx_data_bits = data_bits_cfg(nbits);
    tx_parity_en = parity_en;
    tx_parity_type = parity_type;
    tx_extra_stop = extra_stop;
    tx_valid = 1'b1;

    // Keep data_valid asserted for one TX clock cycle.
    @(posedge tx_clk);

    @(negedge tx_clk);
    tx_valid = 1'b0;

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // RX DRIVER
  //////////////////////////////////////////////////////////////////////////////

  // Generates a UART frame directly on the RX input.
  //
  // Frame format:
  //   IDLE -> START -> DATA -> optional PARITY -> STOP -> optional STOP
  //
  // Data is transmitted LSB first. bad_parity and bad_stop are used
  // to intentionally generate invalid UART frames.
  task automatic send_uart(input logic [7:0] data, input int nbits = 8, input bit parity_en = 0,
                           input bit parity_type = 0, input bit extra_stop = 0,
                           input bit bad_parity = 0, input bit bad_stop = 0);

    time  bit_time;
    logic parity;
    int   i;

    // Every UART bit occupies exactly one UART_BIT_TIME.
    bit_time = UART_BIT_TIME;

    // Calculate parity from the selected number of data bits.
    parity   = 1'b0;

    for (i = 0; i < nbits; i++) parity ^= data[i];

    // Convert the calculated parity to odd parity when requested.
    if (parity_type) parity = ~parity;

    // Invert parity to intentionally generate a parity error.
    if (bad_parity) parity = ~parity;

    // IDLE
    rx_tb_line = 1'b1;
    #(bit_time);

    // START
    rx_tb_line = 1'b0;
    #(bit_time);

    // DATA - UART transmits the least significant bit first.
    for (i = 0; i < nbits; i++) begin
      rx_tb_line = data[i];
      #(bit_time);
    end

    // Optional PARITY bit.
    if (parity_en) begin
      rx_tb_line = parity;
      #(bit_time);
    end

    // STOP bit. Drive low when bad_stop is enabled to create an invalid frame.
    rx_tb_line = bad_stop ? 1'b0 : 1'b1;
    #(bit_time);

    // Optional second STOP bit.
    if (extra_stop) begin
      rx_tb_line = 1'b1;
      #(bit_time);
    end

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TX MONITOR
  //////////////////////////////////////////////////////////////////////////////

  // Monitors the serialized TX frame and compares it against the expected
  // data, parity, and stop-bit configuration.
  task automatic monitor_tx(input logic [7:0] expected_data, input int nbits, input bit parity_en,
                            input bit parity_type, input bit extra_stop, output bit result);

    logic [7:0] observed_data;
    logic parity;
    logic expected_parity;
    bit passed;

    result = 1'b0;
    passed = 1'b1;

    observed_data = 8'h00;
    expected_parity = 1'b0;

    // Wait for the falling edge that indicates the START bit.
    @(negedge tx_serial);

    // Sample the center of the START bit.
    #(UART_BIT_TIME / 2);

    if (tx_serial !== 1'b0) begin
      $error("[%0t] TX MONITOR: INVALID START bit", $time);
      passed = 1'b0;
    end

    // Move to the center of the first DATA bit.
    #(UART_BIT_TIME);

    // Sample DATA bits LSB first, one UART bit period apart.
    for (int i = 0; i < nbits; i++) begin
      observed_data[i] = tx_serial;
      #(TX_CLK_PERIOD);
    end

    // Compare the complete received data word.
    if (observed_data !== expected_data) begin

      $error("[%0t] TX MONITOR: DATA ERROR expected=%02h received=%02h", $time, expected_data,
             observed_data);

      passed = 1'b0;

    end

    // PARITY
    if (parity_en) begin

      // Calculate the expected parity from the transmitted data.
      parity = 1'b0;

      for (int i = 0; i < nbits; i++) parity ^= expected_data[i];

      if (parity_type) parity = ~parity;

      expected_parity = parity;

      if (tx_serial !== expected_parity) begin

        $error("[%0t] TX MONITOR: PARITY ERROR expected=%0b received=%0b", $time, expected_parity,
               tx_serial);

        passed = 1'b0;

      end

      #(TX_CLK_PERIOD);

    end

    // STOP
    if (tx_serial !== 1'b1) begin

      $error("[%0t] TX MONITOR: STOP ERROR expected=1 received=%0b", $time, tx_serial);

      passed = 1'b0;

    end

    #(TX_CLK_PERIOD);

    // EXTRA STOP
    if (extra_stop) begin

      if (tx_serial !== 1'b1) begin
        $error("[%0t] TX MONITOR: SECOND STOP ERROR", $time);
        passed = 1'b0;
      end

      #(TX_CLK_PERIOD);

    end

    result = passed;

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // RX MONITOR
  //////////////////////////////////////////////////////////////////////////////

  // Waits for rx_valid and verifies that the received data matches
  // the expected value. A timeout prevents the testbench from waiting forever
  // if the receiver does not recognize the UART frame.
  task automatic monitor_rx(input logic [7:0] expected_data, output bit result);

    result = 1'b0;

    // Wait for the receiver to indicate that a complete frame was received.
    for (int timeout = 0; timeout < RX_TIMEOUT_CYCLES; timeout++) begin

      @(posedge rx_clk);

      if (rx_valid === 1'b1) break;

    end

    // No valid frame was received within the allowed time.
    if (rx_valid !== 1'b1) begin
      $error("[%0t] RX MONITOR: TIMEOUT", $time);
      return;
    end

    // Verify the received data.
    if (rx_data !== expected_data) begin

      $error("[%0t] RX MONITOR: DATA ERROR expected=%02h received=%02h", $time, expected_data,
             rx_data);

      return;

    end

    result = 1'b1;

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // TEST 1
  // RESET
  //////////////////////////////////////////////////////////////////////////////

  // Verifies the default UART output state after reset.
  // TX must remain idle high and RX valid must remain low.
  task automatic test_1_reset();
    bit result;
    $display("\n========== TEST 1: RESET ==========");
    reset_dut();
    result = ((tx_serial === 1'b1) && (rx_valid === 1'b0));
    note_case(result);
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 2
  // TX BASIC
  //////////////////////////////////////////////////////////////////////////////

  // Verifies basic 8-bit TX operation without parity or extra stop bits.
  task automatic test_2_tx();
    $display("\n========== TEST 2: TX BASIC ==========");
    reset_dut();
    // Monitor and transmit the same byte concurrently.
    fork
      monitor_tx(8'hA5, 8, 0, 0, 0, tx_result);
      send_tx(8'hA5, 8, 0, 0, 0);
    join
    note_case(tx_result);
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 3
  // RX BASIC
  //////////////////////////////////////////////////////////////////////////////

  // Verifies basic 8-bit RX operation using a directly generated UART frame.
  task automatic test_3_rx();
    $display("\n========== TEST 3: RX BASIC ==========");
    reset_dut();

    // Enable direct testbench control of the RX line.
    rx_tb_enable   = 1'b1;

    rx_data_bits   = data_bits_cfg(8);
    rx_parity_en   = 1'b0;
    rx_parity_type = 1'b0;

    // Generate the RX frame while monitoring the receiver.
    fork
      monitor_rx(8'h3C, rx_result);
      send_uart(8'h3C, 8, 0, 0, 0);
    join

    note_case(rx_result);

    // Return the RX line to loopback mode.
    rx_tb_enable = 1'b0;

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 4
  // TX -> RX LOOPBACK
  //////////////////////////////////////////////////////////////////////////////

  // Verifies the complete TX-to-RX data path using the UART interface
  // as a direct loopback connection.
  task automatic test_4_loopback();

    $display("\n========== TEST 4: TX -> RX LOOPBACK ==========");
    reset_dut();

    // Disable direct RX stimulus so TX is connected directly to RX.
    rx_tb_enable   = 1'b0;

    tx_data_bits   = data_bits_cfg(8);
    tx_parity_en   = 1'b0;
    tx_parity_type = 1'b0;
    tx_extra_stop  = 1'b0;

    rx_data_bits   = data_bits_cfg(8);
    rx_parity_en   = 1'b0;
    rx_parity_type = 1'b0;

    // Monitor both sides while transmitting the same byte.
    fork
      monitor_tx(8'h55, 8, 0, 0, 0, tx_result);
      monitor_rx(8'h55, rx_result);
      send_tx(8'h55, 8, 0, 0, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 5
  // DATA WIDTH
  //////////////////////////////////////////////////////////////////////////////

  // Verifies UART operation with 5-, 6-, 7-, and 8-bit data widths.
  task automatic test_5_data_width();

    $display("\n========== TEST 5: DATA WIDTH ==========");

    // 5-bit data
    reset_dut();

    tx_data_bits = data_bits_cfg(5);
    rx_data_bits = data_bits_cfg(5);

    fork
      monitor_tx(8'h15, 5, 0, 0, 0, tx_result);
      monitor_rx(8'h15, rx_result);
      send_tx(8'h15, 5, 0, 0, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

    // 6-bit data
    reset_dut();

    tx_data_bits = data_bits_cfg(6);
    rx_data_bits = data_bits_cfg(6);

    fork
      monitor_tx(8'h2A, 6, 0, 0, 0, tx_result);
      monitor_rx(8'h2A, rx_result);
      send_tx(8'h2A, 6, 0, 0, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

    // 7-bit data
    reset_dut();

    tx_data_bits = data_bits_cfg(7);
    rx_data_bits = data_bits_cfg(7);

    fork
      monitor_tx(8'h55, 7, 0, 0, 0, tx_result);
      monitor_rx(8'h55, rx_result);
      send_tx(8'h55, 7, 0, 0, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

    // 8-bit data
    reset_dut();

    tx_data_bits = data_bits_cfg(8);
    rx_data_bits = data_bits_cfg(8);

    fork
      monitor_tx(8'hA5, 8, 0, 0, 0, tx_result);
      monitor_rx(8'hA5, rx_result);
      send_tx(8'hA5, 8, 0, 0, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 6
  // EVEN PARITY
  //////////////////////////////////////////////////////////////////////////////

  // Verifies TX and RX operation using 7-bit data with even parity.
  task automatic test_6_even_parity();

    $display("\n========== TEST 6: EVEN PARITY ==========");

    reset_dut();

    // Configure both TX and RX for even parity.
    tx_data_bits   = data_bits_cfg(7);
    tx_parity_en   = 1'b1;
    tx_parity_type = 1'b0;
    tx_extra_stop  = 1'b0;

    rx_data_bits   = data_bits_cfg(7);
    rx_parity_en   = 1'b1;
    rx_parity_type = 1'b0;

    fork
      monitor_tx(7'h55, 7, 1, 0, 0, tx_result);
      monitor_rx(7'h55, rx_result);
      send_tx(7'h55, 7, 1, 0, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 6A
  // EVEN PARITY TX
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the transmitter generates the correct even parity bit.
  task automatic test_6_even_parity_tx();

    $display("\n========== TEST 6A: EVEN PARITY TX ==========");

    reset_dut();

    fork
      monitor_tx(7'h55, 7, 1, 0, 0, tx_result);
      send_tx(7'h55, 7, 1, 0, 0);
    join
    note_case(tx_result);
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 6B
  // EVEN PARITY RX
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the receiver correctly accepts a valid even-parity frame.
  task automatic test_6_even_parity_rx();

    $display("\n========== TEST 6B: EVEN PARITY RX ==========");

    reset_dut();

    // Enable direct RX frame generation.
    rx_tb_enable   = 1'b1;

    rx_data_bits   = data_bits_cfg(7);
    rx_parity_en   = 1'b1;
    rx_parity_type = 1'b0;

    fork
      monitor_rx(7'h55, rx_result);
      send_uart(7'h55, 7, 1, 0, 0);
    join
    note_case(rx_result);
    rx_tb_enable = 1'b0;
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 7
  // ODD PARITY
  //////////////////////////////////////////////////////////////////////////////

  // Verifies TX and RX operation using 7-bit data with odd parity.
  task automatic test_7_odd_parity();

    $display("\n========== TEST 7: ODD PARITY ==========");

    reset_dut();

    // Configure both TX and RX for odd parity.
    tx_data_bits   = data_bits_cfg(7);
    tx_parity_en   = 1'b1;
    tx_parity_type = 1'b1;
    tx_extra_stop  = 1'b0;

    rx_data_bits   = data_bits_cfg(7);
    rx_parity_en   = 1'b1;
    rx_parity_type = 1'b1;

    fork
      monitor_tx(7'h25, 7, 1, 1, 0, tx_result);
      monitor_rx(7'h25, rx_result);
      send_tx(7'h25, 7, 1, 1, 0);
    join

    note_case(tx_result);
    note_case(rx_result);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 7A
  // ODD PARITY TX
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the transmitter generates the correct odd parity bit.
  task automatic test_7_odd_parity_tx();

    $display("\n========== TEST 7A: ODD PARITY TX ==========");

    reset_dut();

    fork
      monitor_tx(7'h55, 7, 1, 1, 0, tx_result);
      send_tx(7'h55, 7, 1, 1, 0);
    join

    note_case(tx_result);
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 7B
  // ODD PARITY RX
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the receiver correctly accepts a valid odd-parity frame.
  task automatic test_7_odd_parity_rx();

    $display("\n========== TEST 7B: ODD PARITY RX ==========");

    reset_dut();

    rx_tb_enable   = 1'b1;

    rx_data_bits   = data_bits_cfg(7);
    rx_parity_en   = 1'b1;
    rx_parity_type = 1'b1;

    fork
      monitor_rx(7'h55, rx_result);
      send_uart(7'h55, 7, 1, 1, 0);
    join
    note_case(rx_result);

    rx_tb_enable = 1'b0;
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 8
  // EXTRA STOP
  //////////////////////////////////////////////////////////////////////////////

  // Verifies transmission and reception of a frame containing two stop bits.
  task automatic test_8_extra_stop();

    $display("\n========== TEST 8: EXTRA STOP ==========");

    reset_dut();

    tx_data_bits   = data_bits_cfg(8);
    tx_parity_en   = 1'b0;
    tx_parity_type = 1'b0;
    tx_extra_stop  = 1'b1;

    rx_data_bits   = data_bits_cfg(8);
    rx_parity_en   = 1'b0;
    rx_parity_type = 1'b0;

    fork
      monitor_tx(8'h96, 8, 0, 0, 1, tx_result);
      monitor_rx(8'h96, rx_result);
      send_tx(8'h96, 8, 0, 0, 1);
    join

    note_case(tx_result);
    note_case(rx_result);
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 9
  // MULTIPLE BYTES
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that multiple consecutive bytes are transmitted and received
  // in the correct order without data corruption.
  task automatic test_9_multiple_bytes();

    logic [7:0] data;

    $display("\n========== TEST 9: MULTIPLE BYTES ==========");

    reset_dut();

    tx_data_bits = data_bits_cfg(8);
    rx_data_bits = data_bits_cfg(8);

    // Send four consecutive bytes: 10, 11, 12, and 13.
    for (int i = 0; i < 4; i++) begin

      data = 8'h10 + i;

      tx_result = 1'b0;
      rx_result = 1'b0;

      fork

        // Capture the current byte for the parallel TX monitor.
        begin
          automatic logic [7:0] expected = data;
          monitor_tx(expected, 8, 0, 0, 0, tx_result);
        end

        // Capture the current byte for the parallel RX monitor.
        begin
          automatic logic [7:0] expected = data;
          monitor_rx(expected, rx_result);
        end

        // Transmit the current byte.
        begin
          automatic logic [7:0] expected = data;
          send_tx(expected, 8, 0, 0, 0);
        end

      join

      note_case(tx_result);
      note_case(rx_result);

      // Ensure the transmitter is ready before starting the next byte.
      wait (tx_ready === 1'b1);

    end

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 10
  // BAD PARITY
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the receiver rejects a frame containing an incorrect
  // parity bit and does not assert rx_valid.
  task automatic test_10_bad_parity();

    bit bad_parity_result;

    $display("\n========== TEST 10: BAD PARITY ==========");

    reset_dut();

    // Enable direct RX stimulus and configure even parity.
    rx_tb_enable = 1'b1;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b1;
    rx_parity_type = 1'b0;

    // Test passes unless rx_valid is unexpectedly asserted.
    bad_parity_result = 1'b1;

    fork
      begin
        // Generate a frame with intentionally corrupted parity.
        send_uart(8'hA5, 8, 1, 0, 0, 1, 0);
      end

      begin

        // Monitor for an unexpected valid indication.
        repeat (RX_TIMEOUT_CYCLES) begin

          @(posedge rx_clk);

          if (rx_valid === 1'b1) begin

            $error("[%0t] BAD PARITY: rx_valid asserted unexpectedly, data=%02h", $time, rx_data);

            bad_parity_result = 1'b0;

            break;
          end
        end
      end
    join

    note_case(bad_parity_result);

    rx_tb_enable = 1'b0;
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 11
  // BAD STOP
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the receiver rejects a frame with an invalid stop bit.
  task automatic test_11_bad_stop();

    bit bad_stop_result;

    $display("\n========== TEST 11: BAD STOP BIT ==========");

    reset_dut();

    rx_tb_enable = 1'b1;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b0;
    rx_parity_type = 1'b0;

    // Test passes unless rx_valid is unexpectedly asserted.
    bad_stop_result = 1'b1;

    fork

      begin
        // Generate a frame with an intentionally invalid stop bit.
        send_uart(8'h5A, 8, 0, 0, 0, 0, 1);
      end

      begin

        // Monitor for an unexpected valid indication.
        repeat (RX_TIMEOUT_CYCLES) begin

          @(posedge rx_clk);

          if (rx_valid === 1'b1) begin

            $error("[%0t] BAD STOP: rx_valid asserted unexpectedly, data=%02h", $time, rx_data);

            bad_stop_result = 1'b0;

            break;
          end
        end
      end
    join

    note_case(bad_stop_result);

    rx_tb_enable = 1'b0;
  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 12
  // TX BACK-TO-BACK
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the transmitter can accept and transmit two consecutive
  // bytes while preserving their order.
  task automatic test_12_tx_back_to_back();

    bit result1;
    bit result2;

    $display("\n========== TEST 12: TX BACK-TO-BACK ==========");

    reset_dut();

    fork
      begin
        // Send the second byte as soon as the transmitter becomes ready.
        send_tx(8'h11, 8, 0, 0, 0);
        send_tx(8'h22, 8, 0, 0, 0);
      end

      begin
        // Verify both transmitted frames in sequence.
        monitor_tx(8'h11, 8, 0, 0, 0, result1);
        monitor_tx(8'h22, 8, 0, 0, 0, result2);
      end
    join

    note_case(result1);
    note_case(result2);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TEST 13
  // RX BACK-TO-BACK
  //////////////////////////////////////////////////////////////////////////////

  // Verifies that the receiver can receive two consecutive frames
  // and preserve their order.
  task automatic test_13_rx_back_to_back();

    bit result1;
    bit result2;

    $display("\n========== TEST 13: RX BACK-TO-BACK ==========");

    reset_dut();

    // Enable direct RX frame generation.
    rx_tb_enable = 1'b1;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b0;
    rx_parity_type = 1'b0;

    result1 = 1'b0;
    result2 = 1'b0;

    fork

      begin
        // Check the two received bytes in sequence.
        monitor_rx(8'h11, result1);
        monitor_rx(8'h22, result2);
      end

      begin
        // Generate the two UART frames in sequence.
        send_uart(8'h11, 8, 0, 0, 0);
        send_uart(8'h22, 8, 0, 0, 0);
      end

    join

    note_case(result1);
    note_case(result2);

    rx_tb_enable = 1'b0;
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLOCK GENERATION
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // TX clock period equals one complete UART bit period.
  initial begin
    tx_clk = 1'b0;
    forever #(TX_CLK_PERIOD / 2) tx_clk = ~tx_clk;
  end

  // RX clock runs at the oversampling frequency.
  initial begin
    rx_clk = 1'b0;
    forever #(RX_CLK_PERIOD / 2) rx_clk = ~rx_clk;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN TEST
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    // Initialize all testbench and DUT control signals.
    tx_arst_ni = 1'b0;
    rx_arst_ni = 1'b0;

    tx_valid = 1'b0;
    tx_data = 8'h00;

    tx_data_bits = data_bits_cfg(8);
    tx_parity_en = 1'b0;
    tx_parity_type = 1'b0;
    tx_extra_stop = 1'b0;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b0;
    rx_parity_type = 1'b0;

    rx_tb_enable = 1'b0;
    rx_tb_line = 1'b1;

    ////////////////////////////////////////////////////////////////////////
    // TEST SELECTION
    ////////////////////////////////////////////////////////////////////////

    // Select an individual test using +TN=<test_name>.
    // Use +TN=all to execute the complete UART test suite.
    case (test_name)

      "reset": test_1_reset();
      "tx": test_2_tx();
      "rx": test_3_rx();
      "loopback": test_4_loopback();
      "data_width": test_5_data_width();
      "even_parity": test_6_even_parity();
      "even_parity_tx": test_6_even_parity_tx();
      "even_parity_rx": test_6_even_parity_rx();
      "odd_parity": test_7_odd_parity();
      "odd_parity_tx": test_7_odd_parity_tx();
      "odd_parity_rx": test_7_odd_parity_rx();
      "extra_stop": test_8_extra_stop();
      "multiple_bytes": test_9_multiple_bytes();
      "bad_parity": test_10_bad_parity();
      "bad_stop": test_11_bad_stop();
      "tx_back_to_back": test_12_tx_back_to_back();
      "rx_back_to_back": test_13_rx_back_to_back();

      // Run the complete directed UART test suite.
      "all": begin

        test_1_reset();
        test_2_tx();
        test_3_rx();
        test_4_loopback();
        test_5_data_width();
        test_6_even_parity();
        test_6_even_parity_tx();
        test_6_even_parity_rx();
        test_7_odd_parity();
        test_7_odd_parity_tx();
        test_7_odd_parity_rx();
        test_8_extra_stop();
        test_9_multiple_bytes();
        test_10_bad_parity();
        test_11_bad_stop();
        test_12_tx_back_to_back();
        test_13_rx_back_to_back();
      end

      // Report an error if the requested test name is not supported.
      default: begin
        $error("Unknown test name: %s", test_name);
      end
    endcase

    $finish;
  end
endmodule
