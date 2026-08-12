## Register Map Summary

All offsets are relative to the UART base address (`UART_BASE`). **All registers must be accessed as 32-bit words.** Byte and half-word accesses are supported only where the APB byte-enable strobes (`PSTRB`) correctly target the active byte lanes.

| Offset  | Name        | Type | Reset Value   | Description                                |
| ------- | ----------- | ---- | ------------- | ------------------------------------------ |
| `0x000` | `UART_CTRL` | RW   | `0x0000_0000` | Control: reset, FIFO flush, TX/RX enable   |
| `0x004` | `UART_CFG`  | RW   | `0x0003_405B` | Configuration: baud rate, frame format     |
| `0x008` | `UART_STAT` | RO   | `0x0050_0000` | Status: FIFO fill levels, empty/full flags |
| `0x010` | `UART_TXR`  | WO   | —             | TX arbitration: enqueue master request ID  |
| `0x014` | `UART_TXGP` | RO   | `0x0000_0000` | TX arbitration: non-consuming grant peek   |
| `0x018` | `UART_TXG`  | RO   | `0x0000_0000` | TX arbitration: consuming grant read       |
| `0x01C` | `UART_TXD`  | WO   | —             | TX data: write byte to transmit FIFO       |
| `0x020` | `UART_RXR`  | WO   | —             | RX arbitration: enqueue master request ID  |
| `0x024` | `UART_RXGP` | RO   | `0x0000_0000` | RX arbitration: non-consuming grant peek   |
| `0x028` | `UART_RXG`  | RO   | `0x0000_0000` | RX arbitration: consuming grant read       |
| `0x02C` | `UART_RXD`  | RO   | `0x0000_0000` | RX data: read byte from receive FIFO       |
| `0x030` | `UART_INT`  | RW   | `0x0000_0000` | Interrupt enable mask                      |

> **Note:** Offsets `0x00C`, `0x034`–`0xFFC` are **reserved**. Reads return `0x0000_0000`; writes are ignored (RAZ/WI).

---

## Register Descriptions

### UART_CTRL — Control Register

**Offset:** `0x000`  
**Type:** Read/Write  
**Reset:** `0x0000_0000`

Controls global UART behavior including software reset, FIFO flush, and datapath enable.

#### Detailed Bit Definitions

| Bit(s) | Field           | Reset | Access | Description                                                                                                                                                                                                                                             |
| ------ | --------------- | ----- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `0`    | `UART_SW_RST`   | `0`   | R/W    | **Software Reset.** When `1`, the internal UART state machine, baud-rate generator, and shift registers are held in reset. FIFO contents are preserved unless explicitly flushed. **Self-clearing not guaranteed; software must write `0` to release.** |
| `1`    | `TX_FIFO_FLUSH` | `0`   | R/W    | **TX FIFO Flush.** Write `1` to clear all entries in the transmit FIFO. The TX shift register is aborted if active. **Automatically returns to `0` after flush completes.**                                                                             |
| `2`    | `RX_FIFO_FLUSH` | `0`   | R/W    | **RX FIFO Flush.** Write `1` to clear all entries in the receive FIFO. Any byte currently in the RX shift register is discarded. **Automatically returns to `0` after flush completes.**                                                                |
| `3`    | `TX_EN`         | `0`   | R/W    | **Transmitter Enable.** `1` = transmitter logic active; `0` = TX path disabled. When disabled, the TX pin is typically tri-stated or driven to idle level (mark).                                                                                       |
| `4`    | `RX_EN`         | `0`   | R/W    | **Receiver Enable.** `1` = receiver logic active; `0` = RX path disabled. When disabled, incoming serial data is ignored.                                                                                                                               |
| `31:5` | —               | `0x0` | RAZ/WI | **Reserved.** Read as zero; writes ignored.                                                                                                                                                                                                             |

---

### UART_CFG — Configuration Register

**Offset:** `0x004`  
**Type:** Read/Write  
**Reset:** `0x0003_405B`

Configures baud-rate generation and asynchronous serial frame format.

#### Detailed Bit Definitions

