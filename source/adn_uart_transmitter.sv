/*

@foez-bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez-bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-04 | Annim Jannat    | Initial version                                        |
| 1.0      | 2026-08-06 | Annim Jannat    | Stable release                                         |

Author : Annim Jannat (jannatannim@gmail.com)
This file is part of ADN-VLSI/adn_endec
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

// @foez-bhai, add comments to the parameters, ports
module adn_uart_transmitter #(
) (
    // PORTS
    input  logic arst_ni,              // asynchronous reset, active low
    input  logic clk_i,                // clock input

    output logic       data_ready_o,   // data ready output
    input  logic       data_valid_i,   // data valid input
    input  logic [7:0] data_i,         // data to be transmitted

    input  logic [1:0] data_bits_i,    // number of data bits (0:5b, 1:6b, 2:7b, 3:8b)
    input  logic       parity_en_i,    // parity enable
    input  logic       parity_type_i,  // parity type (0:even, 1:odd)
    input  logic       extra_stop_i,   // extra stop bit enable

    output logic tx_o  // transmitted serial data output
);

  // @foez-bhai, add comments to the functional blocks, signals, and submodules


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_START,
    STATE_DATA,
    STATE_PARITY,
    STATE_STOP1,
    STATE_STOP2
  } state_e;

  state_e current_state, next_state;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [7:0] shift_reg_q;

  logic [3:0] bit_cnt_q;
  logic [3:0] nbits_d;

  logic parity_en_q;
  logic extra_stop_q;

  logic parity_bit_w;  // combinational parity output, valid whenever data_i/data_bits_i are
  logic parity_bit_q;  // snapshot of parity_bit_w taken at latch time, held for the whole frame

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin
    case (data_bits_i)
      2'd0:    nbits_d = 4'd5;
      2'd1:    nbits_d = 4'd6;
      2'd2:    nbits_d = 4'd7;
      default: nbits_d = 4'd8;
    endcase
  end

  assign data_ready_o = (current_state == STATE_IDLE);

  always_comb begin
    next_state = current_state;
    case (current_state)
      STATE_IDLE: begin
        if (data_valid_i) next_state = STATE_START;
      end

      STATE_START: begin
        next_state = STATE_DATA;
      end

      STATE_DATA: begin

        if (bit_cnt_q == 4'd1) begin
          next_state = parity_en_q ? STATE_PARITY : STATE_STOP1;
        end
      end

      STATE_PARITY: begin
        next_state = STATE_STOP1;
      end

      STATE_STOP1: begin
        next_state = extra_stop_q ? STATE_STOP2 : STATE_IDLE;
      end

      STATE_STOP2: begin
        next_state = STATE_IDLE;
      end

      default: next_state = STATE_IDLE;
    endcase
  end

  always_comb begin
    case (current_state)
      STATE_IDLE:   tx_o = 1'b1;
      STATE_START:  tx_o = 1'b0;
      STATE_DATA:   tx_o = shift_reg_q[0];
      STATE_PARITY: tx_o = parity_bit_q;
      STATE_STOP1:  tx_o = 1'b1;
      STATE_STOP2:  tx_o = 1'b1;
      default:      tx_o = 1'b1;
    endcase
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////

   adn_common_parity_generator #(
      .DATA_WIDTH(8)
  ) u_parity_gen (
      .data_i              (data_i),
      .parity_valid_bits_i (nbits_d),
      .parity_type_i       (parity_type_i),
      .parity_o            (parity_bit_w)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // FSM
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      current_state <= STATE_IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      shift_reg_q  <= '0;
      bit_cnt_q    <= '0;
      parity_en_q  <= 1'b0;
      extra_stop_q <= 1'b0;
      parity_bit_q <= 1'b0;
    end

    else begin
      case (current_state)
        STATE_IDLE: begin

          if (data_valid_i) begin
            shift_reg_q  <= data_i;
            bit_cnt_q    <= nbits_d;
            parity_en_q  <= parity_en_i;
            extra_stop_q <= extra_stop_i;
            parity_bit_q <= parity_bit_w;  // freeze this frame's parity bit
          end
        end

        STATE_DATA: begin
          // Shift the LSB out each cycle, count down toward zero
          shift_reg_q <= {1'b0, shift_reg_q[7:1]};
          bit_cnt_q   <= bit_cnt_q - 4'd1;
        end

        default: ;  // hold the value
      endcase
    end
  end

endmodule

