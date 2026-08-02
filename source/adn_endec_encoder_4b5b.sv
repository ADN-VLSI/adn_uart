/*

### Purpose
This module implements a 4b5b line encoder, which maps 4-bit input data symbols to 5-bit output codes. This encoding scheme is commonly used in data communication protocols to ensure sufficient transition density for clock recovery and to provide error detection capabilities.

### Usage
To use this module, connect a 4-bit data bus to `data_in`. The module will output the corresponding 5-bit 4b5b encoded symbol on `code_out`. If the input symbol is invalid (e.g., in protocols where certain 4-bit combinations are reserved), the `code_err` signal will be asserted high. The encoding logic is handled by the included `adn_endec_block_linecode_functions.svh` file.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_4b5b (
  input  logic [3:0] data_in,  // 4-bit input data to be encoded
  output logic [4:0] code_out, // 5-bit encoded output symbol
  output logic       code_err  // Error flag: high if input symbol is invalid
);

  // Include external lookup table and encoding logic functions
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Internal flag to track if the input data maps to a valid 4b5b symbol
  logic symbol_valid;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to perform the 4b5b mapping and error detection
  always_comb begin
    // Call the encoding function from the included SVH file
    encode_4b5b_symbol(data_in, symbol_valid, code_out);
    // Assert error signal if the symbol is not valid
    code_err = !symbol_valid;
  end

endmodule
