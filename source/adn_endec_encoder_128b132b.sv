/*

### Purpose
The `adn_endec_encoder_128b132b` module implements a 128b/132b line coding encoder. It takes a 128-bit payload and a 4-bit synchronization header, applies scrambling based on a provided state, and outputs a 132-bit encoded block suitable for high-speed serial transmission.

### Usage
To use this module, instantiate it in your top-level design. Provide the 128-bit data payload, the 4-bit synchronization header (e.g., 2'b01 for data or 2'b10 for control), and the current 23-bit scrambling state. The module will output the 132-bit encoded block and the updated scrambling state for the next cycle. The `header_err` signal will assert if an invalid synchronization header is detected.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_128b132b (
    input  logic [127:0] payload_in,         // Raw 128-bit data payload
    input  logic [  3:0] sync_header_in,     // 4-bit synchronization header
    input  logic [ 22:0] scramble_state_in,  // Current 23-bit LFSR scrambling state
    output logic [131:0] block_out,          // Final 132-bit encoded output block
    output logic [ 22:0] scramble_state_out, // Updated 23-bit LFSR scrambling state
    output logic         header_err          // Error flag for invalid sync header
);

  // Include external line coding functions for payload transformation and header validation
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Intermediate storage for the payload after the scrambling process
  logic [127:0] scrambled_payload;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to perform scrambling and construct the final output block
  always_comb begin
    // Apply scrambling transformation to the input payload
    transform_128b132b_payload(payload_in, scramble_state_in, scrambled_payload,
                               scramble_state_out);
    
    // Concatenate the sync header and scrambled payload to form the 132-bit block
    block_out  = {sync_header_in, scrambled_payload};
    
    // Validate the sync header and assert error flag if invalid
    header_err = !valid_sync_header4(sync_header_in);
  end

endmodule