| Bit(s)  | Field         | Reset          | Description                                                                                                                   |
| ------- | ------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `11:0`  | `CLK_DIV`     | `0x05B` (`91`) | **Clock Divider.** Fine-grained baud-rate divisor. The effective divider is `(CLK_DIV + 1)`. Range: 1–4096.                   |
| `15:12` | `PRESCALER`   | `0x4` (`4`)    | **Prescaler.** Coarse baud-rate divisor. The effective prescale factor is `(PRESCALER + 1)`. Range: 1–16.                     |
| `17:16` | `DATA_BITS`   | `0x3` (`11₂`)  | **Data Bits per Frame.** `00` = 5 bits, `01` = 6 bits, `10` = 7 bits, `11` = 8 bits.                                          |
| `18`    | `PARITY_EN`   | `0`            | **Parity Enable.** `1` = append parity bit after data bits; `0` = no parity.                                                  |
| `19`    | `PARITY_TYPE` | `0`            | **Parity Type.** `0` = even parity (total 1s including parity bit is even); `1` = odd parity. **Ignored if `PARITY_EN = 0`.** |
| `20`    | `STOP_BITS`   | `0`            | **Stop Bits.** `0` = 1 stop bit; `1` = 2 stop bits.                                                                           |
| `31:21` | —             | `0x0`          | **Reserved.** Read as zero; writes ignored.                                                                                   |

---

### UART_STAT — Status Register

**Offset:** `0x008`  
**Type:** Read-Only  
**Reset:** `0x0050_0000`

Provides real-time visibility into FIFO state. All fields are updated by hardware and reflect the state sampled at the `PCLK` rising edge of the read transaction.

#### Detailed Bit Definitions

| Bit(s)  | Field           | Reset   | Description                                                                                                                                  |
| ------- | --------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `9:0`   | `TX_DATA_CNT`   | `0x000` | **TX FIFO Data Count.** Number of valid bytes currently stored in the transmit FIFO. Range: `0x000`–`0x3FF` (0–1023).                        |
| `19:10` | `RX_DATA_CNT`   | `0x000` | **RX FIFO Data Count.** Number of valid bytes currently stored in the receive FIFO. Range: `0x000`–`0x3FF` (0–1023).                         |
| `20`    | `TX_FIFO_EMPTY` | `1`     | **TX FIFO Empty.** `1` = transmit FIFO contains zero bytes. Set when `TX_DATA_CNT == 0`.                                                     |
| `21`    | `TX_FIFO_FULL`  | `0`     | **TX FIFO Full.** `1` = transmit FIFO has reached maximum capacity. Software must **not** write to `UART_TXD` while this is asserted.        |
| `22`    | `RX_FIFO_EMPTY` | `1`     | **RX FIFO Empty.** `1` = receive FIFO contains zero bytes. Software must **not** read `UART_RXD` while this is asserted (data is undefined). |
| `23`    | `RX_FIFO_FULL`  | `0`     | **RX FIFO Full.** `1` = receive FIFO has reached maximum capacity. Any additional incoming serial bytes may be dropped (overrun condition).  |
| `31:24` | —               | `0x00`  | **Reserved.** Read as zero.                                                                                                                  |

#### Reset Value Analysis (`0x0050_0000`)

| Field           | Binary/Hex | Interpretation            |
| --------------- | ---------- | ------------------------- |
| `TX_DATA_CNT`   | `0x000`    | TX FIFO empty at reset    |
| `RX_DATA_CNT`   | `0x000`    | RX FIFO empty at reset    |
| `TX_FIFO_EMPTY` | `1`        | Confirms TX FIFO is empty |
| `TX_FIFO_FULL`  | `0`        | TX FIFO is not full       |
| `RX_FIFO_EMPTY` | `1`        | Confirms RX FIFO is empty |
| `RX_FIFO_FULL`  | `0`        | RX FIFO is not full       |

---

### UART_TXR — TX Access Request ID

**Offset:** `0x010`  
**Type:** Write-Only  
**Reset:** Undefined (WO)

Enqueues a master ID into the TX arbitration request FIFO. The hardware preserves request order (FIFO discipline).

