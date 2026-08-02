/*

This module implements a 64b/66b decoder designed to process encoded data blocks. It performs synchronization header extraction, payload descrambling using a provided state, and validation of the sync header to detect transmission errors.

### Usage

The `adn_endec_decoder_64b66b` module is used to decode 66-bit blocks into 64-bit data payloads.

1. **Input**: Provide the 66-bit encoded block to `block_in` and the current 58-bit scrambling state to `scramble_state_in`.
2. **Processing**: The module extracts the 2-bit sync header and descrambles the 64-bit payload using the provided state.
3. **Output**: The decoded 64-bit payload is available at `payload_out`, the sync header at `sync_header_out`, and the updated scrambling state at `scramble_state_out`.
4. **Error Detection**: The `header_err` signal asserts high if the sync header is invalid (i.e., not `2'b01` or `2'b10`).

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_64b66b (
    input  logic [65:0] block_in,           // 66-bit encoded input block
    input  logic [57:0] scramble_state_in,  // Current 58-bit scrambling state
    output logic [63:0] payload_out,        // Decoded 64-bit payload
    output logic [ 1:0] sync_header_out,    // Extracted 2-bit sync header
    output logic [57:0] scramble_state_out, // Updated 58-bit scrambling state
    output logic        header_err          // High if sync header is invalid
);

  // Include functional definitions for 64b/66b line coding operations
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational logic block for decoding and validation
  always_comb begin
    // Extract the 2-bit sync header from the MSB of the input block
    sync_header_out = block_in[65:64];
    
    // Perform descrambling on the 64-bit payload using the provided state
    descramble_64b66b_payload(block_in[63:0], scramble_state_in, payload_out, scramble_state_out);
    
    // Validate the sync header and assert error signal if invalid
    header_err = !valid_sync_header(sync_header_out);
  end

endmodule
