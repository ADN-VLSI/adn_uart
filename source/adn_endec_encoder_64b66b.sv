/*

### Purpose
This module implements a 64b/66b encoder used in high-speed serial communication protocols. It performs data scrambling on a 64-bit payload using a provided scramble state and appends a 2-bit synchronization header to produce a 66-bit encoded block, while also validating the sync header.

### Usage
To use this module, provide a 64-bit data payload, a 2-bit synchronization header, and the current 58-bit scramble state. The module will output the 66-bit encoded block, the updated scramble state for the next cycle, and a header error flag if the sync header is invalid.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_64b66b (
    input  logic [63:0] payload_in,         // Raw 64-bit data input
    input  logic [ 1:0] sync_header_in,     // 2-bit synchronization header (e.g., 01 for data, 10 for control)
    input  logic [57:0] scramble_state_in,  // Current 58-bit LFSR scramble state
    output logic [65:0] block_out,          // Final 66-bit encoded block (2-bit header + 64-bit scrambled data)
    output logic [57:0] scramble_state_out, // Next cycle 58-bit LFSR scramble state
    output logic        header_err          // Flag indicating an invalid sync header pattern
);

  // Include external functions for scrambling and header validation
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Intermediate storage for the payload after the LFSR scrambling process
  logic [63:0] scrambled_payload;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Functional block: Perform scrambling and construct the final 66-bit output block
  always_comb begin
    // Apply LFSR scrambling to the input payload
    scramble_64b66b_payload(payload_in, scramble_state_in, scrambled_payload, scramble_state_out);
    
    // Concatenate the sync header with the scrambled payload to form the 66-bit block
    block_out  = {sync_header_in, scrambled_payload};
    
    // Validate the sync header and set error flag if invalid
    header_err = !valid_sync_header(sync_header_in);
  end

endmodule
