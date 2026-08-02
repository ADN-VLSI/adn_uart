/*

# Purpose
This module implements a 256b/257b encoder, which takes a 256-bit payload and a 1-bit synchronization header to produce a 257-bit encoded block. It incorporates payload scrambling based on an input state and validates the synchronization bit.

## Usage
To use this module, connect the 256-bit data payload to `payload_in` and the synchronization header to `sync_bit_in`. Provide the current 23-bit scrambling state via `scramble_state_in`. The module will output the encoded 257-bit block on `block_out` and the updated scrambling state on `scramble_state_out`. The `header_err` signal will assert high if the provided synchronization bit is invalid.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_256b257b (
    input  logic [255:0] payload_in,         // Raw 256-bit input data payload
    input  logic         sync_bit_in,        // Synchronization header bit
    input  logic [ 22:0] scramble_state_in,  // Initial 23-bit scrambling state
    output logic [256:0] block_out,          // Encoded 257-bit output block
    output logic [ 22:0] scramble_state_out, // Updated 23-bit scrambling state
    output logic         header_err          // Error flag for invalid sync bit
);

  // Include external functions for line coding and scrambling logic
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Intermediate register to hold the payload after the scrambling process
  logic [255:0] scrambled_payload;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational block to process payload scrambling, construct the output block, and validate sync
  always_comb begin
    // Apply scrambling transformation to the input payload
    transform_256b257b_payload(payload_in, scramble_state_in, scrambled_payload,
                               scramble_state_out);
    
    // Concatenate the sync bit with the scrambled payload to form the 257-bit output
    block_out  = {sync_bit_in, scrambled_payload};
    
    // Validate the sync bit and assert error signal if invalid
    header_err = !valid_sync_bit(sync_bit_in);
  end

endmodule
