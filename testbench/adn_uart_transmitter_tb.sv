/*

| TEST CASE | DATE       | AUTHOR             | DESCRIPTION                                            |
|-----------|------------|--------------------|---------------------------------------------------------|
| TC_001    | 2026-08-25 | Adnan Sami Anirban | 8N1, no parity, no extra stop                          |
| TC_002    | 2026-08-25 | Adnan Sami Anirban | 7 bits, even parity, extra stop bit                    |
| TC_003    | 2026-08-25 | Adnan Sami Anirban | 6 bits, odd parity, no extra stop                      |
| TC_004    | 2026-08-25 | Adnan Sami Anirban | 5 bits, no parity, extra stop                          |
| TC_005    | 2026-08-25 | Adnan Sami Anirban | All-zero data across each width                        |
| TC_006    | 2026-08-25 | Adnan Sami Anirban | All-ones data across each width (checks bit masking)   |
| TC_007    | 2026-08-25 | Adnan Sami Anirban | Parity off / even / odd, fixed data, 8 bits             |
| TC_008    | 2026-08-25 | Adnan Sami Anirban | 1 stop bit vs 2 stop bits, isolated                    |
| TC_009    | 2026-08-25 | Adnan Sami Anirban | Back-to-back frames, no idle gap between                |
| TC_010    | 2026-08-25 | Adnan Sami Anirban | Min data width (5b) combined with parity + extra stop   |
| TC_011    | 2026-08-25 | Adnan Sami Anirban | Randomized sweep across all configs                    |

| REVISION | DATE       | AUTHOR             | DESCRIPTION                                             |
|----------|------------|--------------------|----------------------------------------------------------|
| 0.1      | 2026-08-24 | Adnan Sami Anirban | Initial version                                          |
| 0.2      | 2026-08-25 | Adnan Sami Anirban | Fixed duplicate clock source                             |
| 0.3      | 2026-08-25 | Adnan Sami Anirban | Fixed signed/unsigned comparison bug (byte -> logic[7:0])|
| 0.4      | 2026-08-25 | Adnan Sami Anirban | Restructured into per-tc tasks, TN plusarg dispatch      |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
This file is part of ADN-VLSI/adn_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_uart_transmitter_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int DATA_WIDTH       = 8;
  localparam int CLK_PERIOD       = 10;                          // ns
  localparam int BAUD_RATE        = 1_000_000_000 / CLK_PERIOD;  // derived, not hardcoded
  localparam int NUM_RANDOM_CASES = 20;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  logic       arst_ni;
  logic       clk_i;
  logic       data_ready_o;
  logic       data_valid_i;
  logic [7:0] data_i;
  logic [1:0] data_bits_i;
  logic       parity_en_i;
  logic       parity_type_i;
  logic       extra_stop_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////
  int    pass_count;
  int    fail_count;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////
  adn_uart_if uart_if();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLASSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  initial begin
    clk_i = 0;
    fork
      start_clk();
    join_none
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  adn_uart_transmitter #(
      .DATA_WIDTH(DATA_WIDTH)
  ) dut (
      .arst_ni      (arst_ni      ),
      .clk_i        (clk_i        ),
      .data_ready_o (data_ready_o ),
      .data_valid_i (data_valid_i ),
      .data_i       (data_i       ),
      .data_bits_i  (data_bits_i  ),
      .parity_en_i  (parity_en_i  ),
      .parity_type_i(parity_type_i),
      .extra_stop_i (extra_stop_i ),
      .tx_o         (uart_if.line )
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Single clock source — do NOT fork this a second time elsewhere
  task automatic start_clk();
    forever begin
      #(CLK_PERIOD / 2);
      clk_i = 1;
      #(CLK_PERIOD / 2);
      clk_i = 0;
    end
  endtask

  task automatic apply_reset();
    arst_ni       = 0;
    data_valid_i  = 0;
    data_i        = '0;
    data_bits_i   = '0;
    parity_en_i   = 0;
    parity_type_i = 0;
    extra_stop_i  = 0;
    repeat (3) @(posedge clk_i);
    @(negedge clk_i);
    arst_ni = 1;
    @(posedge clk_i);
  endtask

  // Mirrors the DUT's data_bits_i -> nbits_d decode, so TB and DUT agree
  function automatic int decode_nbits(bit [1:0] data_bits_enc);
    case (data_bits_enc)
      2'd0:    return 5;
      2'd1:    return 6;
      2'd2:    return 7;
      default: return 8;
    endcase
  endfunction

  // Drives one frame's parallel inputs into the DUT
  task automatic send(input logic [7:0] data, input logic [1:0] dbits_enc,
                       input logic parity_en, input logic parity_type,
                       input logic extra_stop);
    @(posedge clk_i);
    data_i        <= data;
    data_bits_i   <= dbits_enc;
    parity_en_i   <= parity_en;
    parity_type_i <= parity_type;
    extra_stop_i  <= extra_stop;
    data_valid_i  <= 1'b1;
    do @(posedge clk_i); while (!data_ready_o);
    data_valid_i <= 1'b0;
  endtask

  // Listens on uart_if.line and returns the decoded frame
  task automatic receive(output int rx_data, output bit rx_parity,
                          input logic [1:0] dbits_enc, input logic parity_en,
                          input logic parity_type, input logic extra_stop);
    int nbits = decode_nbits(dbits_enc);
    uart_if.recv(rx_data, rx_parity, BAUD_RATE, parity_en, parity_type,
                 extra_stop, nbits);
  endtask

  // Full check: arms the receiver, drives the frame, compares result.
  // NOTE: masked_exp MUST be an unsigned type (logic [7:0]), not `byte`.
  // `byte` is signed in SystemVerilog, so values with bit7 set (e.g. 8'hA5)
  // sign-extend to 32'hFFFFFFA5 when compared against the unsigned `int`
  // rx_data (32'h000000A5), causing a false mismatch at nbits=8.
  task automatic send_and_check(input logic [7:0] exp_data, input logic [1:0] dbits_enc,
                                 input logic parity_en, input logic parity_type,
                                 input logic extra_stop, input string tc_name = "");
    int         rx_data;
    bit         rx_parity;
    int         nbits      = decode_nbits(dbits_enc);
    logic [7:0] masked_exp = exp_data & ((1 << nbits) - 1);

    // Arm the receiver BEFORE driving valid, so it doesn't miss the start bit
    fork
      receive(rx_data, rx_parity, dbits_enc, parity_en, parity_type, extra_stop);
    join_none

    send(exp_data, dbits_enc, parity_en, parity_type, extra_stop);

    wait fork;

    if (rx_data !== masked_exp) begin
      $error("[%s] Data mismatch: exp=%0h got=%0h (nbits=%0d, par_en=%0b, par_type=%0b, ex_stop=%0b)",
             tc_name, masked_exp, rx_data, nbits, parity_en, parity_type, extra_stop);
      fail_count++;
      note_case(0);
    end else begin
      $display("[%s] PASS: data=%0h (nbits=%0d, par_en=%0b, par_type=%0b, ex_stop=%0b)",
                tc_name, rx_data, nbits, parity_en, parity_type, extra_stop);
      pass_count++;
      note_case(1);
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST CASE TASKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic tc_001_basic_8n1();
    send_and_check(8'hA5, 2'd3, 0, 0, 0, "TC_001");
  endtask

  task automatic tc_002_7bit_even_parity_extra_stop();
    send_and_check(8'h5A, 2'd2, 1, 0, 1, "TC_002");
  endtask

  task automatic tc_003_6bit_odd_parity();
    send_and_check(8'h33, 2'd1, 1, 1, 0, "TC_003");
  endtask

  task automatic tc_004_5bit_extra_stop();
    send_and_check(8'h1F, 2'd0, 0, 0, 1, "TC_004");
  endtask

  task automatic tc_005_all_zero_sweep();
    send_and_check(8'h00, 2'd0, 0, 0, 0, "TC_005_5b_zero");
    send_and_check(8'h00, 2'd1, 0, 0, 0, "TC_005_6b_zero");
    send_and_check(8'h00, 2'd2, 0, 0, 0, "TC_005_7b_zero");
    send_and_check(8'h00, 2'd3, 0, 0, 0, "TC_005_8b_zero");
  endtask

  // All-ones data, each width — bits above the configured width should be
  // dropped by the DUT's bit counter, not just happen to be zero already
  // like tc_005 above.
  task automatic tc_006_all_ones_sweep();
    send_and_check(8'hFF, 2'd0, 0, 0, 0, "TC_006_5b_ones");
    send_and_check(8'hFF, 2'd1, 0, 0, 0, "TC_006_6b_ones");
    send_and_check(8'hFF, 2'd2, 0, 0, 0, "TC_006_7b_ones");
    send_and_check(8'hFF, 2'd3, 0, 0, 0, "TC_006_8b_ones");
  endtask

  // Same data throughout — isolates parity_en/parity_type from data and
  // width as confounding variables.
  task automatic tc_007_parity_combinations();
    send_and_check(8'h96, 2'd3, 0, 0, 0, "TC_007_par_off");
    send_and_check(8'h96, 2'd3, 1, 0, 0, "TC_007_par_even");
    send_and_check(8'h96, 2'd3, 1, 1, 0, "TC_007_par_odd");
  endtask

  task automatic tc_008_stop_bit_toggle();
    send_and_check(8'h3C, 2'd3, 0, 0, 0, "TC_008_1stop");
    send_and_check(8'h3C, 2'd3, 0, 0, 1, "TC_008_2stop");
  endtask

  // Three frames sent with zero idle gap between them — checks the DUT
  // reasserts data_ready_o and re-enters STATE_IDLE cleanly right after
  // STOP, without needing extra idle cycles first.
  task automatic tc_009_back_to_back();
    send_and_check(8'h11, 2'd3, 0, 0, 0, "TC_009_back2back_a");
    send_and_check(8'h22, 2'd3, 0, 0, 0, "TC_009_back2back_b");
    send_and_check(8'h33, 2'd3, 0, 0, 0, "TC_009_back2back_c");
  endtask

  // Smallest data window (5 bits) combined with the most frame overhead
  // (parity + 2 stop bits) — combined stress case.
  task automatic tc_010_min_width_max_frame();
    send_and_check(8'h1B, 2'd0, 1, 1, 1, "TC_010_min_width_max_frame");
  endtask

  task automatic tc_011_randomized_sweep();
    byte      rand_data;
    bit [1:0] rand_dbits_enc;
    bit       rand_parity_en;
    bit       rand_parity_typ;
    bit       rand_extra_stop;

    for (int i = 0; i < NUM_RANDOM_CASES; i++) begin
      rand_data       = $urandom;
      rand_dbits_enc  = $urandom_range(0, 3);
      rand_parity_en  = $urandom_range(0, 1);
      rand_parity_typ = $urandom_range(0, 1);
      rand_extra_stop = $urandom_range(0, 1);

      send_and_check(rand_data, rand_dbits_enc, rand_parity_en,
                      rand_parity_typ, rand_extra_stop,
                      $sformatf("TC_011_%0d", i));
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    $dumpfile("adn_uart_transmitter_tb.vcd");
    $dumpvars;

    pass_count = 0;
    fail_count = 0;

    apply_reset();

    case (test_name)
      "TC_ALL": begin
        $display("T=%0t: starting tc_001", $time);
        tc_001_basic_8n1();
        $display("T=%0t: tc_001 done", $time);
        $display("T=%0t: starting tc_002", $time);
        tc_002_7bit_even_parity_extra_stop();
        $display("T=%0t: tc_002 done", $time);
        $display("T=%0t: starting tc_003", $time);
        tc_003_6bit_odd_parity();
        $display("T=%0t: tc_003 done", $time);
        $display("T=%0t: starting tc_004", $time);
        tc_004_5bit_extra_stop();
        $display("T=%0t: tc_004 done", $time);
        $display("T=%0t: starting tc_005", $time);
        tc_005_all_zero_sweep();
        $display("T=%0t: tc_005 done", $time);
        $display("T=%0t: starting tc_006", $time);
        tc_006_all_ones_sweep();
        $display("T=%0t: tc_006 done", $time);
        $display("T=%0t: starting tc_007", $time);
        tc_007_parity_combinations();
        $display("T=%0t: tc_007 done", $time);
        $display("T=%0t: starting tc_008", $time);
        tc_008_stop_bit_toggle();
        $display("T=%0t: tc_008 done", $time);
        $display("T=%0t: starting tc_009", $time);
        tc_009_back_to_back();
        $display("T=%0t: tc_009 done", $time);
        $display("T=%0t: starting tc_010", $time);
        tc_010_min_width_max_frame();
        $display("T=%0t: tc_010 done", $time);
        $display("T=%0t: starting tc_011", $time);
        tc_011_randomized_sweep();
        $display("T=%0t: tc_011 done", $time);
        $display("T=%0t: all test cases done", $time);
        $display("T=%0t: simulation finished", $time);
      end
      "TC_001": tc_001_basic_8n1();
      "TC_002": tc_002_7bit_even_parity_extra_stop();
      "TC_003": tc_003_6bit_odd_parity();
      "TC_004": tc_004_5bit_extra_stop();
      "TC_005": tc_005_all_zero_sweep();
      "TC_006": tc_006_all_ones_sweep();
      "TC_007": tc_007_parity_combinations();
      "TC_008": tc_008_stop_bit_toggle();
      "TC_009": tc_009_back_to_back();
      "TC_010": tc_010_min_width_max_frame();
      "TC_011": tc_011_randomized_sweep();
      default: begin
        $error("Unknown test case name '%s' specified in TN parameter", test_name);
        $finish;
      end
    endcase

    $finish;
  end

endmodule