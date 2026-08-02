/*

| TEST CASE | DATE       | AUTHOR          | DESCRIPTION                                           |
|-----------|------------|-----------------|-------------------------------------------------------|  
| TODO      | YYYY-MM-DD | Who?            | Test case description goes here                       |

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | YYYY-MM-DD | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_256b257b_tb;

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [255:0] enc_payload_in;
  logic         enc_sync_bit_in;
  logic [ 22:0] enc_state_in;
  logic [256:0] enc_block_out;
  logic [ 22:0] enc_state_out;
  logic         enc_header_err;

  logic [256:0] dec_block_in;
  logic [ 22:0] dec_state_in;
  logic [255:0] dec_payload_out;
  logic         dec_sync_bit_out;
  logic [ 22:0] dec_state_out;
  logic         dec_header_err;

  logic [ 22:0] tx_state;
  logic [ 22:0] rx_state;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_endec_encoder_256b257b encoder_dut (
      .payload_in(enc_payload_in),
      .sync_bit_in(enc_sync_bit_in),
      .scramble_state_in(enc_state_in),
      .block_out(enc_block_out),
      .scramble_state_out(enc_state_out),
      .header_err(enc_header_err)
  );

  adn_endec_decoder_256b257b decoder_dut (
      .block_in(dec_block_in),
      .scramble_state_in(dec_state_in),
      .payload_out(dec_payload_out),
      .sync_bit_out(dec_sync_bit_out),
      .scramble_state_out(dec_state_out),
      .header_err(dec_header_err)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_stream_block;
    input [255:0] payload;
    input sync_bit;
    begin
      enc_payload_in = payload;
      enc_sync_bit_in = sync_bit;
      enc_state_in = tx_state;
      #1;

      dec_block_in = enc_block_out;
      dec_state_in = rx_state;
      #1;

      if (enc_header_err) begin
        $display("FAIL 256b257b encoder header_err should remain low sync_bit=%b", sync_bit);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_header_err) begin
        $display("FAIL 256b257b decoder header_err should remain low sync_bit=%b", sync_bit);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_payload_out != payload) begin
        $display("FAIL 256b257b payload mismatch");
        $display("  exp=%064h", payload);
        $display("  got=%064h", dec_payload_out);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_sync_bit_out != sync_bit) begin
        $display("FAIL 256b257b sync bit mismatch exp=%b got=%b", sync_bit, dec_sync_bit_out);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_state_out != enc_state_out) begin
        $display("FAIL 256b257b state mismatch exp=%06h got=%06h", enc_state_out, dec_state_out);
        note_case(0);
      end else begin
        note_case(1);
      end

      tx_state = enc_state_out;
      rx_state = dec_state_out;
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    tx_state = 23'h42A5C3;
    rx_state = 23'h42A5C3;

    check_stream_block(256'h0123456789ABCDEFFEDCBA987654321000112233445566778899AABBCCDDEEFF, 1'b0);
    check_stream_block(256'hFFEEDDCCBBAA99887766554433221100F0E1D2C3B4A5968778695A4B3C2D1E0F, 1'b1);
    check_stream_block(256'h0000000000000000000000000000000000000000000000000000000000000000, 1'b0);
    check_stream_block(256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 1'b1);
    check_stream_block(256'hDEADBEEFCAFEBABE11223344556677889ABCDEF00123456789ABCDEF76543210, 1'b0);

    $display("256b257b encoder/decoder self-check passed");
    $finish;
  end

endmodule
