/*

### Purpose
The `adn_endec_encoder_128b130b` module implements a 128b/130b encoder as specified in the IEEE 802.3 standard. It accepts a 128-bit payload and a 2-bit synchronization header, performs payload scrambling using a provided state, and outputs a 130-bit encoded block along with the updated scrambling state and a header validity check.

### Usage
To use this module, instantiate it in your design and provide the 128-bit data payload, the 2-bit synchronization header, and the current 23-bit scrambling state. The module will output the 130-bit encoded block (header + scrambled payload) and the updated scrambling state for the next cycle. The `header_err` output indicates if the provided synchronization header is invalid according to the standard.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_encoder_128b130b (
    input  logic [127:0] payload_in,         // Raw 128-bit data payload
    input  logic [  1:0] sync_header_in,     // 2-bit synchronization header
    input  logic [ 22:0] scramble_state_in,  // Current 23-bit scrambling state
    output logic [129:0] block_out,          // Encoded 130-bit output block
    output logic [ 22:0] scramble_state_out, // Updated 23-bit scrambling state
    output logic         header_err          // Error flag for invalid sync header
);

  // Include standard line coding functions for scrambling and validation
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Internal buffer to hold the result of the payload scrambling process
  logic [127:0] scrambled_payload;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational logic block to process the payload and generate the final output block
  always_comb begin
    // Perform scrambling on the input payload and update the scrambling state
    transform_128b130b_payload(payload_in, scramble_state_in, scrambled_payload,
                               scramble_state_out);
    
    // Concatenate the sync header with the scrambled payload to form the 130-bit block
    block_out  = {sync_header_in, scrambled_payload};
    
    // Validate the sync header against IEEE 802.3 standards
    header_err = !valid_sync_header(sync_header_in);
  end

endmodule
