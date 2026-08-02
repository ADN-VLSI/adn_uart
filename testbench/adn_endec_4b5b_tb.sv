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

module adn_endec_4b5b_tb;

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic   [3:0] stimulus_data;
  logic   [4:0] encoded_code;
  logic         encode_err;

  logic   [3:0] decoded_data;
  logic         decode_err;

  logic   [4:0] invalid_code;
  logic   [3:0] invalid_decoded_data;
  logic         invalid_decode_err;

  integer       value;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_endec_encoder_4b5b encoder_dut (
      .data_in (stimulus_data),
      .code_out(encoded_code),
      .code_err(encode_err)
  );

  adn_endec_decoder_4b5b decoder_dut (
      .code_in (encoded_code),
      .data_out(decoded_data),
      .code_err(decode_err)
  );

  adn_endec_decoder_4b5b decoder_invalid_code (
      .code_in (invalid_code),
      .data_out(invalid_decoded_data),
      .code_err(invalid_decode_err)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_nibble;
    input [3:0] data;
    begin
      stimulus_data = data;
      #1;

      if (encode_err) begin
        $display("FAIL 4b5b encode_err data=%01h", data);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decode_err) begin
        $display("FAIL 4b5b decode_err code=%05b", encoded_code);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decoded_data != data) begin
        $display("FAIL 4b5b decoded data mismatch code=%05b got=%01h exp=%01h", encoded_code,
                 decoded_data, data);
        note_case(0);
      end else begin
        note_case(1);
      end
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    for (value = 0; value < 16; value = value + 1) begin
      check_nibble(value[3:0]);
    end

    invalid_code = 5'b00000;
    #1;
    if (!invalid_decode_err) begin
      $display("FAIL 4b5b all-zero symbol should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    invalid_code = 5'b00001;
    #1;
    if (!invalid_decode_err) begin
      $display("FAIL 4b5b symbol 00001 should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    invalid_code = 5'b11111;
    #1;
    if (!invalid_decode_err) begin
      $display("FAIL 4b5b symbol 11111 should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    $display("4b5b encoder/decoder self-check passed");
    $finish;
  end

endmodule
