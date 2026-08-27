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


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|clk_i|input|logic|||
|arst_ni|input|logic|||
|reg_addr_i|input|logic [ADDR_WIDTH-1:0]||Standalone Custom Bus Interface|
|reg_wdata_i|input|logic [DATA_WIDTH-1:0]|||
|reg_wen_i|input|logic|||
|reg_ren_i|input|logic|||
|reg_rdata_o|output|logic [DATA_WIDTH-1:0]|||
|reg_ready_o|output|logic|||
|reg_error_o|output|logic|||
|uart_ctrl_o|output|uart_ctrl_reg_t||Hardware Struct Outputs|
|uart_cfg_o|output|uart_cfg_reg_t|||
|uart_stat_o|output|uart_stat_reg_t|||
|uart_int_en_o|output|uart_int_reg_t|||
|tx_data_o|output|uart_data_t||TX Datapath (Valid/Ready)|
|tx_data_valid_o|output|logic|||
|tx_data_ready_i|input|logic|||
|rx_data_i|input|uart_data_t||RX Datapath (Valid/Ready)|
|rx_data_valid_i|input|logic|||
|rx_data_ready_o|output|logic|||
|tx_req_id_o|output|uart_id_t||TX Arbitration Request (Valid/Ready Enqueue)|
|tx_req_valid_o|output|logic|||
|tx_req_ready_i|input|logic|||
|tx_grant_id_i|input|uart_id_t||TX Arbitration Grant (Valid/Ready Dequeue)|
|tx_grant_valid_i|input|logic|||
|tx_grant_ready_o|output|logic|||
|rx_req_id_o|output|uart_id_t||RX Arbitration Request (Valid/Ready Enqueue)|
|rx_req_valid_o|output|logic|||
|rx_req_ready_i|input|logic|||
|rx_grant_id_i|input|uart_id_t||RX Arbitration Grant (Valid/Ready Dequeue)|
|rx_grant_valid_i|input|logic|||
|rx_grant_ready_o|output|logic|||
|tx_data_cnt_i|input|uart_count_t||Status & Idle Monitoring|
|rx_data_cnt_i|input|uart_count_t|||
|tx_uart_idle_i|input|logic|||


## Description

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
