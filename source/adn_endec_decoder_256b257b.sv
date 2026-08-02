/*

### Purpose
This module implements a 256b/257b decoder designed for high-speed serial data streams. It extracts the 256-bit payload from a 257-bit encoded block, performs descrambling based on the provided state, and validates the synchronization header bit to detect potential transmission errors.

### Usage
To use this module, connect the 257-bit encoded input stream to `block_in` and provide the current 23-bit scrambler state via `scramble_state_in`. The module will output the decoded 256-bit payload, the extracted sync bit, the updated scrambler state for the next cycle, and a `header_err` flag if the sync bit is invalid.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_256b257b (
    input  logic [256:0] block_in,           // 257-bit encoded input block (1-bit sync + 256-bit payload)
    input  logic [ 22:0] scramble_state_in,  // Current 23-bit scrambler state for descrambling
    output logic [255:0] payload_out,        // Decoded 256-bit data payload
    output logic         sync_bit_out,       // Extracted synchronization header bit
    output logic [ 22:0] scramble_state_out, // Updated 23-bit scrambler state for next cycle
    output logic         header_err          // Error flag indicating invalid sync header
);

  // Include external functional definitions for line coding and descrambling
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin
    // Extract the sync header bit from the MSB of the input block
    sync_bit_out = block_in[256];
    
    // Perform payload descrambling and transformation using the imported function
    transform_256b257b_payload(block_in[255:0], scramble_state_in, payload_out, scramble_state_out);
    
    // Validate the sync header bit and set error flag if invalid
    header_err = !valid_sync_bit(sync_bit_out);
  end

endmodule
