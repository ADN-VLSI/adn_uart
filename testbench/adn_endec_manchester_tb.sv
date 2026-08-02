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

module adn_endec_manchester_tb;

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam integer DATA_W = 8;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic   [    DATA_W-1:0] data_in;
  logic   [(2*DATA_W)-1:0] code_out;
  logic   [    DATA_W-1:0] decoded_data;
  logic                    decode_err;

  logic   [(2*DATA_W)-1:0] invalid_code_in;
  logic   [    DATA_W-1:0] invalid_decoded_data;
  logic                    invalid_decode_err;

  logic   [(2*DATA_W)-1:0] inverted_code_out;
  logic   [    DATA_W-1:0] inverted_decoded_data;
  logic                    inverted_decode_err;

  integer                  value;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_endec_encoder_manchester #(
      .DATA_W(DATA_W)
  ) encoder_dut (
      .data_in (data_in),
      .code_out(code_out)
  );

  adn_endec_decoder_manchester #(
      .DATA_W(DATA_W)
  ) decoder_dut (
      .code_in (code_out),
      .data_out(decoded_data),
      .code_err(decode_err)
  );

  adn_endec_decoder_manchester #(
      .DATA_W(DATA_W)
  ) invalid_decoder_dut (
      .code_in (invalid_code_in),
      .data_out(invalid_decoded_data),
      .code_err(invalid_decode_err)
  );

  adn_endec_encoder_manchester #(
      .DATA_W(DATA_W),
      .INVERT_POLARITY(1)
  ) inverted_encoder_dut (
      .data_in (data_in),
      .code_out(inverted_code_out)
  );

  adn_endec_decoder_manchester #(
      .DATA_W(DATA_W),
      .INVERT_POLARITY(1)
  ) inverted_decoder_dut (
      .code_in (inverted_code_out),
      .data_out(inverted_decoded_data),
      .code_err(inverted_decode_err)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic check_round_trip;
    input [DATA_W-1:0] payload;
    begin
      data_in = payload;
      #1;

      if (decode_err) begin
        $display("FAIL Manchester decode_err payload=%02h", payload);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (decoded_data != payload) begin
        $display("FAIL Manchester decoded mismatch exp=%02h got=%02h", payload, decoded_data);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (inverted_decode_err) begin
        $display("FAIL inverted Manchester decode_err payload=%02h", payload);
        note_case(0);
      end else begin
        note_case(1);
      end
      if (inverted_decoded_data != payload) begin
        $display("FAIL inverted Manchester decoded mismatch exp=%02h got=%02h", payload,
                 inverted_decoded_data);
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
    data_in = {DATA_W{1'b0}};
    invalid_code_in = {(2 * DATA_W) {1'b0}};
    #1;

    if (code_out != 16'h5555) begin
      $display("FAIL Manchester zero encoding exp=5555 got=%04h", code_out);
      note_case(0);
    end else begin
      note_case(1);
    end
    if (inverted_code_out != 16'hAAAA) begin
      $display("FAIL inverted Manchester zero encoding exp=AAAA got=%04h", inverted_code_out);
      note_case(0);
    end else begin
      note_case(1);
    end

    data_in = {DATA_W{1'b1}};
    #1;
    if (code_out != 16'hAAAA) begin
      $display("FAIL Manchester ones encoding exp=AAAA got=%04h", code_out);
      note_case(0);
    end else begin
      note_case(1);
    end
    if (inverted_code_out != 16'h5555) begin
      $display("FAIL inverted Manchester ones encoding exp=5555 got=%04h", inverted_code_out);
      note_case(0);
    end else begin
      note_case(1);
    end

    for (value = 0; value < 256; value = value + 1) begin
      check_round_trip(value[DATA_W-1:0]);
    end

    invalid_code_in = 16'h0000;
    #1;
    if (!invalid_decode_err) begin
      $display("FAIL Manchester all-zero line code should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    invalid_code_in = 16'hFFFF;
    #1;
    if (!invalid_decode_err) begin
      $display("FAIL Manchester all-one line code should raise code_err");
      note_case(0);
    end else begin
      note_case(1);
    end

    invalid_code_in = 16'h56A9;
    #1;
    if (invalid_decode_err) begin
      $display("FAIL Manchester mixed valid line code should decode cleanly");
      note_case(0);
    end else begin
      note_case(1);
    end

    $display("Manchester encoder/decoder self-check passed");
    $finish;
  end

endmodule
