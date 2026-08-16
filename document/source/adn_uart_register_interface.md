# adn_uart_register_interface (module)

### Author: Ahasan Ullah Khalid (aukhalid02@gmail.com)

### Source: adn_uart_register_interface.sv

## Top IO

<img src="./adn_uart_register_interface_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|ADDR_WIDTH|int||32||
|DATA_WIDTH|int||32||
|RST_CLK_DIV|logic [11:0]||12'h05B|Default UART Configuration Reset Values|
|RST_PRESCALER|logic [ 3:0]||4'h4||
|RST_DATA_BITS|logic [ 1:0]||2'h3||
|RST_PARITY_EN|logic||1'b0||
|RST_PARITY_TY|logic||1'b0||
|RST_STOP_BITS|logic||1'b0||


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|clk|input|logic||Global Signals|
|rst_n|input|logic|||
|reg_addr|input|logic [ADDR_WIDTH-1:0]||===================================================================== Internal Bus Interface (Translated from APB) =====================================================================|
|reg_wdata|input|logic [DATA_WIDTH-1:0]|||
|reg_write_en|input|logic|||
|reg_read_en|input|logic|||
|reg_rdata|output|logic [DATA_WIDTH-1:0]|||
|reg_ready|output|logic|||
|reg_error|output|logic|||
|uart_sw_rst|output|logic||===================================================================== Hardware Control Outputs (UART_CTRL & UART_CFG) =====================================================================|
|tx_fifo_flush|output|logic|||
|rx_fifo_flush|output|logic|||
|tx_en|output|logic|||
|rx_en|output|logic|||
|clk_div|output|logic [11:0]|||
|prescaler|output|logic [ 3:0]|||
|data_bits|output|logic [ 1:0]|||
|parity_en|output|logic|||
|parity_type|output|logic|||
|stop_bits|output|logic|||
|tx_data_cnt|input|logic [9:0]||===================================================================== Status Inputs (UART_STAT) =====================================================================|
|rx_data_cnt|input|logic [9:0]|||
|tx_fifo_empty|input|logic|||
|tx_fifo_full|input|logic|||
|rx_fifo_empty|input|logic|||
|rx_fifo_full|input|logic|||
|tx_fifo_wdata|output|logic [7:0]||===================================================================== TX Datapath (UART_TXD) =====================================================================|
|tx_fifo_push|output|logic|||
|rx_fifo_rdata|input|logic [7:0]||===================================================================== RX Datapath (UART_RXD) =====================================================================|
|rx_fifo_pop|output|logic|||
|tx_access_req_id|output|logic [7:0]||===================================================================== TX Arbitration (UART_TXR, UART_TXGP, UART_TXG) =====================================================================|
|tx_req_valid|output|logic|||
|tx_grant_id|input|logic [7:0]|||
|tx_grant_valid|input|logic|||
|tx_grant_pop|output|logic|||
|rx_access_req_id|output|logic [7:0]||===================================================================== RX Arbitration (UART_RXR, UART_RXGP, UART_RXG) =====================================================================|
|rx_req_valid|output|logic|||
|rx_grant_id|input|logic [7:0]|||
|rx_grant_valid|input|logic|||
|rx_grant_pop|output|logic|||
|tx_fifo_empty_int_en|output|logic||===================================================================== Interrupts (UART_INT) =====================================================================|
|tx_fifo_full_int_en|output|logic|||
|rx_fifo_empty_int_en|output|logic|||
|rx_fifo_full_int_en|output|logic|||


## Description

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR              | DESCRIPTION                                            |
|----------|------------|---------------------|--------------------------------------------------------|
| 0.1      | 2026-08-16 | Ahasan Ullah Khalid | Initial version                                        |
| 1.0      | 2026-08-16 | Ahasan Ullah Khalid | Stable release                                         |

Author : Ahasan Ullah Khalid (aukhalid02@gmail.com)
