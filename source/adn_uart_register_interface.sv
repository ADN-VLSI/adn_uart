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

module adn_uart_register_interface #(
    parameter int ADDR_WIDTH = 32, // Width of the register address bus
    parameter int DATA_WIDTH = 32, // Width of the register data bus

    // Default UART Configuration Reset Values
    parameter logic [11:0] RST_CLK_DIV   = 12'h05B, // Reset value for clock divider
    parameter logic [ 3:0] RST_PRESCALER = 4'h4,    // Reset value for prescaler
    parameter logic [ 1:0] RST_DATA_BITS = 2'h3,    // Reset value for data bits configuration
    parameter logic        RST_PARITY_EN = 1'b0,    // Reset value for parity enable
    parameter logic        RST_PARITY_TY = 1'b0,    // Reset value for parity type
    parameter logic        RST_STOP_BITS = 1'b0     // Reset value for stop bits configuration
) (
    // Global Signals
    input logic clk,   // System clock
    input logic rst_n, // Active-low asynchronous reset

    // =====================================================================
    // Internal Bus Interface (Translated from APB)
    // =====================================================================
    input  logic [ADDR_WIDTH-1:0] reg_addr,     // Register address input
    input  logic [DATA_WIDTH-1:0] reg_wdata,    // Write data input
    input  logic                  reg_write_en, // Write enable signal
    input  logic                  reg_read_en,  // Read enable signal
    output logic [DATA_WIDTH-1:0] reg_rdata,    // Read data output
    output logic                  reg_ready,    // Bus ready signal
    output logic                  reg_error,    // Bus error signal

    // =====================================================================
    // Hardware Control Outputs (UART_CTRL & UART_CFG)
    // =====================================================================
    output logic uart_sw_rst,   // Software reset trigger
    output logic tx_fifo_flush, // Flush TX FIFO
    output logic rx_fifo_flush, // Flush RX FIFO
    output logic tx_en,         // Transmitter enable
    output logic rx_en,         // Receiver enable

    output logic [11:0] clk_div,     // Clock divider value
    output logic [ 3:0] prescaler,   // Prescaler value
    output logic [ 1:0] data_bits,   // Data bits configuration
    output logic        parity_en,   // Parity enable
    output logic        parity_type, // Parity type selection
    output logic        stop_bits,   // Stop bits configuration

    // =====================================================================
    // Status Inputs (UART_STAT)
    // =====================================================================
    input logic [9:0] tx_data_cnt,   // TX FIFO data count
    input logic [9:0] rx_data_cnt,   // RX FIFO data count
    input logic       tx_fifo_empty, // TX FIFO empty status
    input logic       tx_fifo_full,  // TX FIFO full status
    input logic       rx_fifo_empty, // RX FIFO empty status
    input logic       rx_fifo_full,  // RX FIFO full status

    // =====================================================================
    // TX Datapath (UART_TXD)
    // =====================================================================
    output logic [7:0] tx_fifo_wdata, // Data to write to TX FIFO
    output logic       tx_fifo_push,  // Push data to TX FIFO

    // =====================================================================
    // RX Datapath (UART_RXD)
    // =====================================================================
    input  logic [7:0] rx_fifo_rdata, // Data read from RX FIFO
    output logic       rx_fifo_pop,   // Pop data from RX FIFO

    // =====================================================================
    // TX Arbitration (UART_TXR, UART_TXGP, UART_TXG)
    // =====================================================================
    output logic [7:0] tx_access_req_id, // TX request ID
    output logic       tx_req_valid,     // TX request valid
    input  logic [7:0] tx_grant_id,      // TX grant ID
    input  logic       tx_grant_valid,   // TX grant valid
    output logic       tx_grant_pop,     // Pop TX grant

    // =====================================================================
    // RX Arbitration (UART_RXR, UART_RXGP, UART_RXG)
    // =====================================================================
    output logic [7:0] rx_access_req_id, // RX request ID
    output logic       rx_req_valid,     // RX request valid
    input  logic [7:0] rx_grant_id,      // RX grant ID
    input  logic       rx_grant_valid,   // RX grant valid
    output logic       rx_grant_pop,     // Pop RX grant

    // =====================================================================
    // Interrupts (UART_INT)
    // =====================================================================
    output logic tx_fifo_empty_int_en, // TX empty interrupt enable
    output logic tx_fifo_full_int_en,  // TX full interrupt enable
    output logic rx_fifo_empty_int_en, // RX empty interrupt enable
    output logic rx_fifo_full_int_en  // RX full interrupt enable
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Register Address Offsets
  // Assuming 12-bit address decoding for local offsets
  localparam logic [11:0] AddrUartCtrl = 12'h000;
  localparam logic [11:0] AddrUartCfg = 12'h004;
  localparam logic [11:0] AddrUartStat = 12'h008;
  localparam logic [11:0] AddrUartTxr = 12'h010;
  localparam logic [11:0] AddrUartTxgp = 12'h014;
  localparam logic [11:0] AddrUartTxg = 12'h018;
  localparam logic [11:0] AddrUartTxd = 12'h01C;
  localparam logic [11:0] AddrUartRxr = 12'h020;
  localparam logic [11:0] AddrUartRxgp = 12'h024;
  localparam logic [11:0] AddrUartRxg = 12'h028;
  localparam logic [11:0] AddrUartRxd = 12'h02C;
  localparam logic [11:0] AddrUartInt = 12'h030;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Fixed APB responses for RAZ/WI (Read-As-Zero / Write-Ignored) architecture
  always_comb reg_ready = 1'b1;
  always_comb reg_error = 1'b0;

  // TX Request Enqueue: Triggered when writing to UART_TXR and MSB (valid bit) is 1
  always_comb tx_req_valid = reg_write_en && (reg_addr[11:0] == AddrUartTxr) && reg_wdata[31];
  always_comb tx_access_req_id = reg_wdata[7:0];

  // RX Request Enqueue: Triggered when writing to UART_RXR and MSB (valid bit) is 1
  always_comb rx_req_valid = reg_write_en && (reg_addr[11:0] == AddrUartRxr) && reg_wdata[31];
  always_comb rx_access_req_id = reg_wdata[7:0];

  // TX Data Push: Safely push data into TX FIFO only if it is not currently full
  always_comb tx_fifo_push = reg_write_en && (reg_addr[11:0] == AddrUartTxd) && !tx_fifo_full;
  always_comb tx_fifo_wdata = reg_wdata[7:0];

  // Consuming Reads for Arbiters: Automatically advance queue when read
  always_comb tx_grant_pop = reg_read_en && (reg_addr[11:0] == AddrUartTxg);
  always_comb rx_grant_pop = reg_read_en && (reg_addr[11:0] == AddrUartRxg);

  // Consuming Read for RX Data: Pops byte from RX FIFO on a read, provided it's not empty
  always_comb rx_fifo_pop = reg_read_en && (reg_addr[11:0] == AddrUartRxd) && !rx_fifo_empty;

  // Read Logic Decoder (Multiplexer for register reads)
  always_comb begin
    reg_rdata = '0;  // Default RAZ (Read-As-Zero) for reserved/unmapped addresses

    if (reg_read_en) begin
      case (reg_addr[11:0])
        AddrUartCtrl: begin
          reg_rdata[0] = uart_sw_rst;
          reg_rdata[1] = tx_fifo_flush;
          reg_rdata[2] = rx_fifo_flush;
          reg_rdata[3] = tx_en;
          reg_rdata[4] = rx_en;
        end

        AddrUartCfg: begin
          reg_rdata[11:0]  = clk_div;
          reg_rdata[15:12] = prescaler;
          reg_rdata[17:16] = data_bits;
          reg_rdata[18]    = parity_en;
          reg_rdata[19]    = parity_type;
          reg_rdata[20]    = stop_bits;
        end

        AddrUartStat: begin
          reg_rdata[9:0]   = tx_data_cnt;
          reg_rdata[19:10] = rx_data_cnt;
          reg_rdata[20]    = tx_fifo_empty;
          reg_rdata[21]    = tx_fifo_full;
          reg_rdata[22]    = rx_fifo_empty;
          reg_rdata[23]    = rx_fifo_full;
        end

        AddrUartTxgp, AddrUartTxg: begin
          // UART_TXGP (Peek) and UART_TXG (Consume) share the same read data layout
          reg_rdata[7:0] = tx_grant_id;
          reg_rdata[31]  = tx_grant_valid;
        end

        AddrUartRxgp, AddrUartRxg: begin
          // UART_RXGP (Peek) and UART_RXG (Consume) share the same read data layout
          reg_rdata[7:0] = rx_grant_id;
          reg_rdata[31]  = rx_grant_valid;
        end

        AddrUartRxd: begin
          // Note: Hardware safety prevents pop if rx_fifo_empty==1. Raw bus data is outputted.
          reg_rdata[7:0] = rx_fifo_rdata;
        end

        AddrUartInt: begin
          reg_rdata[0] = tx_fifo_empty_int_en;
          reg_rdata[1] = tx_fifo_full_int_en;
          reg_rdata[2] = rx_fifo_empty_int_en;
          reg_rdata[3] = rx_fifo_full_int_en;
        end

        default: begin
          reg_rdata = '0;  // Unmapped offsets explicit fallback
        end
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Write Logic & Register State
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset values for UART_CTRL
      uart_sw_rst          <= 1'b0;
      tx_fifo_flush        <= 1'b0;
      rx_fifo_flush        <= 1'b0;
      tx_en                <= 1'b0;
      rx_en                <= 1'b0;

      // Reset values for UART_CFG (using parameterized defaults)
      clk_div              <= RST_CLK_DIV;
      prescaler            <= RST_PRESCALER;
      data_bits            <= RST_DATA_BITS;
      parity_en            <= RST_PARITY_EN;
      parity_type          <= RST_PARITY_TY;
      stop_bits            <= RST_STOP_BITS;

      // Reset values for UART_INT
      tx_fifo_empty_int_en <= 1'b0;
      tx_fifo_full_int_en  <= 1'b0;
      rx_fifo_empty_int_en <= 1'b0;
      rx_fifo_full_int_en  <= 1'b0;
    end else begin
      // Auto-clearing mechanism for FIFO flushes:
      if (tx_fifo_flush) tx_fifo_flush <= 1'b0;
      if (rx_fifo_flush) rx_fifo_flush <= 1'b0;

      // Write decoder block
      if (reg_write_en) begin
        case (reg_addr[11:0])
          AddrUartCtrl: begin
            uart_sw_rst   <= reg_wdata[0];
            tx_fifo_flush <= reg_wdata[1];
            rx_fifo_flush <= reg_wdata[2];
            tx_en         <= reg_wdata[3];
            rx_en         <= reg_wdata[4];
          end

          AddrUartCfg: begin
            clk_div     <= reg_wdata[11:0];
            prescaler   <= reg_wdata[15:12];
            data_bits   <= reg_wdata[17:16];
            parity_en   <= reg_wdata[18];
            parity_type <= reg_wdata[19];
            stop_bits   <= reg_wdata[20];
          end

          AddrUartInt: begin
            tx_fifo_empty_int_en <= reg_wdata[0];
            tx_fifo_full_int_en  <= reg_wdata[1];
            rx_fifo_empty_int_en <= reg_wdata[2];
            rx_fifo_full_int_en  <= reg_wdata[3];
          end

          default: ;  // Write Ignored (WI) for Read-Only or Reserved registers
        endcase
      end
    end
  end

endmodule