| Bit(s) | Field              | Description                                                                                                                                                |
| ------ | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `7:0`  | `TX_ACCESS_REQ_ID` | **Master ID.** Unique identifier of the bus master requesting TX access. Typical assignment: `0x00` = reserved/invalid, `0x01` = CPU0, `0x02` = CPU1, etc. |
| `30:8` | —                  | **Reserved.** Writes ignored.                                                                                                                              |
| `31`   | `VALID`            | **Request Valid.** Must be `1` for the write to be accepted into the request FIFO. If `0`, the write is discarded.                                         |

### UART_TXGP — TX Access Grant ID Peek

**Offset:** `0x014`  
**Type:** Read-Only  
**Reset:** `0x0000_0000`

Provides a **non-consuming** view of the current TX grant. Reading this register does **not** advance the arbitration state machine.

### UART_TXG — TX Access Grant ID

**Offset:** `0x018`  
**Type:** Read-Only  
**Reset:** `0x0000_0000`

Provides a **consuming** read of the current TX grant. The act of reading this register **completes** the grant and allows the next queued master to be serviced.

#### Bit-Field Layout

Identical to `UART_TXGP`:

| Bit(s) | Field         | Reset      | Description                                                                                                        |
| ------ | ------------- | ---------- | ------------------------------------------------------------------------------------------------------------------ |
| `7:0`  | `TX_GRANT_ID` | `0x00`     | **Granted Master ID.** Same value as `UART_TXGP` at the moment of read.                                            |
| `30:8` | —             | `0x000000` | **Reserved.** Read as zero.                                                                                        |
| `31`   | `VALID`       | `0`        | **Grant Valid.** `1` = the consumed grant was valid; `0` = no grant was pending (read returned empty queue state). |

> **Note:** Only read `UART_TXG` **after** you have finising transmitting all data for this grant. Reading it prematurely will release the path to the next master, potentially interleaving their data with yours.

---

### UART_TXD — TX Data

**Offset:** `0x01C`  
**Type:** Write-Only  
**Reset:** Undefined (WO)

The data port for the transmit FIFO. Writes are accepted only if the TX FIFO is not full.

#### Bit-Field Layout

| Bit(s) | Field     | Description                                                                                       |
| ------ | --------- | ------------------------------------------------------------------------------------------------- |
| `7:0`  | `TX_DATA` | Byte to be pushed into the transmit FIFO. Only bits `[7:0]` are stored; upper bits are discarded. |
| `31:8` | —         | **Reserved.** Writes ignored.                                                                     |

---

### UART_RXR — RX Access Request ID

**Offset:** `0x020`  
**Type:** Write-Only  
**Reset:** Undefined (WO)

Enqueues a master ID into the RX arbitration request FIFO. Behavior is symmetric to `UART_TXR`.

| Bit(s) | Field              | Description                          |
| ------ | ------------------ | ------------------------------------ |
| `7:0`  | `RX_ACCESS_REQ_ID` | Master ID requesting receive access. |
| `30:8` | —                  | Reserved. Writes ignored.            |
| `31`   | `VALID`            | Must be `1` to enqueue the request.  |

---

### UART_RXGP — RX Access Grant ID Peek

**Offset:** `0x024`  
**Type:** Read-Only  
**Reset:** `0x0000_0000`

Non-consuming view of the RX grant. Symmetric to `UART_TXGP`.

| Bit(s) | Field              | Reset      | Description                                 |
| ------ | ------------------ | ---------- | ------------------------------------------- |
| `7:0`  | `RX_GRANT_ID_PEEK` | `0x00`     | Current granted master ID for receive path. |
| `30:8` | —                  | `0x000000` | Reserved. Read as zero.                     |
| `31`   | `VALID`            | `0`        | `1` = valid grant exists.                   |

---

### UART_RXG — RX Access Grant ID

**Offset:** `0x028`  
**Type:** Read-Only  
**Reset:** `0x0000_0000`

Consuming read of the RX grant. Symmetric to `UART_TXG`.

| Bit(s) | Field         | Reset      | Description                     |
| ------ | ------------- | ---------- | ------------------------------- |
| `7:0`  | `RX_GRANT_ID` | `0x00`     | Consumed grant ID.              |
| `30:8` | —             | `0x000000` | Reserved. Read as zero.         |
| `31`   | `VALID`       | `0`        | `1` = consumed grant was valid. |

