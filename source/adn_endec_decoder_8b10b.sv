/*

### Purpose
This module implements an 8b/10b decoder, which converts 10-bit encoded symbols back into their original 8-bit data bytes or control characters (K-codes). It performs disparity tracking and error detection to ensure the integrity of the received line-coded data.

### Usage
To use this module, provide the 10-bit encoded symbol to `code_in` and the current Running Disparity (RD) state to `rd_in`. The module will output the decoded 8-bit value on `data_out`. If the symbol represents a control character, `is_k` will be asserted. The `rd_out` signal provides the updated disparity for the next symbol. Error flags `code_err` and `disparity_err` indicate invalid symbols or disparity violations, respectively.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_8b10b (
    input  logic [9:0] code_in,       // 10-bit input symbol to be decoded
    input  logic       rd_in,         // Current Running Disparity (0: negative, 1: positive)
    output logic [7:0] data_out,      // Decoded 8-bit data byte
    output logic       is_k,          // High if the decoded symbol is a K-code (control character)
    output logic       rd_out,        // Updated Running Disparity for the next symbol
    output logic       code_err,      // High if the input symbol is invalid
    output logic       disparity_err  // High if a disparity violation is detected
);

  // Include shared 8b/10b encoding/decoding logic functions
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Candidate generation signals for brute-force matching
  logic         candidate_valid;   // Flag indicating if the generated candidate is valid
  logic   [9:0] candidate_code;    // The 10-bit code generated from candidate data
  logic         candidate_rd_out;  // The resulting RD after encoding the candidate
  integer       candidate;         // Loop index for iterating through all possible 8-bit values

  // Matching logic signals to store results for current and alternate RD states
  logic         match_same_rd;     // Match found using current RD
  logic         match_other_rd;    // Match found using inverted RD (disparity error case)
  logic   [7:0] same_data;         // Decoded data for current RD match
  logic         same_is_k;         // K-code status for current RD match
  logic         same_rd_out;       // RD output for current RD match
  logic   [7:0] other_data;        // Decoded data for alternate RD match
  logic         other_is_k;        // K-code status for alternate RD match
  logic         other_rd_out;      // RD output for alternate RD match

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to decode the input symbol by comparing against all possible 8b/10b mappings
  always_comb begin
    // Default assignments
    data_out = '0;
    is_k = 1'b0;
    rd_out = rd_in;
    code_err = 1'b1;
    disparity_err = 1'b0;

    match_same_rd = 1'b0;
    match_other_rd = 1'b0;
    same_data = '0;
    same_is_k = 1'b0;
    same_rd_out = rd_in;
    other_data = '0;
    other_is_k = 1'b0;
    other_rd_out = rd_in;

    // Iterate through all 256 possible data values and K-codes to find a match
    for (candidate = 0; candidate < 256; candidate = candidate + 1) begin
      // Check for standard data symbols
      encode_symbol(candidate[7:0], 1'b0, rd_in, candidate_valid, candidate_code, candidate_rd_out);
      if (candidate_valid && (candidate_code == code_in) && !match_same_rd) begin
        match_same_rd = 1'b1;
        same_data = candidate[7:0];
        same_is_k = 1'b0;
        same_rd_out = candidate_rd_out;
      end

      encode_symbol(candidate[7:0], 1'b0, ~rd_in, candidate_valid, candidate_code,
                    candidate_rd_out);
      if (candidate_valid && (candidate_code == code_in) && !match_other_rd) begin
        match_other_rd = 1'b1;
        other_data = candidate[7:0];
        other_is_k = 1'b0;
        other_rd_out = candidate_rd_out;
      end

      // Check for K-code symbols if the candidate is a valid control character
      if (is_valid_k(candidate[7:0])) begin
        encode_symbol(candidate[7:0], 1'b1, rd_in, candidate_valid, candidate_code,
                      candidate_rd_out);
        if (candidate_valid && (candidate_code == code_in) && !match_same_rd) begin
          match_same_rd = 1'b1;
          same_data = candidate[7:0];
          same_is_k = 1'b1;
          same_rd_out = candidate_rd_out;
        end

        encode_symbol(candidate[7:0], 1'b1, ~rd_in, candidate_valid, candidate_code,
                      candidate_rd_out);
        if (candidate_valid && (candidate_code == code_in) && !match_other_rd) begin
          match_other_rd = 1'b1;
          other_data = candidate[7:0];
          other_is_k = 1'b1;
          other_rd_out = candidate_rd_out;
        end
      end
    end

    // Final selection logic: prioritize matches with correct RD, flag disparity errors if only alternate RD matches
    if (match_same_rd) begin
      data_out = same_data;
      is_k = same_is_k;
      rd_out = same_rd_out;
      code_err = 1'b0;
    end else if (match_other_rd) begin
      data_out = other_data;
      is_k = other_is_k;
      rd_out = other_rd_out;
      code_err = 1'b0;
      disparity_err = 1'b1;
    end
  end

endmodule
