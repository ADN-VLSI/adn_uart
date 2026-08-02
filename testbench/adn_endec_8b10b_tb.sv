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

module adn_endec_8b10b_tb;

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic   [7:0] stimulus_data;
  logic         stimulus_k;
  logic         stimulus_rd;
  logic   [9:0] encoded_code;
  logic         encoded_rd;
  logic         encode_err;

  logic   [7:0] decoded_data;
  logic         decoded_k;
  logic         decoded_rd;
  logic         decode_err;
  logic         disparity_err;

  logic   [9:0] invalid_code;
  logic         invalid_rd;
  logic   [7:0] invalid_decoded_data;
  logic         invalid_decoded_k;
  logic         invalid_decoded_rd;
  logic         invalid_decode_err;
  logic         invalid_disparity_err;

  logic   [9:0] opposite_code;
  logic         opposite_rd;
  logic         opposite_encode_err;

  logic   [7:0] opposite_decoded_data;
  logic         opposite_decoded_k;
  logic         opposite_decoded_rd;
  logic         opposite_decode_err;
  logic         opposite_disparity_err;

  logic   [7:0] valid_k_codes          [0:11];
  integer       rd;
  integer       value;
  integer       idx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_endec_encoder_8b10b encoder_dut (
      .data_in(stimulus_data),
      .is_k(stimulus_k),
      .rd_in(stimulus_rd),
      .code_out(encoded_code),
      .rd_out(encoded_rd),
      .code_err(encode_err)
  );

  adn_endec_encoder_8b10b encoder_opposite_rd (
      .data_in(stimulus_data),
      .is_k(stimulus_k),
      .rd_in(~stimulus_rd),
      .code_out(opposite_code),
      .rd_out(opposite_rd),
      .code_err(opposite_encode_err)
  );

  adn_endec_decoder_8b10b decoder_dut (
      .code_in(encoded_code),
      .rd_in(stimulus_rd),
      .data_out(decoded_data),
      .is_k(decoded_k),
      .rd_out(decoded_rd),
      .code_err(decode_err),
      .disparity_err(disparity_err)
  );

  adn_endec_decoder_8b10b decoder_opposite_rd (
      .code_in(encoded_code),
      .rd_in(~stimulus_rd),
      .data_out(opposite_decoded_data),
      .is_k(opposite_decoded_k),
      .rd_out(opposite_decoded_rd),
      .code_err(opposite_decode_err),
      .disparity_err(opposite_disparity_err)
  );

  adn_endec_decoder_8b10b decoder_invalid_code (
      .code_in(invalid_code),
      .rd_in(invalid_rd),
      .data_out(invalid_decoded_data),
      .is_k(invalid_decoded_k),
      .rd_out(invalid_decoded_rd),
      .code_err(invalid_decode_err),
      .disparity_err(invalid_disparity_err)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_symbol(input logic [7:0] data, input logic is_k, input logic rd_positive);
    begin
      stimulus_data = data;
      stimulus_k    = is_k;
      stimulus_rd   = rd_positive;
      #1;

      if (encode_err) begin
        $display("FAIL encode_err data=%02h k=%0d rd=%0d", data, is_k, rd_positive);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decode_err) begin
        $display("FAIL decode_err code=%010b", encoded_code);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (disparity_err) begin
        $display("FAIL unexpected disparity_err code=%010b", encoded_code);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decoded_data != data) begin
        $display("FAIL decoded data mismatch code=%010b got=%02h exp=%02h", encoded_code,
                 decoded_data, data);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decoded_k != is_k) begin
        $display("FAIL decoded K mismatch code=%010b got=%0d exp=%0d", encoded_code, decoded_k,
                 is_k);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decoded_rd != encoded_rd) begin
        $display("FAIL decoded RD mismatch code=%010b got=%0d exp=%0d", encoded_code, decoded_rd,
                 encoded_rd);
        note_case(0);
      end else begin
        note_case(1);
      end

      if (!opposite_encode_err && (opposite_code != encoded_code)) begin
        if (opposite_decode_err) begin
          $display("FAIL opposite-RD decode_err code=%010b", encoded_code);
          note_case(0);
        end else begin
          note_case(1);
        end
        if (!opposite_disparity_err) begin
          $display("FAIL missing opposite-RD disparity_err code=%010b", encoded_code);
          note_case(0);
        end else begin
          note_case(1);
        end
        if (opposite_decoded_data != data) begin
          $display("FAIL opposite-RD data mismatch code=%010b got=%02h exp=%02h", encoded_code,
                   opposite_decoded_data, data);
          note_case(0);
        end else begin
          note_case(1);
        end
        if (opposite_decoded_k != is_k) begin
          $display("FAIL opposite-RD K mismatch code=%010b got=%0d exp=%0d", encoded_code,
                   opposite_decoded_k, is_k);
          note_case(0);
        end else begin
          note_case(1);
        end
        if (opposite_decoded_rd != encoded_rd) begin
          $display("FAIL opposite-RD RD mismatch code=%010b got=%0d exp=%0d", encoded_code,
                   opposite_decoded_rd, encoded_rd);
          note_case(0);
        end else begin
          note_case(1);
        end
      end else begin
        if (opposite_decode_err) begin
          $display("FAIL balanced symbol decode_err code=%010b", encoded_code);
          note_case(0);
        end else begin
          note_case(1);
        end
        if (opposite_disparity_err) begin
          $display("FAIL balanced symbol disparity_err code=%010b", encoded_code);
          note_case(0);
        end else begin
          note_case(1);
        end
      end
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////  

  initial begin
    valid_k_codes[0]  = 8'h1C;
    valid_k_codes[1]  = 8'h3C;
    valid_k_codes[2]  = 8'h5C;
    valid_k_codes[3]  = 8'h7C;
    valid_k_codes[4]  = 8'h9C;
    valid_k_codes[5]  = 8'hBC;
    valid_k_codes[6]  = 8'hDC;
    valid_k_codes[7]  = 8'hFC;
    valid_k_codes[8]  = 8'hF7;
    valid_k_codes[9]  = 8'hFB;
    valid_k_codes[10] = 8'hFD;
    valid_k_codes[11] = 8'hFE;

    for (rd = 0; rd < 2; rd = rd + 1) begin
      for (value = 0; value < 256; value = value + 1) begin
        check_symbol(value[7:0], 1'b0, rd[0]);
      end
    end

    for (rd = 0; rd < 2; rd = rd + 1) begin
      for (idx = 0; idx < 12; idx = idx + 1) begin
        check_symbol(valid_k_codes[idx], 1'b1, rd[0]);
      end
    end

    stimulus_rd = 1'b0;
    stimulus_k = 1'b1;
    stimulus_data = 8'h00;
    #1;
    if (!encode_err) begin
      $display("FAIL invalid K character should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    stimulus_rd = 1'b1;
    stimulus_k = 1'b0;
    stimulus_data = 8'h00;
    #1;
    if (encode_err) begin
      $display("FAIL data byte 00 should encode cleanly");
      note_case(0);
    end else begin
      note_case(1);
    end

    invalid_code = 10'b0000000000;
    invalid_rd   = 1'b0;
    #1;
    if (!invalid_decode_err) begin
      $display("FAIL all-zero 10b symbol should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    $display("8b10b encoder/decoder self-check passed");
    $finish;
  end

endmodule
