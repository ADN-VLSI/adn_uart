# adn_uart_pkg.sv  (package)

### Source: adn_uart_pkg.sv

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|UART_FIFO_DEPTH|int||16||
|UART_FIFO_COUNT_W|int||$clog2(UART_FIFO_DEPTH) + 1||
|UART_CTRL_OFFSET|logic [11:0]||12'h000|Register offsets|
|UART_CFG_OFFSET|logic [11:0]||12'h004||
|UART_STAT_OFFSET|logic [11:0]||12'h008||
|UART_TXR_OFFSET|logic [11:0]||12'h010||
|UART_TXGP_OFFSET|logic [11:0]||12'h014||
|UART_TXG_OFFSET|logic [11:0]||12'h018||
|UART_TXD_OFFSET|logic [11:0]||12'h01C||
|UART_RXR_OFFSET|logic [11:0]||12'h020||
|UART_RXGP_OFFSET|logic [11:0]||12'h024||
|UART_RXG_OFFSET|logic [11:0]||12'h028||
|UART_RXD_OFFSET|logic [11:0]||12'h02C||
|UART_INT_EN_OFFSET|logic [11:0]||12'h030||


## Typedefs

|Name|
|-|
|uart_ctrl_reg_t|
|uart_cfg_reg_t|
|uart_stat_reg_t|
|uart_int_reg_t|
|uart_id_t|
|uart_data_t|
|uart_count_t|


## Description

_No top-level description found._
