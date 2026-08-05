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
    parameter int OVERSAMPLE = 8 // Number of samples per bit period
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
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int HALF_OVERSAMPLE = (OVERSAMPLE / 2) - 1; // Midpoint for bit sampling

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

  state_e current_state, next_state; // FSM state registers

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic                          rx_s;  // Synchronized RX signal

  logic [$clog2(OVERSAMPLE)-1:0] sample_cnt; // Counter for oversampling ticks
  logic [                   2:0] bit_cnt;    // Tracks number of bits received
  logic [                   2:0] target_bit_cnt; // Configured bit count target
  logic [                   3:0] active_bit_count; // Number of bits for parity calc

  logic [                   7:0] rx_shift_reg; // Shift register for incoming bits
  logic [                   7:0] aligned_data; // Data shifted to LSB alignment
  logic                          rx_parity_bit; // Captured parity bit
  logic                          expected_parity; // Parity calculated from received data
  logic                          parity_err; // Flag for parity mismatch

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Convert config input to target bit count (5 to 8 bits)
  always_comb target_bit_cnt = 3'd5 + {1'b0, data_bits_i};
  always_comb active_bit_count = 4'd5 + {2'b0, data_bits_i};

  // Align raw right-shifted LSB-first data into zero-padded LSB positions
  always_comb begin
    case (data_bits_i)
      2'b00:   aligned_data = {3'b0, rx_shift_reg[7:3]};  // 5 bits
      2'b01:   aligned_data = {2'b0, rx_shift_reg[7:2]};  // 6 bits
      2'b10:   aligned_data = {1'b0, rx_shift_reg[7:1]};  // 7 bits
      2'b11:   aligned_data = rx_shift_reg;  // 8 bits
      default: aligned_data = rx_shift_reg;
    endcase
  end

  always_comb parity_err = parity_en_i && (rx_parity_bit != expected_parity);

  // FSM Next State Logic
  always_comb begin
    next_state = current_state;

    case (current_state)
      STATE_IDLE: begin
        if (!rx_s) begin
          next_state = STATE_START;
        end
      end

      STATE_START: begin
        if (sample_cnt == HALF_OVERSAMPLE) begin
          if (!rx_s) begin
            next_state = STATE_DATA;
          end else begin
            next_state = STATE_IDLE;  // False start glitch recovery
          end
        end
      end

      STATE_DATA: begin
        if (sample_cnt == OVERSAMPLE - 1) begin
          if (bit_cnt == target_bit_cnt - 1) begin
            if (parity_en_i) begin
              next_state = STATE_PARITY;
            end else begin
              next_state = STATE_STOP;
            end
          end
        end
      end

      STATE_PARITY: begin
        if (sample_cnt == OVERSAMPLE - 1) begin
          next_state = STATE_STOP;
        end
      end

      STATE_STOP: begin
        if (sample_cnt == OVERSAMPLE - 1) begin
          next_state = STATE_IDLE;
        end
      end

      default: next_state = STATE_IDLE;
    endcase
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Synchronize asynchronous RX input to local clock domain
  adn_common_synchronizer #(
      .WIDTH(1),
      .STAGES(2),
      .RESET_VALUE(1'b1)  // UART line stays HIGH when idle
  ) u_rx_sync (
      .clk_i  (clk_i),
      .arst_ni(arst_ni),
      .en_i   (1'b1),
      .data_i (rx_i),
      .data_o (rx_s)
  );

  // Generate expected parity for validation
  adn_parity_generator #(
      .DATA_WIDTH(8)
  ) u_parity_gen (
      .data_i       (aligned_data),
      .valid_bits_i (active_bit_count),
      .parity_type_i(parity_type_i),
      .parity_o     (expected_parity)
  );


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // FSM State Register
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      current_state <= STATE_IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // Data path and control logic
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      sample_cnt    <= '0;
      bit_cnt       <= '0;
      rx_shift_reg  <= '0;
      rx_parity_bit <= 1'b0;
      data_o        <= '0;
      data_valid_o  <= 1'b0;
    end else begin
      data_valid_o <= 1'b0;  // Default pulse suppression

      case (current_state)
        STATE_IDLE: begin
          sample_cnt <= '0;
          bit_cnt    <= '0;
        end

        STATE_START: begin
          if (sample_cnt == HALF_OVERSAMPLE) begin
            sample_cnt <= '0;  // Re-align sampling phase to bit center
          end else begin
            sample_cnt <= sample_cnt + 1'b1;
          end
        end

        STATE_DATA: begin
          if (sample_cnt == OVERSAMPLE - 1) begin
            sample_cnt <= '0;
            bit_cnt    <= bit_cnt + 1'b1;
          end else begin
            sample_cnt <= sample_cnt + 1'b1;
          end

          // Sample data bit at midpoint
          if (sample_cnt == HALF_OVERSAMPLE) begin
            rx_shift_reg <= {rx_s, rx_shift_reg[7:1]};
          end
        end

        STATE_PARITY: begin
          if (sample_cnt == OVERSAMPLE - 1) begin
            sample_cnt <= '0;
          end else begin
            sample_cnt <= sample_cnt + 1'b1;
          end

          // Sample parity bit at midpoint
          if (sample_cnt == HALF_OVERSAMPLE) begin
            rx_parity_bit <= rx_s;
          end
        end

        STATE_STOP: begin
          if (sample_cnt == OVERSAMPLE - 1) begin
            sample_cnt <= '0;

            // Assert valid output if stop bit is valid (HIGH) and parity matches
            if (rx_s && !parity_err) begin
              data_o       <= aligned_data;
              data_valid_o <= 1'b1;
            end
          end else begin
            sample_cnt <= sample_cnt + 1'b1;
          end
        end
      endcase
    end
  end

endmodule
