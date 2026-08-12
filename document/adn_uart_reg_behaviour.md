### Design Philosophy

| Design Decision                         | Rationale                                                                                                                               |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Multi-master arbitration**            | Eliminates need for atomic test-and-set or mutexes in software when multiple CPUs share one UART for debug/logging.                     |
| **Separate peek vs. consume registers** | Allows a master to verify it holds the grant before acting, preventing accidental consumption due to speculative reads or debug probes. |
| **Level-sensitive interrupts**          | Reduces interrupt storm risk; edge detection is handled by the interrupt controller.                                                    |
| **Deep FIFOs**                          | Minimizes CPU intervention; typical depth supports 1024 entries (10-bit count fields in STAT).                                          |

---

#### Baud Rate Formula

```
                    UART_CLK_Hz
Baud Rate = ─────────────────────────────
            (PRESCALER + 1) × (CLK_DIV + 1)
```

**Example:** With `UART_CLK = 50 MHz`, `PRESCALER = 4`, `CLK_DIV = 91`:

```
            50,000,000
Baud Rate = ──────────── = 50,000,000 / (5 × 92) ≈ 108,696 baud
              5 × 92
```

#### Behavior

```
Software Action                          Hardware Response
─────────────────────────────────────────────────────────────────
Write {VALID=1, ID=0x01} to UART_TXR  →  Enqueue 0x01 into TX_REQ_FIFO
                                          If FIFO full: write silently dropped
                                          (no bus error, no interrupt)
```

> **Warning:** A master should enqueue itself **only once** per transaction burst. Repeated writes with the same ID will create multiple queue entries, causing that master to be granted multiple sequential turns.

---

## Multi-Master Arbitration Protocol

### Conceptual Model

The arbitration mechanism implements a **hardware ticket queue** for each datapath (TX and RX). This eliminates the need for:

- Spinlocks or mutexes in software
- Atomic read-modify-write instructions
- Bus-level locking (e.g., AHB LOCK)

```
        Master A (ID=0x01)              Master B (ID=0x02)
              │                              │
              ▼                              ▼
        ┌───────────┐                  ┌───────────┐
        │ Write     │                  │ Write     │
        │ 0x80000001│                  │ 0x80000002│
        │ to TXR    │                  │ to TXR    │
        └────┬──────┘                  └────┬──────┘
             │                              │
             └────────────┬─────────────────┘
                          ▼
                   ┌──────────────┐
                   │ TX_REQ_FIFO  │
                   │  [0x01, 0x02]│
                   └──────┬───────┘
                          │
                   ┌──────▼───────┐
                   │ Grant Logic  │
                   │  Head = 0x01 │
                   └──────┬───────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
        UART_TXGP =           UART_TXGP =
        0x80000001            0x80000001
        (Master A sees        (Master B sees
         its ID, acts)        not its ID, polls)
```

### TX Arbitration State Machine

```
┌─────────────┐     Write to UART_TXR    ┌─────────────┐
│   IDLE      │ ───────────────────────► │  REQUESTED  │
│ (no queue)  │    VALID=1, ID enqueued  │ (in queue)  │
└─────────────┘                          └──────┬──────┘
                                                │
                                                │ Head of queue reached
                                                ▼
                                         ┌─────────────┐
                                         │   GRANTED   │
                                         │ (TXGP match)│
                                         └──────┬──────┘
                                                │
                                                │ Write to UART_TXD
                                                │ Read UART_TXG
                                                ▼
                                         ┌─────────────────┐
                                         │  COMPLETE       │
                                         │ (grant consumed)│
                                         └─────────────────┘
```

### Arbitration Fairness & Deadlock Considerations

| Scenario                                  | Behavior                                                                                                                                                                                       |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Same ID enqueued twice**                | The master gets two back-to-back grants. This is legal but usually a software bug.                                                                                                             |
| **Master requests but never consumes**    | The queue stalls at that master. All subsequent masters wait indefinitely. **Always consume your grant.**                                                                                      |
| **Master consumes without holding grant** | If the queue is empty, `VALID=0` is returned. If the queue is non-empty, the head grant is consumed regardless of who reads it. **Do not read `TXG`/`RXG` unless you verified `TXGP`/`RXGP`.** |
| **Debug probe reads `TXG`**               | A debugger performing a memory dump that touches `0x018` will **consume** the active grant, breaking the protocol. Mask `0x018` from debug scans.                                              |

---

## Interrupt Handling

### Recommended Interrupt Strategy

| Use Case              | Enabled Interrupts | Handler Action                                                       |
| --------------------- | ------------------ | -------------------------------------------------------------------- |
| **TX streaming**      | `TX_FIFO_EMPTY`    | Refill FIFO from memory buffer; consume grant when buffer exhausted. |
| **RX streaming**      | `RX_FIFO_FULL`     | Emergency drain to prevent overrun; schedule deferred processing.    |
| **Low-power polling** | `RX_FIFO_EMPTY`    | Wake CPU when RX FIFO drains completely (end of packet).             |
| **Backpressure**      | `TX_FIFO_FULL`     | Stop DMA/channel until FIFO has room.                                |

---
