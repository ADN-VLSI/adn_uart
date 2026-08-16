/*

# Purpose
This module implements a configurable UART receiver designed to deserialize incoming serial data streams. It supports variable data lengths (5 to 8 bits), optional parity checking (even/odd), and oversampling to ensure robust clock domain synchronization and bit-center sampling.

### Use Case
The `adn_uart_receiver` is designed for integration into SoC or FPGA designs requiring asynchronous serial communication. It is typically used to interface with external peripherals, sensors, or debug consoles that transmit data using the standard UART protocol. By providing configurable data widths and parity, it offers flexibility for various communication standards (e.g., RS-232, RS-485) while ensuring reliable data capture through oversampling and synchronization logic.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-06 | Ahasan Ullah Khalid | Initial version                                        |
| 1.0      | 2026-08-06 | Ahasan Ullah Khalid | Stable release                                         |

Author : Ahasan Ullah Khalid (aukhalid02@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/
module adn_uart_receiver #(
    parameter int OVERSAMPLE = 8  // Number of samples per bit period
) (
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // System clock input

    input logic [1:0] data_bits_i,   // Data length config (0:5b, 1:6b, 2:7b, 3:8b)
    input logic       parity_en_i,   // Parity check enable
    input logic       parity_type_i, // Parity type (0:even, 1:odd)

    input logic rx_i,  // Raw serial receive input

    output logic [7:0] data_o,       // Parallel received data output
    output logic       data_valid_o  // Pulse indicating valid data on data_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Midpoint for bit sampling. e.g., if OVERSAMPLE=8, HalfOversample=3 (4th clock tick)
  localparam int HalfOversample = (OVERSAMPLE / 2) - 1;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_START,
    STATE_DATA,
    STATE_PARITY,
    STATE_STOP
  } state_e;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS & REGISTERS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  state_e state_q, state_next;

  logic [$clog2(OVERSAMPLE)-1:0] sample_cnt_q, sample_cnt_next;
  logic [2:0] bit_cnt_q, bit_cnt_next;
  logic [7:0] data_q, data_next;
  logic parity_err_q, parity_err_next;
  logic [7:0] data_o_q, data_o_next;
  logic data_valid_q, data_valid_next;

  logic       rx_s;  // Synchronized RX signal

  // Parity variables
  logic [3:0] par_calc;
  logic       expected_parity;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COMBINATIONAL LOGIC
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // 1. Inline Parity Calculation (Optimized from reference code)
  always_comb begin
    par_calc[0] = ^data_q[4:0];
    par_calc[1] = par_calc[0] ^ data_q[5];
    par_calc[2] = par_calc[1] ^ data_q[6];
    par_calc[3] = par_calc[2] ^ data_q[7];

    case (data_bits_i)
      2'b00:   expected_parity = par_calc[0];  // 5 bits
      2'b01:   expected_parity = par_calc[1];  // 6 bits
      2'b10:   expected_parity = par_calc[2];  // 7 bits
      2'b11:   expected_parity = par_calc[3];  // 8 bits
      default: expected_parity = par_calc[3];
    endcase

    if (parity_type_i == 1'b1) begin  // Assuming 1 designates ODD parity
      expected_parity = ~expected_parity;
    end
  end

  // 2. FSM Next-State & Data Path Logic
  always_comb begin
    // Default assignments to prevent latches
    state_next      = state_q;
    sample_cnt_next = sample_cnt_q;
    bit_cnt_next    = bit_cnt_q;
    data_next       = data_q;
    parity_err_next = parity_err_q;
    data_o_next     = data_o_q;
    data_valid_next = 1'b0;  // Default to 0 so it naturally creates a single-cycle pulse

    // Default sample counter behavior (wraps at OVERSAMPLE-1)
    if (sample_cnt_q == OVERSAMPLE - 1) begin
      sample_cnt_next = '0;
    end else begin
      sample_cnt_next = sample_cnt_q + 1'b1;
    end

    case (state_q)
      STATE_IDLE: begin
        sample_cnt_next = '0;
        bit_cnt_next    = '0;
        parity_err_next = 1'b0;
        data_next       = '0;  // Clear the shift register for new zero-padded frame

        if (!rx_s) begin
          state_next = STATE_START;
        end
      end

      STATE_START: begin
        if (sample_cnt_q == HalfOversample) begin
          if (!rx_s) begin
            state_next      = STATE_DATA;
            sample_cnt_next = '0;  // Re-align sampling phase to the center of the bit
          end else begin
            state_next = STATE_IDLE;  // False start glitch recovery
          end
        end
      end

      STATE_DATA: begin
        // Sample data bit exactly at midpoint
        if (sample_cnt_q == HalfOversample) begin
          data_next[bit_cnt_q] = rx_s;  // Direct assignment, replaces shift logic
        end

        // End of the bit period
        if (sample_cnt_q == OVERSAMPLE - 1) begin
          if (bit_cnt_q == 3'd4 + {1'b0, data_bits_i}) begin
            if (parity_en_i) begin
              state_next = STATE_PARITY;
            end else begin
              state_next = STATE_STOP;
            end
          end else begin
            bit_cnt_next = bit_cnt_q + 1'b1;
          end
        end
      end

      STATE_PARITY: begin
        if (sample_cnt_q == HalfOversample) begin
          if (rx_s != expected_parity) begin
            parity_err_next = 1'b1;
          end
        end

        if (sample_cnt_q == OVERSAMPLE - 1) begin
          state_next = STATE_STOP;
        end
      end

      STATE_STOP: begin
        if (sample_cnt_q == HalfOversample) begin
          // Assert valid output if stop bit is valid (HIGH) and parity matches
          if (rx_s && !parity_err_q) begin
            data_o_next     = data_q;
            data_valid_next = 1'b1;
          end
        end

        if (sample_cnt_q == OVERSAMPLE - 1) begin
          state_next = STATE_IDLE;
        end
      end

      default: state_next = STATE_IDLE;
    endcase
  end

  // Output assignments
  always_comb data_o = data_o_q;
  always_comb data_valid_o = data_valid_q;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Synchronize asynchronous RX input to local clock domain
  adn_common_synchronizer #(
      .WIDTH(1),
      .STAGES(2),
      .RESET_VALUE(1'b1)
  ) u_rx_sync (
      .clk_i  (clk_i),
      .arst_ni(arst_ni),
      .en_i   (1'b1),
      .data_i (rx_i),
      .data_o (rx_s)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      state_q      <= STATE_IDLE;
      sample_cnt_q <= '0;
      bit_cnt_q    <= '0;
      data_q       <= '0;
      parity_err_q <= 1'b0;
      data_o_q     <= '0;
      data_valid_q <= 1'b0;
    end else begin
      state_q      <= state_next;
      sample_cnt_q <= sample_cnt_next;
      bit_cnt_q    <= bit_cnt_next;
      data_q       <= data_next;
      parity_err_q <= parity_err_next;
      data_o_q     <= data_o_next;
      data_valid_q <= data_valid_next;
    end
  end

endmodule
