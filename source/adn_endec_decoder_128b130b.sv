/*

This module implements a 128b/130b decoder, which is responsible for reversing the 128b/130b encoding process. It extracts the 2-bit synchronization header and the 128-bit payload from the input 130-bit block, performs descrambling based on the provided state, and validates the synchronization header.

### Usage
The `adn_endec_decoder_128b130b` module is used in high-speed serial links to recover 128-bit data from 130-bit encoded blocks. 
1. Connect the 130-bit received block to `block_in`.
2. Provide the current 23-bit scrambler state to `scramble_state_in`.
3. The module outputs the decoded 128-bit payload, the 2-bit sync header, and the updated scrambler state.
4. Monitor `header_err` to detect invalid synchronization headers, which indicates a potential framing error or link instability.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_endec_decoder_128b130b (
    input  logic [129:0] block_in,           // Raw 130-bit input block (2-bit header + 128-bit payload)
    input  logic [ 22:0] scramble_state_in,  // Current 23-bit scrambler state for descrambling
    output logic [127:0] payload_out,        // Decoded 128-bit data payload
    output logic [  1:0] sync_header_out,    // Extracted 2-bit synchronization header
    output logic [ 22:0] scramble_state_out, // Updated 23-bit scrambler state for next cycle
    output logic         header_err          // High when sync header is invalid (00 or 11)
);

  // Include external functions for line coding logic
  `include "adn_endec_block_linecode_functions.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin
    // Extract the 2-bit sync header from the MSB of the input block
    sync_header_out = block_in[129:128];
    
    // Perform descrambling and payload transformation using the imported function
    transform_128b130b_payload(block_in[127:0], scramble_state_in, payload_out, scramble_state_out);
    
    // Validate the sync header; set error flag if header is not 01 or 10
    header_err = !valid_sync_header(sync_header_out);
  end

endmodule
