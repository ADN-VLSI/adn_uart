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

module adn_endec_64b66b_tb;

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [63:0] enc_payload_in;
  logic [ 1:0] enc_sync_header_in;
  logic [57:0] enc_state_in;
  logic [65:0] enc_block_out;
  logic [57:0] enc_state_out;
  logic        enc_header_err;

  logic [65:0] dec_block_in;
  logic [57:0] dec_state_in;
  logic [63:0] dec_payload_out;
  logic [ 1:0] dec_sync_header_out;
  logic [57:0] dec_state_out;
  logic        dec_header_err;

  logic [57:0] tx_state;
  logic [57:0] rx_state;
  logic [65:0] saved_valid_block;
  logic [57:0] saved_valid_state;
  logic [63:0] saved_valid_payload;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_endec_encoder_64b66b encoder_dut (
      .payload_in(enc_payload_in),
      .sync_header_in(enc_sync_header_in),
      .scramble_state_in(enc_state_in),
      .block_out(enc_block_out),
      .scramble_state_out(enc_state_out),
      .header_err(enc_header_err)
  );

  adn_endec_decoder_64b66b decoder_dut (
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
    input [63:0] payload;
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
        $display("FAIL 64b66b encoder header_err mismatch header=%b", sync_header);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_header_err != ((sync_header != 2'b01) && (sync_header != 2'b10))) begin
        $display("FAIL 64b66b decoder header_err mismatch header=%b", sync_header);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_payload_out != payload) begin
        $display("FAIL 64b66b payload mismatch exp=%016h got=%016h", payload, dec_payload_out);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_sync_header_out != sync_header) begin
        $display("FAIL 64b66b header mismatch exp=%b got=%b", sync_header, dec_sync_header_out);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (dec_state_out != enc_state_out) begin
        $display("FAIL 64b66b state mismatch exp=%015h got=%015h", enc_state_out, dec_state_out);
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
    tx_state = 58'h123456789ABCDE;
    rx_state = 58'h123456789ABCDE;

    check_stream_block(64'h0123456789ABCDEF, 2'b01);
    saved_valid_block   = enc_block_out;
    saved_valid_state   = enc_state_in;
    saved_valid_payload = enc_payload_in;
    check_stream_block(64'hFEDCBA9876543210, 2'b10);
    check_stream_block(64'h0000000000000000, 2'b00);
    check_stream_block(64'hFFFFFFFFFFFFFFFF, 2'b11);
    check_stream_block(64'hDEADBEEFCAFEBABE, 2'b01);

    dec_block_in = {2'b00, saved_valid_block[63:0]};
    dec_state_in = saved_valid_state;
    #1;

    if (!dec_header_err) begin
      $display("FAIL 64b66b corrupted header should raise header_err");
      note_case(0);
    end else begin
      note_case(1);
    end
    if (dec_payload_out != saved_valid_payload) begin
      $display("FAIL 64b66b corrupted-header payload mismatch exp=%016h got=%016h",
               saved_valid_payload, dec_payload_out);
      note_case(0);
    end else begin
      note_case(1);
    end

    $display("64b66b encoder/decoder self-check passed");
    $finish;
  end

endmodule
