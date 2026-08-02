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

module adn_endec_128b130b_tb;

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [127:0] enc_payload_in;
  logic [  1:0] enc_sync_header_in;
  logic [ 22:0] enc_state_in;
  logic [129:0] enc_block_out;
  logic [ 22:0] enc_state_out;
  logic         enc_header_err;

  logic [129:0] dec_block_in;
  logic [ 22:0] dec_state_in;
  logic [127:0] dec_payload_out;
  logic [  1:0] dec_sync_header_out;
  logic [ 22:0] dec_state_out;
  logic         dec_header_err;

  logic [ 22:0] tx_state;
  logic [ 22:0] rx_state;
  logic [129:0] saved_valid_block;
  logic [ 22:0] saved_valid_state;
  logic [127:0] saved_valid_payload;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_endec_encoder_128b130b encoder_dut (
      .payload_in(enc_payload_in),
      .sync_header_in(enc_sync_header_in),
      .scramble_state_in(enc_state_in),
      .block_out(enc_block_out),
      .scramble_state_out(enc_state_out),
      .header_err(enc_header_err)
  );

  adn_endec_decoder_128b130b decoder_dut (
      .block_in(dec_block_in),
      .scramble_state_in(dec_state_in),
      .payload_out(dec_payload_out),
      .sync_header_out(dec_sync_header_out),
      .scramble_state_out(dec_state_out),
      .header_err(dec_header_err)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_stream_block;
    input [127:0] payload;
    input [1:0] sync_header;
    begin
      enc_payload_in = payload;
      enc_sync_header_in = sync_header;
      enc_state_in = tx_state;
      #1;

      dec_block_in = enc_block_out;
      dec_state_in = rx_state;
      #1;

      if (enc_header_err != ((sync_header != 2'b01) && (sync_header != 2'b10))) begin
        $display("FAIL 128b130b encoder header_err mismatch header=%b", sync_header);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_header_err != ((sync_header != 2'b01) && (sync_header != 2'b10))) begin
        $display("FAIL 128b130b decoder header_err mismatch header=%b", sync_header);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_payload_out != payload) begin
        $display("FAIL 128b130b payload mismatch");
        $display("  exp=%032h", payload);
        $display("  got=%032h", dec_payload_out);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_sync_header_out != sync_header) begin
        $display("FAIL 128b130b header mismatch exp=%b got=%b", sync_header, dec_sync_header_out);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_state_out != enc_state_out) begin
        $display("FAIL 128b130b state mismatch exp=%06h got=%06h", enc_state_out, dec_state_out);
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
    tx_state = 23'h5A1C3D;
    rx_state = 23'h5A1C3D;

    check_stream_block(128'h0123456789ABCDEFFEDCBA9876543210, 2'b01);
    saved_valid_block   = enc_block_out;
    saved_valid_state   = enc_state_in;
    saved_valid_payload = enc_payload_in;
    check_stream_block(128'h000102030405060708090A0B0C0D0E0F, 2'b10);
    check_stream_block(128'h00112233445566778899AABBCCDDEEFF, 2'b00);
    check_stream_block(128'hFFEEDDCCBBAA99887766554433221100, 2'b11);
    check_stream_block(128'hDEADBEEFCAFEBABE1122334455667788, 2'b01);

    dec_block_in = {2'b11, saved_valid_block[127:0]};
    dec_state_in = saved_valid_state;
    #1;

    if (!dec_header_err) begin
      $display("FAIL 128b130b corrupted header should raise header_err");
      note_case(0);
    end else begin
      note_case(1);
    end
    if (dec_payload_out != saved_valid_payload) begin
      $display("FAIL 128b130b corrupted-header payload mismatch");
      $display("  exp=%032h", saved_valid_payload);
      $display("  got=%032h", dec_payload_out);
      note_case(0);
    end else begin
      note_case(1);
    end

    $display("128b130b encoder/decoder self-check passed");
    $finish;
  end

endmodule
