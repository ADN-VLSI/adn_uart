/*

### Purpose
This module implements a Manchester encoder that converts parallel input data into a serial Manchester-encoded bitstream. It maps each input bit to a two-bit code, where logic '0' and '1' are represented by specific transitions based on the configured polarity.

### Usage
To use this module, instantiate it in your design by specifying the `DATA_W` parameter to match your input data width. The `INVERT_POLARITY` parameter can be set to `1` to swap the transition logic if required by your physical layer protocol. The module performs combinatorial encoding, mapping each input bit to a 2-bit sequence at the output.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_manchester #(
    parameter integer DATA_W = 8,           // Width of the input data bus
    parameter integer INVERT_POLARITY = 0   // Toggle to invert Manchester transition logic
) (
    input logic [DATA_W-1:0] data_in,       // Parallel input data to be encoded
    output logic [(2*DATA_W)-1:0] code_out  // Serialized Manchester-encoded output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Define bit patterns for logic 0 and 1 based on polarity configuration
  localparam [1:0] ZERO_CODE = INVERT_POLARITY ? 2'b10 : 2'b01;
  localparam [1:0] ONE_CODE = INVERT_POLARITY ? 2'b01 : 2'b10;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Loop index for combinatorial bit processing
  integer bit_idx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinatorial block to map input bits to Manchester encoded pairs
  always_comb begin
    // Initialize output bus to zero
    code_out = {((2 * DATA_W)) {1'b0}};

    // Iterate through each input bit and assign corresponding Manchester code
    for (bit_idx = 0; bit_idx < DATA_W; bit_idx = bit_idx + 1) begin
      if (data_in[bit_idx]) begin
        code_out[(2*bit_idx)+1] = ONE_CODE[1];
        code_out[(2*bit_idx)]   = ONE_CODE[0];
      end else begin
        code_out[(2*bit_idx)+1] = ZERO_CODE[1];
        code_out[(2*bit_idx)]   = ZERO_CODE[0];
      end
    end
  end

endmodule
