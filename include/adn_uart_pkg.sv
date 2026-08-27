`ifndef ADN_UART_PKG_SV
`define ADN_UART_PKG_SV

package adn_uart_pkg;

  parameter int UART_FIFO_DEPTH = 16;
  parameter int UART_FIFO_COUNT_W = $clog2(UART_FIFO_DEPTH) + 1;

  // Register offsets
  parameter logic [11:0] UART_CTRL_OFFSET = 12'h000;
  parameter logic [11:0] UART_CFG_OFFSET = 12'h004;
  parameter logic [11:0] UART_STAT_OFFSET = 12'h008;
  parameter logic [11:0] UART_TXR_OFFSET = 12'h010;
  parameter logic [11:0] UART_TXGP_OFFSET = 12'h014;
  parameter logic [11:0] UART_TXG_OFFSET = 12'h018;
  parameter logic [11:0] UART_TXD_OFFSET = 12'h01C;
  parameter logic [11:0] UART_RXR_OFFSET = 12'h020;
  parameter logic [11:0] UART_RXGP_OFFSET = 12'h024;
  parameter logic [11:0] UART_RXG_OFFSET = 12'h028;
  parameter logic [11:0] UART_RXD_OFFSET = 12'h02C;
  parameter logic [11:0] UART_INT_EN_OFFSET = 12'h030;

  // UART_CTRL — offset 0x00 | RW
  // [31:5] reserved | [4] rx_en | [3] tx_en | [2] rx_fifo_flush | [1] tx_fifo_flush | [0] uart_rst
  typedef struct packed {
    logic [26:0] reserved;
    logic        rx_en;
    logic        tx_en;
    logic        rx_fifo_flush;
    logic        tx_fifo_flush;
    logic        uart_rst;
  } uart_ctrl_reg_t;

  // UART_CFG — offset 0x04 | RW
  // [31:21] reserved | [20] sb | [19] ptp | [18] pen | [17:16] db | [15:12] psclr | [11:0] clk_div
  typedef struct packed {
    logic [10:0] reserved;
    logic        sb;
    logic        ptp;
    logic        pen;
    logic [1:0]  db;
    logic [3:0]  psclr;
    logic [11:0] clk_div;
  } uart_cfg_reg_t;

  // UART_STAT — offset 0x08 | RO
  // [31:24] reserved | [23] rx_full | [22] rx_empty | [21] tx_full | [20] tx_empty | [19:10] rx_cnt | [9:0] tx_cnt
  typedef struct packed {
    logic [7:0] reserved;
    logic       rx_full;
    logic       rx_empty;
    logic       tx_full;
    logic       tx_empty;
    logic [9:0] rx_cnt;
    logic [9:0] tx_cnt;
  } uart_stat_reg_t;

  // UART_INT_EN — offset 0x30 | RW
  // [31:4] reserved | [3] rx_full_en | [2] rx_empty_en | [1] tx_full_en | [0] tx_empty_en
  typedef struct packed {
    logic [27:0] reserved;
    logic        rx_full_en;
    logic        rx_empty_en;
    logic        tx_full_en;
    logic        tx_empty_en;
  } uart_int_reg_t;

  // Helper Types for Valid/Ready payloads
  typedef struct packed {logic [7:0] id;} uart_id_t;
  typedef struct packed {logic [7:0] data;} uart_data_t;
  typedef struct packed {logic [9:0] count;} uart_count_t;

endpackage
`endif
