/*

| TEST CASE | TEST NAME                  | DATE       | AUTHOR                       | DESCRIPTION                                                 |
|-----------|----------------------------|------------|------------------------------|-------------------------------------------------------------|
| TC_001    | `five_bit_no_parity`       | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 5-bit UART reception with parity disabled.         |
| TC_002    | `six_bit_no_parity`        | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 6-bit UART reception with parity disabled.         |
| TC_003    | `seven_bit_no_parity`      | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 7-bit UART reception with parity disabled.         |
| TC_004    | `eight_bit_no_parity`      | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 8-bit UART reception with parity disabled.         |
| TC_005    | `five_bit_even_parity`     | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 5-bit UART reception with even parity enabled.     |
| TC_006    | `six_bit_even_parity`      | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 6-bit UART reception with even parity enabled.     |
| TC_007    | `seven_bit_even_parity`    | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 7-bit UART reception with even parity enabled.     |
| TC_008    | `eight_bit_even_parity`    | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 8-bit UART reception with even parity enabled.     |
| TC_009    | `five_bit_odd_parity`      | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 5-bit UART reception with odd parity enabled.      |
| TC_010    | `six_bit_odd_parity`       | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 6-bit UART reception with odd parity enabled.      |
| TC_011    | `seven_bit_odd_parity`     | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 7-bit UART reception with odd parity enabled.      |
| TC_012    | `eight_bit_odd_parity`     | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies 8-bit UART reception with odd parity enabled.      |
| TC_013    | `bad_parity`               | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies that a frame with incorrect parity is rejected.    |
| TC_014    | `bad_stop_bit`             | 2026-08-24 | Md. Sakib Hasan Shawon       | Verifies that a frame with an invalid stop bit is rejected. |
| --------- | `all`                      | 2026-08-24 | Md. Sakib Hasan Shawon       | Runs the complete directed UART receiver test suite.        |

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                                   |
|----------|------------|-----------------|---------------------------------------------------------------|
| 0.1      | 2026-08-24 | Md. Sakib Hasan Shawon | Initial version                                        |
| 1.0      | 2026-08-24 | Md. Sakib Hasan Shawon | Stable release                                         |

Author : Md. Sakib Hasan Shawon (mdsakibhasanshawon20@gmail.com)
This file is part of ADN-VLSI/adn_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_uart_receiver_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Number of system-clock samples used for one UART bit period.
  localparam int OVERSAMPLE = 8;

  // System clock period.
  localparam time CLK_PERIOD = 10ns;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Asynchronous active-low reset.
  logic       arst_ni;

  // System clock.
  logic       clk_i;

  // UART configuration.
  logic [1:0] data_bits_i;
  logic       parity_en_i;
  logic       parity_type_i;

  // Serial RX input.
  logic       rx_i;

  // DUT outputs.
  logic [7:0] data_o;
  logic       data_valid_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TESTBENCH VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [7:0] received_data;
  bit         received_valid;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // DUT
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_uart_receiver #(
      .OVERSAMPLE(OVERSAMPLE)
  ) dut (
      .arst_ni      (arst_ni),
      .clk_i        (clk_i),
      .data_bits_i  (data_bits_i),
      .parity_en_i  (parity_en_i),
      .parity_type_i(parity_type_i),
      .rx_i         (rx_i),
      .data_o       (data_o),
      .data_valid_o (data_valid_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLOCK
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    clk_i = 1'b0;

    forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RESET
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic reset_dut();

    rx_i = 1'b1;                  // Idle 

    data_bits_i = 2'b00;
    parity_en_i = 1'b0;
    parity_type_i = 1'b0;

    received_valid = 1'b0;
    received_data = 8'h00;

    arst_ni = 1'b0;               // reset

    repeat (4) begin
      @(negedge clk_i);
      #1ns;
    end

    arst_ni = 1'b1;

    repeat (4) begin
      @(negedge clk_i);
      #1ns;
    end

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // UART BIT DELAY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic uart_bit_delay();

    repeat (OVERSAMPLE) begin
      @(posedge clk_i);

      // Allow DUT nonblocking assignments to update.
      #1ns;

      if (data_valid_o) begin
        received_valid = 1'b1;
        received_data  = data_o;

        if (debug) begin
          $display("DEBUG: data_valid_o asserted at %0t, data_o=0x%02h", $time, data_o);
        end
      end
    end

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEND UART BIT
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic send_uart_bit(input logic bit_value);

    // Drive one serial bit.
    rx_i = bit_value;

    // Keep it stable for one complete UART bit period.
    uart_bit_delay();

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PARITY CALCULATION
  //////////////////////////////////////////////////////////////////////////////////////////////////

  function automatic logic calculate_parity(input logic [7:0] data, input logic [1:0] data_bits,
                                            input logic parity_type);

    logic parity;

    begin

      // Calculate XOR of the active data bits.
      case (data_bits)

        2'b00: begin
          // 5-bit data.
          parity = ^data[4:0];
        end

        2'b01: begin
          // 6-bit data.
          parity = ^data[5:0];
        end

        2'b10: begin
          // 7-bit data.
          parity = ^data[6:0];
        end

        2'b11: begin
          // 8-bit data.
          parity = ^data[7:0];
        end

        default: begin
          parity = ^data[7:0];
        end

      endcase

      // Invert XOR result for odd parity.
      if (parity_type) parity = ~parity;

      return parity;

    end

  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEND UART FRAME
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic send_uart_frame(input logic [7:0] data, input logic [1:0] data_bits,
                                 input logic parity_en, input logic parity_type,
                                 input bit bad_parity, input bit bad_stop);

    logic parity_bit;
    int   number_of_bits;

    begin

      // Determine the number of active data bits.
      case (data_bits)
        2'b00:   number_of_bits = 5;
        2'b01:   number_of_bits = 6;
        2'b10:   number_of_bits = 7;
        2'b11:   number_of_bits = 8;
        default: number_of_bits = 8;
      endcase

      // Ensure the line is idle before the frame.
      rx_i = 1'b1;
      uart_bit_delay();

      // START BIT.
      send_uart_bit(1'b0);

      // DATA BITS, LSB first.
      for (int i = 0; i < number_of_bits; i++) begin
        send_uart_bit(data[i]);
      end

      // PARITY BIT.
      if (parity_en) begin

        parity_bit = calculate_parity(data, data_bits, parity_type);

        // Intentionally corrupt parity when requested.
        if (bad_parity) parity_bit = ~parity_bit;

        send_uart_bit(parity_bit);

      end

      // STOP BIT.
      if (bad_stop) send_uart_bit(1'b0);
      else send_uart_bit(1'b1);

      // Return to UART idle.
      rx_i = 1'b1;

    end

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CHECK VALID FRAME
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_valid_frame(input logic [7:0] expected_data, input string case_name);

    logic result;

    begin

      result = (received_valid && (received_data === expected_data));

      if (result) begin

        $display("PASS: %-30s data=0x%02h valid=%b", case_name, received_data, received_valid);

      end else begin

        $display("FAIL: %-30s data=0x%02h expected=0x%02h valid_seen=%b", case_name, received_data,
                 expected_data, received_valid);

      end

      note_case(result);

    end

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CHECK INVALID FRAME
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_invalid_frame(input string case_name);

    logic result;

    begin

      result = !received_valid;

      if (result) begin

        $display("PASS: %-30s invalid frame rejected", case_name);

      end else begin

        $display("FAIL: %-30s invalid frame accepted, data=0x%02h", case_name, received_data);

      end

      note_case(result);

    end

  endtask
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 1
  // FIVE-BIT DATA, NO PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_1_five_bit_no_parity();

    $display("\n========== TEST 1: FIVE-BIT DATA, NO PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b00;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;

    // Send 10101, LSB first.
    send_uart_frame(8'h15, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'h15, "TC_001: FIVE-BIT NO PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 2
  // SIX-BIT DATA, NO PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_2_six_bit_no_parity();

    $display("\n========== TEST 2: SIX-BIT DATA, NO PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b01;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;

    send_uart_frame(8'h2A, 2'b01, 1'b0, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'h2A, "TC_002: SIX-BIT NO PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 3
  // SEVEN-BIT DATA, NO PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_3_seven_bit_no_parity();

    $display("\n========== TEST 3: SEVEN-BIT DATA, NO PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b10;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;

    send_uart_frame(8'h55, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'h55, "TC_003: SEVEN-BIT NO PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 4
  // EIGHT-BIT DATA, NO PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_4_eight_bit_no_parity();

    $display("\n========== TEST 4: EIGHT-BIT DATA, NO PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b11;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;

    send_uart_frame(8'hA5, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'hA5, "TC_004: EIGHT-BIT NO PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 5
  // FIVE-BIT DATA, EVEN PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_5_five_bit_even_parity();

    $display("\n========== TEST 5: FIVE-BIT DATA, EVEN PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b00;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b0;

    send_uart_frame(8'h15, 2'b00, 1'b1, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'h15, "TC_005: FIVE-BIT EVEN PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 6
  // SIX-BIT DATA, EVEN PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_6_six_bit_even_parity();

    $display("\n========== TEST 6: SIX-BIT DATA, EVEN PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b01;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b0;

    send_uart_frame(8'h2D, 2'b01, 1'b1, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'h2D, "TC_006: SIX-BIT EVEN PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 7
  // SEVEN-BIT DATA, EVEN PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_7_seven_bit_even_parity();

    $display("\n========== TEST 7: SEVEN-BIT DATA, EVEN PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b10;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b0;

    send_uart_frame(8'h53, 2'b10, 1'b1, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'h53, "TC_007: SEVEN-BIT EVEN PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 8
  // EIGHT-BIT DATA, EVEN PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_8_eight_bit_even_parity();

    $display("\n========== TEST 8: EIGHT-BIT DATA, EVEN PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b11;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b0;

    send_uart_frame(8'hA5, 2'b11, 1'b1, 1'b0, 1'b0, 1'b0);

    check_valid_frame(8'hA5, "TC_008: EIGHT-BIT EVEN PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 9
  // FIVE-BIT DATA, ODD PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_9_five_bit_odd_parity();

    $display("\n========== TEST 9: FIVE-BIT DATA, ODD PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b00;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b1;

    send_uart_frame(8'h0B, 2'b00, 1'b1, 1'b1, 1'b0, 1'b0);

    check_valid_frame(8'h0B, "TC_009: FIVE-BIT ODD PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 10
  // SIX-BIT DATA, ODD PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_10_six_bit_odd_parity();

    $display("\n========== TEST 10: SIX-BIT DATA, ODD PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b01;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b1;

    send_uart_frame(8'h16, 2'b01, 1'b1, 1'b1, 1'b0, 1'b0);

    check_valid_frame(8'h16, "TC_010: SIX-BIT ODD PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 11
  // SEVEN-BIT DATA, ODD PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_11_seven_bit_odd_parity();

    $display("\n========== TEST 11: SEVEN-BIT DATA, ODD PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b10;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b1;

    send_uart_frame(8'h65, 2'b10, 1'b1, 1'b1, 1'b0, 1'b0);

    check_valid_frame(8'h65, "TC_011: SEVEN-BIT ODD PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 12
  // EIGHT-BIT DATA, ODD PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_12_eight_bit_odd_parity();

    $display("\n========== TEST 12: EIGHT-BIT DATA, ODD PARITY ==========");

    reset_dut();

    data_bits_i   = 2'b11;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b1;

    send_uart_frame(8'h3C, 2'b11, 1'b1, 1'b1, 1'b0, 1'b0);

    check_valid_frame(8'h3C, "TC_012: EIGHT-BIT ODD PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 13
  // BAD PARITY
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_13_bad_parity();

    $display("\n========== TEST 13: BAD PARITY ==========");

    reset_dut();

    // 8-bit data with even parity.
    data_bits_i   = 2'b11;
    parity_en_i   = 1'b1;
    parity_type_i = 1'b0;

    /*
      bad_parity = 1
     
      The parity bit is intentionally inverted.
      Therefore the DUT must not assert data_valid_o.
     */

    send_uart_frame(8'hA5, 2'b11, 1'b1, 1'b0, 1'b1, 1'b0);

    check_invalid_frame("TC_013: BAD PARITY");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST 14
  // BAD STOP BIT
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic test_14_bad_stop_bit();

    $display("\n========== TEST 14: BAD STOP BIT ==========");

    reset_dut();

    // 8-bit data, no parity.
    data_bits_i   = 2'b11;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;

    /*
      bad_stop = 1
     
      Stop bit is intentionally driven LOW.
      The DUT must not assert data_valid_o.
     */

    send_uart_frame(8'h5A, 2'b11, 1'b0, 1'b0, 1'b0, 1'b1);

    check_invalid_frame("TC_014: BAD STOP BIT");

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN TEST
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    // Initialize all inputs.
    arst_ni       = 1'b0;
    data_bits_i   = 2'b00;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;
    rx_i          = 1'b1;

    // Allow the common testbench header to initialize.
    #1ns;

    $display("\n");
    $display("============================================================");
    $display("          ADN UART RECEIVER DIRECTED TESTBENCH");
    $display("============================================================");
    $display("OVERSAMPLE  = %0d", OVERSAMPLE);
    $display("CLK PERIOD  = %0t", CLK_PERIOD);
    $display("============================================================");

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // TEST SELECTION
    //////////////////////////////////////////////////////////////////////////////////////////////////

    case (test_name)

      "TC_001", "five_bit_no_parity": test_1_five_bit_no_parity();
      "TC_002", "six_bit_no_parity": test_2_six_bit_no_parity();
      "TC_003", "seven_bit_no_parity": test_3_seven_bit_no_parity();
      "TC_004", "eight_bit_no_parity": test_4_eight_bit_no_parity();

      "TC_005", "five_bit_even_parity": test_5_five_bit_even_parity();
      "TC_006", "six_bit_even_parity": test_6_six_bit_even_parity();
      "TC_007", "seven_bit_even_parity": test_7_seven_bit_even_parity();
      "TC_008", "eight_bit_even_parity": test_8_eight_bit_even_parity();

      "TC_009", "five_bit_odd_parity": test_9_five_bit_odd_parity();
      "TC_010", "six_bit_odd_parity": test_10_six_bit_odd_parity();
      "TC_011", "seven_bit_odd_parity": test_11_seven_bit_odd_parity();
      "TC_012", "eight_bit_odd_parity": test_12_eight_bit_odd_parity();

      "TC_013", "bad_parity": test_13_bad_parity();
      "TC_014", "bad_stop_bit": test_14_bad_stop_bit();

      "TC_ALL", "ALL", "default": begin

        test_1_five_bit_no_parity();
        test_2_six_bit_no_parity();
        test_3_seven_bit_no_parity();
        test_4_eight_bit_no_parity();

        test_5_five_bit_even_parity();
        test_6_six_bit_even_parity();
        test_7_seven_bit_even_parity();
        test_8_eight_bit_even_parity();

        test_9_five_bit_odd_parity();
        test_10_six_bit_odd_parity();
        test_11_seven_bit_odd_parity();
        test_12_eight_bit_odd_parity();

        test_13_bad_parity();
        test_14_bad_stop_bit();

      end

    endcase

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // SIMULATION END
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // Give the DUT a little time to complete the final frame.
    repeat (OVERSAMPLE * 2) @(posedge clk_i);

    $finish;

  end

endmodule
