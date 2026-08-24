/*

| TEST CASE | DATE       | AUTHOR          | DESCRIPTION                                           |
|-----------|------------|-----------------|-------------------------------------------------------|  
| TC_001    | 2026-08-24 | Adnan Sami Anirban | 8N1, no parity, no extra stop                       |
| TC_002    | 2026-08-24 | Adnan Sami Anirban | 7 bits, even parity, extra stop bit                 |

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-24 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-08-24 | Adnan Sami Anirban | Stable release                                         |

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

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int DATA_WIDTH = 8;
  localparam int CLK_PERIOD = 10;                              // ns (check your `timescale)
  localparam int BAUD_RATE  = 1_000_000_000 / CLK_PERIOD;      // derived, not hardcoded

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
  logic       tx_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

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
      .tx_o         (tx_o         )
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

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
    #25;
    arst_ni = 1;
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

  task automatic send(input logic [7:0] data, input logic [1:0] data_bits, input logic parity_en,
                      input logic parity_type, input logic extra_stop);
    @(posedge clk_i);
    data_i        <= data;
    data_bits_i   <= data_bits;
    data_valid_i  <= '1;
    parity_en_i   <= parity_en;
    parity_type_i <= parity_type;
    extra_stop_i  <= extra_stop;
    do @(posedge clk_i);
    while(!data_ready_o);
    data_valid_i <= '0;
  endtask



  // Drives one frame into the DUT, listens on tx_o via uart_if.recv(),
  // and checks the decoded data against what was sent.
  // task automatic send_and_check(input byte      exp_data,
  //                                input bit [1:0] dbits_enc,
  //                                input bit       par_en,
  //                                input bit       par_type,
  //                                input bit       ex_stop);
  //   int  rx_data;
  //   bit  rx_parity;
  //   int  nbits;
  //   byte masked_exp;

  //   nbits      = decode_nbits(dbits_enc);
  //   masked_exp = exp_data & ((1 << nbits) - 1);

  //   // Arm the receiver BEFORE driving valid, so it doesn't miss the start bit
  //   fork
  //     uart_if.recv(rx_data, rx_parity, BAUD_RATE, par_en, par_type, ex_stop, nbits);
  //   join_none

  //   @(posedge clk_i);
  //   data_i        = exp_data;
  //   data_bits_i   = dbits_enc;
  //   parity_en_i   = par_en;
  //   parity_type_i = par_type;
  //   extra_stop_i  = ex_stop;
  //   data_valid_i  = 1;

  //   @(posedge clk_i iff data_ready_o);
  //   data_valid_i = 0;

  //   wait fork;

  //   if (rx_data !== masked_exp) begin
  //     $error("[send_and_check] Data mismatch: exp=%0h got=%0h (nbits=%0d)",
  //            masked_exp, rx_data, nbits);
  //     note_case(0);
  //   end else begin
  //     note_case(1);
  //   end
  // endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    $dumpfile("adn_uart_transmitter_tb.vcd");
    $dumpvars;
    apply_reset();
    #5;
    fork
      start_clk();
    join_none
    send('hAA, 0, 1, 0, 1);
    repeat(12) @(posedge clk_i);
    send('hAA, 1, 1, 0, 1);
    repeat(12) @(posedge clk_i);
    send('hAA, 2, 1, 0, 1);
    repeat(12) @(posedge clk_i);
    send('hAA, 3, 1, 0, 1);
    repeat(12) @(posedge clk_i);
    send('hAA, 3, 0, 0, 1);
    repeat(12) @(posedge clk_i);
    $finish;

  end

endmodule