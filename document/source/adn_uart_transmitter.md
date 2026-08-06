# adn_uart_transmitter (module)

### Source: adn_uart_transmitter.sv

## Top IO

<img src="./adn_uart_transmitter_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|DATA_WIDTH|int||8|Width of the input data bus|


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|arst_ni|input|logic||asynchronous reset, active low|
|clk_i|input|logic||clock input|
|data_ready_o|output|logic||High when transmitter is ready to accept new data|
|data_valid_i|input|logic||High when input data is valid|
|data_i|input|logic [7:0]||Parallel data to be transmitted|
|data_bits_i|input|logic [1:0]||Number of data bits (0:5b, 1:6b, 2:7b, 3:8b)|
|parity_en_i|input|logic||Enable parity bit generation|
|parity_type_i|input|logic||Parity type (0:even, 1:odd)|
|extra_stop_i|input|logic||Enable second stop bit|
|tx_o|output|logic||Serialized UART output bitstream|


## Description

_No top-level description found._
