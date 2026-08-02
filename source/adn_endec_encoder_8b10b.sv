/*

### Purpose
The `adn_endec_encoder_8b10b` module implements an 8b/10b encoder, which converts 8-bit data bytes into 10-bit symbols. This encoding scheme is widely used in high-speed serial communication protocols to ensure DC balance and provide sufficient transition density for clock recovery.

### Usage
To use this module, provide an 8-bit data byte at `data_in` and set `is_k` high if the input is a control character (K-code) or low for data characters (D-code). The `rd_in` signal represents the current Running Disparity (RD) state. The module outputs the 10-bit encoded symbol at `code_out`, the updated running disparity at `rd_out`, and an error flag `code_err` if the input combination is invalid.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_8b10b (
    input  logic [7:0] data_in,  // 8-bit input data byte
    input  logic       is_k,     // Control character indicator (1: K-code, 0: D-code)
    input  logic       rd_in,    // Current Running Disparity (0: negative, 1: positive)
    output logic [9:0] code_out, // 10-bit encoded output symbol
    output logic       rd_out,   // Updated Running Disparity
    output logic       code_err  // Error flag (1: invalid input combination)
);

  // Include external lookup tables and encoding logic functions
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic       enc_valid;  // Internal flag indicating successful encoding
  logic [9:0] enc_code;   // Internal buffer for the 10-bit encoded symbol
  logic       enc_rd_out; // Internal buffer for the calculated running disparity

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to perform 8b/10b mapping and disparity calculation
  always_comb begin
    // Call the encoding function from the included header
    encode_symbol(data_in, is_k, rd_in, enc_valid, enc_code, enc_rd_out);
    
    // Drive output ports from internal signals
    code_out = enc_code;
    rd_out   = enc_rd_out;
    
    // Assert error flag if the encoding function returns invalid
    code_err = !enc_valid;
  end

endmodule
