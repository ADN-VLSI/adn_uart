/*

### Purpose
The `adn_endec_decoder_128b132b` module is designed to perform 128b/132b decoding for high-speed serial data streams. It extracts the 4-bit synchronization header and descrambles the 128-bit payload using a provided scramble state, while also validating the sync header to detect potential transmission errors.

### Usage
To use this module, connect the 132-bit raw data stream to `block_in` and provide the current 23-bit `scramble_state_in` used for the descrambling process. The module will output the decoded 128-bit payload via `payload_out` and the extracted 4-bit sync header via `sync_header_out`. The `scramble_state_out` provides the updated state for the next cycle, and `header_err` indicates if the sync header is invalid.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_128b132b (
    input  logic [131:0] block_in,           // Raw 132-bit input block
    input  logic [ 22:0] scramble_state_in,  // Input 23-bit scrambler state
    output logic [127:0] payload_out,        // Decoded 128-bit payload
    output logic [  3:0] sync_header_out,    // Extracted 4-bit sync header
    output logic [ 22:0] scramble_state_out, // Updated 23-bit scrambler state
    output logic         header_err          // Sync header validation error flag
);

  // Include library for line coding transformation functions
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin
    // Extract the 4-bit sync header from the MSB of the input block
    sync_header_out = block_in[131:128];
    
    // Perform descrambling and payload extraction using the imported function
    transform_128b132b_payload(block_in[127:0], scramble_state_in, payload_out, scramble_state_out);
    
    // Validate the sync header and set error flag if invalid
    header_err = !valid_sync_header4(sync_header_out);
  end

endmodule
