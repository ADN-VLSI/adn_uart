/*

| TEST CASE | DATE | AUTHOR | DESCRIPTION |
|-----------|------------|-----------------|-------------------------------------------------------|
| TC_001 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies UART reset behavior|
| TC_002 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies basic UART TX operation using 8-bit|
| TC_003 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies basic UART RX operation by receiving an 8-bit UART frame |
| TC_004 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies TX-to-RX loopback operation|
| TC_005 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies configurable UART data widths of 5, 6, 7 and 8 bits for both TX and RX operation. |
| TC_006 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies even-parity operation in both TX and RX paths. |
| TC_006A | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies even-parity generation and transmission on the TX path|
| TC_006B | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies even-parity detection and reception on the RX path|
| TC_007 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies odd-parity operation in both TX and RX paths. |
| TC_007A | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies odd-parity generation and transmission on the TX path |
| TC_007B | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies odd-parity detection and reception on the RX path |
| TC_008 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies transmission and reception of a UART frame containing an additional stop bit. |
| TC_009 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies transmission and reception of multiple consecutive bytes while maintaining correct byte order and data integrity. |
| TC_010 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies RX rejection of a UART frame containing an incorrect parity bit and ensures `rx_valid` is not asserted. |
| TC_011 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies RX rejection of a UART frame containing an incorrect stop bit and ensures `rx_valid` is not asserted. |
| TC_012 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies TX back-to-back transmission of two consecutive 8-bit frames and checks that both frames are transmitted correctly. |
| TC_013 | 2026-08-13 | Md. Sakib Hasan Shawon | Verifies RX back-to-back reception of two consecutive 8-bit frames and checks that both bytes are received correctly and in the correct order. |

| REVISION | DATE | AUTHOR | DESCRIPTION |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1 | 2026-08-11 | Md. Sakib Hasan Shawon | Initial version |
| 1.0 | 2026-08-11 | Md. Sakib Hasan Shawon | Stable release |

Author : Md. Sakib Hasan Shawon (mdsakibhasanshawon20@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_uart_tx_rx_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam time RX_CLK_PERIOD = 10ns;
  localparam int OVERSAMPLE = 8;
  localparam time UART_BIT_TIME = RX_CLK_PERIOD * OVERSAMPLE;
  localparam time TX_CLK_PERIOD = UART_BIT_TIME;

  localparam int RX_TIMEOUT_CYCLES = 200;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST RESULT COUNTER
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int   pass_count = 0;
  int   fail_count = 0;

  bit   test_pass;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLOCK / RESET
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic tx_clk;
  logic rx_clk;

  logic tx_arst_ni;
  logic rx_arst_ni;

  initial begin
    tx_clk = 1'b0;
    forever #(TX_CLK_PERIOD / 2) tx_clk = ~tx_clk;
  end

  initial begin
    rx_clk = 1'b0;
    forever #(RX_CLK_PERIOD / 2) rx_clk = ~rx_clk;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // UART INTERFACE
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_uart_if uart_if ();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TX SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic tx_valid;
  logic tx_ready;
  logic [7:0] tx_data;

  logic [1:0] tx_data_bits;
  logic tx_parity_en;
  logic tx_parity_type;
  logic tx_extra_stop;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RX SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [1:0] rx_data_bits;
  logic rx_parity_en;
  logic rx_parity_type;

  logic [7:0] rx_data;
  logic rx_valid;

  logic rx_tb_line;
  logic rx_tb_enable;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST RESULTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  bit tx_result;
  bit rx_result;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // UART CHANNEL MODEL
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign uart_if.rx = rx_tb_enable ? rx_tb_line : uart_if.tx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TX DUT
  //////////////////////////////////////////////////////////////////////////////////////////////////

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

      .tx_o(uart_if.tx_driver)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RX DUT
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_uart_receiver #(
      .OVERSAMPLE(OVERSAMPLE)
  ) u_rx (
      .arst_ni(rx_arst_ni),
      .clk_i  (rx_clk),

      .data_bits_i  (rx_data_bits),
      .parity_en_i  (rx_parity_en),
      .parity_type_i(rx_parity_type),

      .rx_i(uart_if.rx),

      .data_o(rx_data),
      .data_valid_o(rx_valid)
  );

  //////////////////////////////////////////////////////////////////////////////
  // UTILITY FUNCTIONS
  //////////////////////////////////////////////////////////////////////////////

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

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RESET
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic reset_dut();

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

    tx_result = 1'b0;
    rx_result = 1'b0;

    // Hold reset for both clock domains.
    repeat (5) @(posedge rx_clk);

    repeat (2) @(posedge tx_clk);

    tx_arst_ni = 1'b1;
    rx_arst_ni = 1'b1;

    // Allow both DUTs to leave reset.
    repeat (2) @(posedge tx_clk);

    repeat (2) @(posedge rx_clk);

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // CHECK RESULT
  //////////////////////////////////////////////////////////////////////////////

  task automatic check_result(input bit result, input string test_name);

    if (result) begin
      pass_count++;
      $display("[%0t] %s : PASS", $time, test_name);
    end else begin
      fail_count++;
      $error("[%0t] %s : FAIL", $time, test_name);
    end

  endtask

  //////////////////////////////////////////////////////////////////////////////
  // TX DRIVER
  //////////////////////////////////////////////////////////////////////////////

  task automatic send_tx(input logic [7:0] data, input int nbits = 8, input bit parity_en = 0,
                         input bit parity_type = 0, input bit extra_stop = 0);

    wait (tx_ready === 1'b1);

    @(negedge tx_clk);

    tx_data = data;
    tx_data_bits = data_bits_cfg(nbits);
    tx_parity_en = parity_en;
    tx_parity_type = parity_type;
    tx_extra_stop = extra_stop;
    tx_valid = 1'b1;

    @(posedge tx_clk);

    @(negedge tx_clk);

    tx_valid = 1'b0;

  endtask

  /////////////////////////////////////////////////////////////
  // INTERFACE RX DRIVER
  //
  // Used to test receiver independently.
  /////////////////////////////////////////////////////////////

  task automatic send_uart(input logic [7:0] data, input int nbits = 8, input bit parity_en = 0,
                           input bit parity_type = 0, input bit extra_stop = 0,
                           input bit bad_parity = 0, input bit bad_stop = 0);

    time  bit_time;
    logic parity;
    int   i;

    bit_time = UART_BIT_TIME;

    parity   = 1'b0;

    for (i = 0; i < nbits; i++) parity ^= data[i];

    if (parity_type) parity = ~parity;

    if (bad_parity) parity = ~parity;

    // IDLE
    rx_tb_line = 1'b1;
    #(bit_time);

    // START
    rx_tb_line = 1'b0;
    #(bit_time);

    // DATA
    for (i = 0; i < nbits; i++) begin
      rx_tb_line = data[i];
      #(bit_time);
    end

    // PARITY
    if (parity_en) begin
      rx_tb_line = parity;
      #(bit_time);
    end

    // STOP
    rx_tb_line = bad_stop ? 1'b0 : 1'b1;
    #(bit_time);

    // SECOND STOP
    if (extra_stop) begin
      rx_tb_line = 1'b1;
      #(bit_time);
    end

  endtask

  /////////////////////////////////////////////////////////////
  // TX MONITOR
  //
  // Checks:
  // START -> DATA -> PARITY -> STOP
  /////////////////////////////////////////////////////////////

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

    // ---------------------------------------------------------
    // WAIT FOR START BIT
    // ---------------------------------------------------------

    @(negedge uart_if.tx);

    // Move to center of START bit.
    #(UART_BIT_TIME / 2);

    if (uart_if.tx !== 1'b0) begin
      $error("[%0t] TX MONITOR: INVALID START bit", $time);
      passed = 1'b0;
    end

    // ---------------------------------------------------------
    // MOVE TO CENTER OF FIRST DATA BIT
    // ---------------------------------------------------------

    #(UART_BIT_TIME);

    // ---------------------------------------------------------
    // DATA
    // ---------------------------------------------------------

    for (int i = 0; i < nbits; i++) begin

      observed_data[i] = uart_if.tx;

      #(TX_CLK_PERIOD);

    end

    // ---------------------------------------------------------
    // DATA CHECK
    // ---------------------------------------------------------

    if (observed_data !== expected_data) begin

      $error("[%0t] TX MONITOR: DATA ERROR expected=%02h received=%02h", $time, expected_data,
             observed_data);

      passed = 1'b0;

    end

    // ---------------------------------------------------------
    // PARITY
    // ---------------------------------------------------------

    if (parity_en) begin

      parity = 1'b0;

      for (int i = 0; i < nbits; i++) parity ^= expected_data[i];

      if (parity_type) parity = ~parity;

      expected_parity = parity;

      if (uart_if.tx !== expected_parity) begin

        $error("[%0t] TX MONITOR: PARITY ERROR expected=%0b received=%0b", $time, expected_parity,
               uart_if.tx);

        passed = 1'b0;

      end

      #(TX_CLK_PERIOD);

    end

    // ---------------------------------------------------------
    // STOP BIT
    // ---------------------------------------------------------

    if (uart_if.tx !== 1'b1) begin

      $error("[%0t] TX MONITOR: STOP ERROR expected=1 received=%0b", $time, uart_if.tx);

      passed = 1'b0;

    end

    #(TX_CLK_PERIOD);

    // ---------------------------------------------------------
    // EXTRA STOP BIT
    // ---------------------------------------------------------

    if (extra_stop) begin

      if (uart_if.tx !== 1'b1) begin

        $error("[%0t] TX MONITOR: SECOND STOP ERROR", $time);

        passed = 1'b0;

      end

      #(TX_CLK_PERIOD);

    end

    result = passed;

  endtask

  /////////////////////////////////////////////////////////////
  // RX MONITOR
  /////////////////////////////////////////////////////////////

  task automatic monitor_rx(input logic [7:0] expected_data, output bit result);

    result = 1'b0;

    for (int timeout = 0; timeout < RX_TIMEOUT_CYCLES; timeout++) begin

      @(posedge rx_clk);

      if (rx_valid === 1'b1) break;

    end

    if (rx_valid !== 1'b1) begin
      $error("[%0t] RX MONITOR: TIMEOUT", $time);
      return;
    end

    if (rx_data !== expected_data) begin
      $error("[%0t] RX MONITOR: DATA ERROR expected=%02h received=%02h", $time, expected_data,
             rx_data);
      return;
    end

    result = 1'b1;

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 1
  // RESET
  /////////////////////////////////////////////////////////////

  task automatic test_1_reset();

    bit result;

    $display("\n========== TEST 1: RESET ==========");

    reset_dut();

    result = ((uart_if.tx === 1'b1) && (rx_valid === 1'b0));

    check_result(result, "TEST 1: RESET");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 2
  // TX BASIC
  /////////////////////////////////////////////////////////////

  task automatic test_2_tx();

    $display("\n========== TEST 2: TX BASIC ==========");

    reset_dut();

    tx_data_bits  = data_bits_cfg(8);
    tx_parity_en  = 1'b0;
    tx_extra_stop = 1'b0;

    fork

      monitor_tx(8'hA5, 8, 0, 0, 0, tx_result);

      send_tx(8'hA5, 8, 0, 0, 0);

    join

    check_result(tx_result, "TEST 2: TX BASIC");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 3
  // RX BASIC
  /////////////////////////////////////////////////////////////

  task automatic test_3_rx();

    $display("\n========== TEST 3: RX BASIC ==========");

    reset_dut();

    rx_tb_enable   = 1'b1;

    rx_data_bits   = data_bits_cfg(8);
    rx_parity_en   = 1'b0;
    rx_parity_type = 1'b0;

    fork

      monitor_rx(8'h3C, rx_result);

      send_uart(8'h3C, 8, 0, 0, 0);

    join

    check_result(rx_result, "TEST 3: RX BASIC");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 4
  // TX -> RX LOOPBACK
  /////////////////////////////////////////////////////////////

  task automatic test_4_loopback();

    $display("\n========== TEST 4: TX -> RX LOOPBACK ==========");

    reset_dut();

    rx_tb_enable   = 1'b0;

    tx_data_bits   = data_bits_cfg(8);
    tx_parity_en   = 1'b0;
    tx_parity_type = 1'b0;
    tx_extra_stop  = 1'b0;

    rx_data_bits   = data_bits_cfg(8);
    rx_parity_en   = 1'b0;
    rx_parity_type = 1'b0;

    fork

      monitor_tx(8'h55, 8, 0, 0, 0, tx_result);

      monitor_rx(8'h55, rx_result);

      send_tx(8'h55, 8, 0, 0, 0);

    join

    check_result(tx_result, "TEST 4: TX MONITOR");
    check_result(rx_result, "TEST 4: RX MONITOR");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 5
  // DATA WIDTH
  /////////////////////////////////////////////////////////////

  task automatic test_5_data_width();

    $display("\n========== TEST 5: DATA WIDTH ==========");

    // -----------------------------------------------------
    // 5 BIT
    // -----------------------------------------------------

    reset_dut();

    tx_data_bits = data_bits_cfg(5);
    rx_data_bits = data_bits_cfg(5);

    fork

      monitor_tx(8'h15, 5, 0, 0, 0, tx_result);

      monitor_rx(8'h15, rx_result);

      send_tx(8'h15, 5, 0, 0, 0);

    join

    check_result(tx_result, "TEST 5: 5-BIT TX");
    check_result(rx_result, "TEST 5: 5-BIT RX");

    // -----------------------------------------------------
    // 6 BIT
    // -----------------------------------------------------

    reset_dut();

    tx_data_bits = data_bits_cfg(6);
    rx_data_bits = data_bits_cfg(6);

    fork

      monitor_tx(8'h2A, 6, 0, 0, 0, tx_result);

      monitor_rx(8'h2A, rx_result);

      send_tx(8'h2A, 6, 0, 0, 0);

    join

    check_result(tx_result, "TEST 5: 6-BIT TX");
    check_result(rx_result, "TEST 5: 6-BIT RX");

    // -----------------------------------------------------
    // 7 BIT
    // -----------------------------------------------------

    reset_dut();

    tx_data_bits = data_bits_cfg(7);
    rx_data_bits = data_bits_cfg(7);

    fork

      monitor_tx(8'h55, 7, 0, 0, 0, tx_result);

      monitor_rx(8'h55, rx_result);

      send_tx(8'h55, 7, 0, 0, 0);

    join

    check_result(tx_result, "TEST 5: 7-BIT TX");
    check_result(rx_result, "TEST 5: 7-BIT RX");

    // -----------------------------------------------------
    // 8 BIT
    // -----------------------------------------------------

    reset_dut();

    tx_data_bits = data_bits_cfg(8);
    rx_data_bits = data_bits_cfg(8);

    fork

      monitor_tx(8'hA5, 8, 0, 0, 0, tx_result);

      monitor_rx(8'hA5, rx_result);

      send_tx(8'hA5, 8, 0, 0, 0);

    join

    check_result(tx_result, "TEST 5: 8-BIT TX");
    check_result(rx_result, "TEST 5: 8-BIT RX");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 6
  // EVEN PARITY
  /////////////////////////////////////////////////////////////

  task automatic test_6_even_parity();

    $display("\n========== TEST 6: EVEN PARITY ==========");

    reset_dut();

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

    check_result(tx_result, "TEST 6: EVEN PARITY TX");
    check_result(rx_result, "TEST 6: EVEN PARITY RX");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 6A
  // EVEN PARITY - TX ONLY
  /////////////////////////////////////////////////////////////

  task automatic test_6_even_parity_tx();

    $display("\n========== TEST 6A: EVEN PARITY TX ==========");

    reset_dut();

    tx_data_bits   = data_bits_cfg(7);
    tx_parity_en   = 1'b1;
    tx_parity_type = 1'b0;
    tx_extra_stop  = 1'b0;

    fork

      monitor_tx(7'h55, 7, 1, 0, 0, tx_result);

      send_tx(7'h55, 7, 1, 0, 0);

    join

    check_result(tx_result, "TEST 6A: EVEN PARITY TX");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 6B
  // EVEN PARITY - RX ONLY
  /////////////////////////////////////////////////////////////

  task automatic test_6_even_parity_rx();

    $display("\n========== TEST 6B: EVEN PARITY RX ==========");

    reset_dut();

    rx_tb_enable   = 1'b1;

    rx_data_bits   = data_bits_cfg(7);
    rx_parity_en   = 1'b1;
    rx_parity_type = 1'b0;

    fork

      monitor_rx(7'h55, rx_result);

      send_uart(7'h55, 7, 1, 0, 0);

    join

    check_result(rx_result, "TEST 6B: EVEN PARITY RX");

    rx_tb_enable = 1'b0;

  endtask


  /////////////////////////////////////////////////////////////
  // TEST 7
  // ODD PARITY
  /////////////////////////////////////////////////////////////

  task automatic test_7_odd_parity();

    $display("\n========== TEST 7: ODD PARITY ==========");

    reset_dut();

    tx_data_bits   = data_bits_cfg(7);
    tx_parity_en   = 1'b1;
    tx_parity_type = 1'b1;
    tx_extra_stop  = 1'b0;

    rx_data_bits   = data_bits_cfg(7);
    rx_parity_en   = 1'b1;
    rx_parity_type = 1'b1;

    fork

      monitor_tx(7'hA5, 7, 1, 1, 0, tx_result);

      monitor_rx(7'hA5, rx_result);

      send_tx(7'hA5, 7, 1, 1, 0);

    join

    check_result(tx_result, "TEST 7: ODD PARITY TX");
    check_result(rx_result, "TEST 7: ODD PARITY RX");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 7A
  // ODD PARITY - TX ONLY
  /////////////////////////////////////////////////////////////

  task automatic test_7_odd_parity_tx();

    $display("\n========== TEST 7A: ODD PARITY TX ==========");

    reset_dut();

    tx_data_bits   = data_bits_cfg(7);
    tx_parity_en   = 1'b1;
    tx_parity_type = 1'b1;
    tx_extra_stop  = 1'b0;

    fork

      monitor_tx(7'h55, 7, 1, 1, 0, tx_result);

      send_tx(7'h55, 7, 1, 1, 0);

    join

    check_result(tx_result, "TEST 7A: ODD PARITY TX");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 7B
  // ODD PARITY - RX ONLY
  /////////////////////////////////////////////////////////////

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

    check_result(rx_result, "TEST 7B: ODD PARITY RX");

    rx_tb_enable = 1'b0;

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 8
  // EXTRA STOP BIT
  /////////////////////////////////////////////////////////////

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

    check_result(tx_result, "TEST 8: EXTRA STOP TX");

    // RX result only verifies that the receiver accepts
    // a frame containing an extra stop bit.
    check_result(rx_result, "TEST 8: EXTRA STOP RX ACCEPT");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 9
  // MULTIPLE BYTES / ORDER
  /////////////////////////////////////////////////////////////

  task automatic test_9_multiple_bytes();

    logic [7:0] data;

    $display("\n========== TEST 9: MULTIPLE BYTES ==========");

    reset_dut();

    tx_data_bits = data_bits_cfg(8);
    rx_data_bits = data_bits_cfg(8);

    for (int i = 0; i < 4; i++) begin

      data = 8'h10 + i;

      tx_result = 1'b0;
      rx_result = 1'b0;

      fork

        begin
          automatic logic [7:0] expected = data;

          monitor_tx(expected, 8, 0, 0, 0, tx_result);
        end

        begin
          automatic logic [7:0] expected = data;

          monitor_rx(expected, rx_result);
        end

        begin
          automatic logic [7:0] expected = data;

          send_tx(expected, 8, 0, 0, 0);
        end

      join

      check_result(tx_result, $sformatf("TEST 9: BYTE %0d TX expected=%02h", i, data));

      check_result(rx_result, $sformatf("TEST 9: BYTE %0d RX expected=%02h", i, data));

      // Wait for transmitter to become idle.
      wait (tx_ready === 1'b1);

    end

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 10
  // BAD PARITY
  /////////////////////////////////////////////////////////////

  task automatic test_10_bad_parity();

    bit bad_parity_result;

    $display("\n========== TEST 10: BAD PARITY ==========");

    reset_dut();

    rx_tb_enable = 1'b1;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b1;
    rx_parity_type = 1'b0;

    bad_parity_result = 1'b1;

    fork

      begin

        send_uart(8'hA5, 8, 1, 0, 0, 1,  // bad_parity
                  0 // bad_stop
);

      end

      begin

        // Wait long enough for the complete corrupted frame
        // to be processed by the receiver.
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

    check_result(bad_parity_result, "TEST 10: BAD PARITY REJECTION");

    rx_tb_enable = 1'b0;

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 11
  // BAD STOP BIT
  /////////////////////////////////////////////////////////////

  task automatic test_11_bad_stop();

    bit bad_stop_result;

    $display("\n========== TEST 11: BAD STOP BIT ==========");

    reset_dut();

    rx_tb_enable = 1'b1;

    rx_data_bits = data_bits_cfg(8);
    rx_parity_en = 1'b0;
    rx_parity_type = 1'b0;

    bad_stop_result = 1'b1;

    fork

      begin

        send_uart(8'h5A, 8, 0, 0, 0, 0,  // bad_parity
                  1 // bad_stop
        );

      end

      begin

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

    check_result(bad_stop_result, "TEST 11: BAD STOP REJECTION");

    rx_tb_enable = 1'b0;

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 12
  // TX BACK-TO-BACK
  /////////////////////////////////////////////////////////////

  task automatic test_12_tx_back_to_back();

    bit result1;
    bit result2;

    $display("\n========== TEST 12: TX BACK-TO-BACK ==========");

    reset_dut();

    tx_data_bits   = data_bits_cfg(8);
    tx_parity_en   = 1'b0;
    tx_parity_type = 1'b0;
    tx_extra_stop  = 1'b0;

    fork


      begin
        send_tx(8'h11, 8, 0, 0, 0);
        send_tx(8'h22, 8, 0, 0, 0);
      end

      begin
        monitor_tx(8'h11, 8, 0, 0, 0, result1);
        monitor_tx(8'h22, 8, 0, 0, 0, result2);
      end

    join

    check_result(result1, "TEST 12: FIRST BYTE");
    check_result(result2, "TEST 12: SECOND BYTE");

  endtask

  /////////////////////////////////////////////////////////////
  // TEST 13
  // RX BACK-TO-BACK
  /////////////////////////////////////////////////////////////

  task automatic test_13_rx_back_to_back();

    bit result1;
    bit result2;

    $display("\n========== TEST 13: RX BACK-TO-BACK ==========");

    reset_dut();

    rx_tb_enable = 1'b1;
    rx_data_bits = data_bits_cfg(7);
    rx_parity_en = 1'b0;
    rx_parity_type = 1'b0;

    result1 = 1'b0;
    result2 = 1'b0;

    fork

      begin
        monitor_rx(8'h11, result1);
        monitor_rx(8'h22, result2);
      end

      begin
        send_uart(8'h11, 7, 0, 0, 0);
        send_uart(8'h22, 7, 0, 0, 0);
      end

    join

    check_result(result1, "TEST 13: FIRST BYTE RX");
    check_result(result2, "TEST 13: SECOND BYTE RX");

    rx_tb_enable = 1'b0;

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN TEST
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    // Initial values

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

    // -------------------------------------------------------
    // RUN TESTS
    // -------------------------------------------------------

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


    // -------------------------------------------------------
    // FINAL SUMMARY
    // -------------------------------------------------------

    $display("");
    $display("============================================================");
    $display(" UART TESTBENCH SUMMARY");
    $display("============================================================");

    $display("TOTAL PASS : %0d", pass_count);
    $display("TOTAL FAIL : %0d", fail_count);

    if (fail_count == 0) begin

      $display("============================================================");
      $display(" ALL TESTS PASSED");
      $display("============================================================");

    end else begin

      $display("============================================================");
      $display(" TESTBENCH FAILED");
      $display("============================================================");

    end

    if (fail_count != 0) $fatal(1, "UART regression failed");

    $finish;

  end

endmodule