> **Note:** Read `UART_RXG` only after finishingreading all RX data associated with this grant.

---

### UART_RXD — RX Data

**Offset:** `0x02C`  
**Type:** Read-Only  
**Reset:** `0x0000_0000`

Data port for the receive FIFO.

| Bit(s) | Field     | Reset      | Description                                          |
| ------ | --------- | ---------- | ---------------------------------------------------- |
| `7:0`  | `RX_DATA` | `0x00`     | Oldest byte in the receive FIFO. Pop occurs on read. |
| `31:8` | —         | `0x000000` | Reserved. Read as zero.                              |

#### Programming Rule

Before reading, verify:

1. You hold the RX grant (`UART_RXGP` matches your ID and `VALID=1`).
2. The RX FIFO is not empty (`UART_STAT[22] == 0`).

Reading when `RX_FIFO_EMPTY==1` returns undefined data (typically `0x00`, but not guaranteed).

---

### UART_INT — Interrupt Control

**Offset:** `0x030`  
**Type:** Read/Write  
**Reset:** `0x0000_0000`

Interrupt enable mask. Writing `1` to a bit enables the corresponding interrupt source; writing `0` disables it.

#### Bit-Field Layout

| Bit    | Field                  | Reset | Interrupt Source | Description                                                                                                                                                  |
| ------ | ---------------------- | ----- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `0`    | `TX_FIFO_EMPTY_INT_EN` | `0`   | TX FIFO Empty    | Asserted when the TX FIFO transitions from **non-empty** to **empty**. Useful for triggering a refill when the transmitter has drained all pending data.     |
| `1`    | `TX_FIFO_FULL_INT_EN`  | `0`   | TX FIFO Full     | Asserted when the TX FIFO transitions from **non-full** to **full**. Useful for backpressure signaling; stop enqueueing data.                                |
| `2`    | `RX_FIFO_EMPTY_INT_EN` | `0`   | RX FIFO Empty    | Asserted when the RX FIFO transitions from **non-empty** to **empty**. Indicates the software reader has caught up to the hardware.                          |
| `3`    | `RX_FIFO_FULL_INT_EN`  | `0`   | RX FIFO Full     | Asserted when the RX FIFO transitions from **non-full** to **full**. **Critical:** Indicates imminent data loss unless software drains the FIFO immediately. |
| `31:4` | —                      | `0x0` | —                | Reserved. Read as zero; writes ignored.                                                                                                                      |

---

## Appendix

### Register Quick Reference Card

```
Offset  Name      Type  Reset        Purpose
─────────────────────────────────────────────────────────
0x000   UART_CTRL RW    0x0000_0000  Reset, flush, enable
0x004   UART_CFG  RW    0x0003_405B  Baud, format
0x008   UART_STAT RO    0x0050_0000  FIFO levels
0x010   UART_TXR  WO    —            TX request
0x014   UART_TXGP RO    0x0000_0000  TX grant peek
0x018   UART_TXG  RO    0x0000_0000  TX grant consume
0x01C   UART_TXD  WO    —            TX data
0x020   UART_RXR  WO    —            RX request
0x024   UART_RXGP RO    0x0000_0000  RX grant peek
0x028   UART_RXG  RO    0x0000_0000  RX grant consume
0x02C   UART_RXD  RO    0x0000_0000  RX data
0x030   UART_INT  RW    0x0000_0000  Interrupt mask
```

### Reset Value `0x0003_405B` Bit Breakdown

| Bit Range | Hex Value | Field         | Meaning                      |
| --------- | --------- | ------------- | ---------------------------- |
| `11:0`    | `0x05B`   | `CLK_DIV`     | Divider = 91 → effective ÷92 |
| `15:12`   | `0x4`     | `PRESCALER`   | Prescale = 4 → effective ÷5  |
| `17:16`   | `0x3`     | `DATA_BITS`   | 8 data bits                  |
| `18`      | `0`       | `PARITY_EN`   | Parity disabled              |
| `19`      | `0`       | `PARITY_TYPE` | Even (don't care)            |
| `20`      | `0`       | `STOP_BITS`   | 1 stop bit                   |
| `31:21`   | `0x000`   | Reserved      | All zeros                    |
