/*

# Purpose
This module implements a 4b5b decoder, which converts a 5-bit encoded symbol back into its original 4-bit data representation. It includes error detection to identify invalid 5-bit symbols that do not map to valid 4-bit data.

## Usage
To use this module, connect a 5-bit encoded symbol to the `code_in` port. The module will output the corresponding 4-bit data on `data_out` and assert `code_err` if the input symbol is invalid.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | YYYY-MM-DD | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_4b5b (
    input  logic [4:0] code_in,  // 5-bit encoded input symbol
    output logic [3:0] data_out, // 4-bit decoded data output
    output logic       code_err  // Error flag: high if input symbol is invalid
);

  // Include external lookup table and decoding logic functions
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Internal flag indicating if the current 5-bit input maps to a valid 4-bit symbol
  logic symbol_valid;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to perform 5b to 4b decoding and error checking
  always_comb begin
    // Call decoding function from included file
    decode_5b4b_symbol(code_in, symbol_valid, data_out);
    // Assert error signal if the symbol is not recognized as valid
    code_err = !symbol_valid;
  end

endmodule
