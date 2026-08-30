/*

The `adn_uart_register_interface` module serves as the primary bridge between a system-level bus interface (such as APB) and the internal UART hardware components. It maps control, configuration, status, and data registers to specific memory addresses, enabling software to manage UART operations, monitor FIFO status, handle arbitration requests, and configure communication parameters like clock division and parity.

### Use Case
The `adn_uart_register_interface` acts as the memory-mapped control layer for the UART peripheral. Its primary use cases include:
- **Configuration:** Allowing software to set baud rates (via clock division/prescalers) and frame formats (data bits, parity, stop bits).
- **Control:** Providing a mechanism to trigger software resets, flush FIFOs, and enable/disable the transmitter and receiver.
- **Data Transfer:** Facilitating the movement of data between the system bus and the TX/RX FIFOs.
- **Status Monitoring:** Exposing real-time FIFO occupancy and status flags to the CPU.
- **Arbitration:** Managing request/grant handshakes for multi-master or multi-client UART access scenarios.

| REVISION | DATE       | AUTHOR              | DESCRIPTION                                            |
|----------|------------|---------------------|--------------------------------------------------------|
| 0.1      | 2026-08-16 | Ahasan Ullah Khalid | Initial version                                        |
| 1.0      | 2026-08-16 | Ahasan Ullah Khalid | Stable release                                         |

Author : Ahasan Ullah Khalid (aukhalid02@gmail.com)
This file is part of ADN-VLSI/adn_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

`include "adn_uart_pkg.sv"
`include "typedef.svh"

module adn_uart_register_interface
  import adn_uart_pkg::*;
#(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic clk_i,
    input logic arst_ni,

    // Pipelined Memory Interface (PMI)
    input  pmi_req_t pmi_req_i,
    output pmi_rsp_t pmi_rsp_o,

    // Hardware Struct Outputs
    output uart_ctrl_reg_t uart_ctrl_o,
    output uart_cfg_reg_t  uart_cfg_o,
    output uart_stat_reg_t uart_stat_o,
    output uart_int_reg_t  uart_int_en_o,

    // TX Datapath (Valid/Ready)
    output uart_data_t tx_data_o,
    output logic       tx_data_valid_o,
    input  logic       tx_data_ready_i,

    // RX Datapath (Valid/Ready)
    input  uart_data_t rx_data_i,
    input  logic       rx_data_valid_i,
    output logic       rx_data_ready_o,

    // TX Arbitration Request (Valid/Ready Enqueue)
    output uart_id_t tx_req_id_o,
    output logic     tx_req_valid_o,
    input  logic     tx_req_ready_i,

    // TX Arbitration Grant (Valid/Ready Dequeue)
    input  uart_id_t tx_grant_id_i,
    input  logic     tx_grant_valid_i,
    output logic     tx_grant_ready_o,

    // RX Arbitration Request (Valid/Ready Enqueue)
    output uart_id_t rx_req_id_o,
    output logic     rx_req_valid_o,
    input  logic     rx_req_ready_i,

    // RX Arbitration Grant (Valid/Ready Dequeue)
    input  uart_id_t rx_grant_id_i,
    input  logic     rx_grant_valid_i,
    output logic     rx_grant_ready_o,

    // Status & Idle Monitoring
    input uart_count_t tx_data_cnt_i,
    input uart_count_t rx_data_cnt_i,
    input logic        tx_uart_idle_i
);

  //////////////////////////////////////////////////////////////////////////////
  // INTERNAL SIGNALS
  //////////////////////////////////////////////////////////////////////////////
  logic                  write_error;
  logic                  read_error;

  logic [DATA_WIDTH-1:0] reg_rdata;
  logic                  reg_wen;
  logic                  reg_ren;
  logic [          11:0] reg_addr;

  // PMI Aliasing & No-op logic (PR-15 compliance for mstrb==0)
  assign reg_wen  = pmi_req_i.mreq && pmi_req_i.mwe && (|pmi_req_i.mstrb);
  assign reg_ren  = pmi_req_i.mreq && !pmi_req_i.mwe;
  assign reg_addr = pmi_req_i.maddr[11:0];

  // PMI Response - 0-wait state logic
  always_comb begin
    pmi_rsp_o.mgnt   = 1'b1;  // Always ready for a request
    pmi_rsp_o.mack   = pmi_req_i.mreq;  // Complete immediately on request acceptance
    pmi_rsp_o.mrdata = reg_rdata;
    // Route internal logical errors to PMI response code
    pmi_rsp_o.mresp  = pmi_req_i.mreq ? (pmi_req_i.mwe ? write_error : read_error) : 1'b0;
  end

  // Directly assign data payloads to Datapath FIFOs
  always_comb tx_data_o.data = pmi_req_i.mwdata[7:0];
  always_comb tx_req_id_o.id = pmi_req_i.mwdata[7:0];
  always_comb rx_req_id_o.id = pmi_req_i.mwdata[7:0];

  //////////////////////////////////////////////////////////////////////////////
  // WRITE LOGIC — Address Decoding & Error Checking
  //////////////////////////////////////////////////////////////////////////////
  always_comb begin
    write_error     = 1'b1;  // Default to error
    tx_data_valid_o = 1'b0;
    tx_req_valid_o  = 1'b0;
    rx_req_valid_o  = 1'b0;

    if (reg_wen) begin
      case (reg_addr)
        UART_CTRL_OFFSET: write_error = 1'b0;

        UART_CFG_OFFSET: begin
          // Only allow configuration changes when FIFOs are empty
          if (tx_data_cnt_i.count == '0 && rx_data_cnt_i.count == '0) write_error = 1'b0;
        end

        UART_TXR_OFFSET: begin
          if (tx_req_ready_i) begin
            write_error = 1'b0;
            tx_req_valid_o = 1'b1;
          end
        end

        UART_TXD_OFFSET: begin
          if (tx_data_ready_i) begin
            write_error = 1'b0;
            tx_data_valid_o = 1'b1;
          end
        end

        UART_RXR_OFFSET: begin
          if (rx_req_ready_i) begin
            write_error = 1'b0;
            rx_req_valid_o = 1'b1;
          end
        end

        UART_INT_EN_OFFSET: write_error = 1'b0;

        default: ;
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // READ LOGIC — Muxing & Consuming Pop Handshakes
  //////////////////////////////////////////////////////////////////////////////
  always_comb begin
    read_error       = 1'b1;  // Default to error
    reg_rdata        = '0;
    rx_data_ready_o  = 1'b0;
    tx_grant_ready_o = 1'b0;
    rx_grant_ready_o = 1'b0;

    if (reg_ren) begin
      case (reg_addr)
        UART_CTRL_OFFSET: begin
          read_error = 1'b0;
          reg_rdata  = {{(DATA_WIDTH - $bits(uart_ctrl_reg_t)) {1'b0}}, uart_ctrl_o};
        end

        UART_CFG_OFFSET: begin
          read_error = 1'b0;
          reg_rdata  = {{(DATA_WIDTH - $bits(uart_cfg_reg_t)) {1'b0}}, uart_cfg_o};
        end

        UART_STAT_OFFSET: begin
          read_error = 1'b0;
          reg_rdata  = {{(DATA_WIDTH - $bits(uart_stat_reg_t)) {1'b0}}, uart_stat_o};
        end

        UART_TXR_OFFSET, UART_TXD_OFFSET, UART_RXR_OFFSET: begin
          read_error = 1'b0;  // Read-As-Zero (RAZ)
        end

        UART_TXGP_OFFSET: begin
          read_error = 1'b0;
          if (tx_grant_valid_i)
            reg_rdata = {{(DATA_WIDTH - $bits(uart_id_t)) {1'b0}}, tx_grant_id_i};
        end

        UART_TXG_OFFSET: begin
          read_error = 1'b0;
          if (tx_grant_valid_i) begin
            reg_rdata = {{(DATA_WIDTH - $bits(uart_id_t)) {1'b0}}, tx_grant_id_i};
            tx_grant_ready_o = 1'b1;  // Consuming read pops the arbiter grant
          end
        end

        UART_RXGP_OFFSET: begin
          read_error = 1'b0;
          if (rx_grant_valid_i)
            reg_rdata = {{(DATA_WIDTH - $bits(uart_id_t)) {1'b0}}, rx_grant_id_i};
        end

        UART_RXG_OFFSET: begin
          read_error = 1'b0;
          if (rx_grant_valid_i) begin
            reg_rdata = {{(DATA_WIDTH - $bits(uart_id_t)) {1'b0}}, rx_grant_id_i};
            rx_grant_ready_o = 1'b1;  // Consuming read pops the arbiter grant
          end
        end

        UART_RXD_OFFSET: begin
          read_error = 1'b0;
          if (rx_data_valid_i) begin
            reg_rdata = {{(DATA_WIDTH - $bits(uart_data_t)) {1'b0}}, rx_data_i};
            rx_data_ready_o = 1'b1;  // Consuming read pops the RX FIFO
          end
        end

        UART_INT_EN_OFFSET: begin
          read_error = 1'b0;
          reg_rdata  = {{(DATA_WIDTH - $bits(uart_int_reg_t)) {1'b0}}, uart_int_en_o};
        end

        default: ;
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS — Configuration State
  //////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      uart_ctrl_o   <= '0;
      uart_cfg_o    <= 32'h0003_405B; // Derived from original defaults
      uart_int_en_o <= '0;
    end else begin
      // Auto-clear software resets and flushes internally
      if (uart_ctrl_o.uart_rst) uart_ctrl_o.uart_rst <= 1'b0;
      if (uart_ctrl_o.tx_fifo_flush) uart_ctrl_o.tx_fifo_flush <= 1'b0;
      if (uart_ctrl_o.rx_fifo_flush) uart_ctrl_o.rx_fifo_flush <= 1'b0;

      // Update structs on valid writes
      if (reg_wen && !write_error) begin
        case (reg_addr)
          UART_CTRL_OFFSET:   uart_ctrl_o   <= pmi_req_i.mwdata;
          UART_CFG_OFFSET:    uart_cfg_o    <= pmi_req_i.mwdata;
          UART_INT_EN_OFFSET: uart_int_en_o <= pmi_req_i.mwdata;
          default: ;
        endcase
      end
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // UART_STAT — Combinational construction
  //////////////////////////////////////////////////////////////////////////////
  always_comb begin
    uart_stat_o.reserved = '0;
    uart_stat_o.tx_cnt   = tx_data_cnt_i.count;
    uart_stat_o.tx_empty = (tx_data_cnt_i.count == '0) & tx_uart_idle_i;
    uart_stat_o.tx_full  = (tx_data_cnt_i.count == adn_uart_pkg::UART_FIFO_DEPTH);
    uart_stat_o.rx_cnt   = rx_data_cnt_i.count;
    uart_stat_o.rx_empty = (rx_data_cnt_i.count == '0);
    uart_stat_o.rx_full  = (rx_data_cnt_i.count == adn_uart_pkg::UART_FIFO_DEPTH);
  end

endmodule
