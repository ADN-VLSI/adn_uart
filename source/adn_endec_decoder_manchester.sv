/*

This module implements a Manchester decoder that converts a 2*N-bit encoded input stream into an N-bit data output. It validates the Manchester encoding rules (01 for logic 0, 10 for logic 1, or vice versa depending on polarity) and flags any invalid symbol transitions as errors.

### Usage

To use this module, instantiate it in your design by specifying the `DATA_W` parameter to match your desired output width. The `INVERT_POLARITY` parameter can be set to `1` if the Manchester encoding scheme is inverted (e.g., 10 for logic 0).

```systemverilog
adn_endec_decoder_manchester #(
    .DATA_W(8),
    .INVERT_POLARITY(0)
) u_decoder (
    .code_in(encoded_data),
    .data_out(decoded_data),
    .code_err(error_flag)
);
```

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_manchester #(
    parameter integer DATA_W = 8,          // Width of the decoded output data
    parameter integer INVERT_POLARITY = 0  // Polarity selection: 0 for standard, 1 for inverted
) (
    input  logic [(2*DATA_W)-1:0] code_in,  // Manchester encoded input stream
    output logic [    DATA_W-1:0] data_out, // Decoded output data
    output logic                  code_err  // Error flag for invalid Manchester symbols
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Define expected bit patterns for logic 0 and 1 based on polarity configuration
  localparam [1:0] ZERO_CODE = INVERT_POLARITY ? 2'b10 : 2'b01;
  localparam [1:0] ONE_CODE = INVERT_POLARITY ? 2'b01 : 2'b10;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  reg [1:0] symbol_bits; // Temporary storage for the current 2-bit Manchester symbol
  integer bit_idx;       // Loop index for iterating through input bits

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to decode Manchester symbols and detect errors
  always_comb begin
    data_out = {DATA_W{1'b0}};
    code_err = 1'b0;

    // Iterate through each 2-bit symbol in the input stream
    for (bit_idx = 0; bit_idx < DATA_W; bit_idx = bit_idx + 1) begin
      symbol_bits[1] = code_in[(2*bit_idx)+1];
      symbol_bits[0] = code_in[(2*bit_idx)];

      // Check if symbol matches valid logic 0 or 1 patterns
      if (symbol_bits == ZERO_CODE) begin
        data_out[bit_idx] = 1'b0;
      end else if (symbol_bits == ONE_CODE) begin
        data_out[bit_idx] = 1'b1;
      end else begin
        // Flag error if symbol is invalid (e.g., 00 or 11)
        data_out[bit_idx] = 1'b0;
        code_err = 1'b1;
      end
    end
  end

endmodule
