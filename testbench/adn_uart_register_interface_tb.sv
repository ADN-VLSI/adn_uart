/*

| TEST CASE | DATE       | AUTHOR             | DESCRIPTION                                                  |
|-----------|------------|--------------------|---------------------------------------------------------------|
| TC_001    | 2026-08-31 | Adnan Sami Anirban | Reset values of uart_ctrl_o / uart_cfg_o / uart_int_en_o       |
| TC_002    | 2026-08-31 | Adnan Sami Anirban | UART_CTRL RW + self-clearing bits (uart_rst, fifo flushes)     |
| TC_003    | 2026-08-31 | Adnan Sami Anirban | UART_CFG write gated on TX/RX FIFO empty                       |
| TC_004    | 2026-08-31 | Adnan Sami Anirban | UART_STAT read-only + combinational status construction        |
| TC_005    | 2026-08-31 | Adnan Sami Anirban | TX data enqueue (UART_TXD), gated on tx_data_ready_i            |
| TC_006    | 2026-08-31 | Adnan Sami Anirban | TX arbitration request (UART_TXR), gated on tx_req_ready_i      |
| TC_007    | 2026-08-31 | Adnan Sami Anirban | TX grant peek (UART_TXGP) vs consuming pop (UART_TXG)           |
| TC_008    | 2026-08-31 | Adnan Sami Anirban | RX arbitration request/grant (mirror of TC_006 / TC_007)        |
| TC_009    | 2026-08-31 | Adnan Sami Anirban | RX data dequeue (UART_RXD), consuming pop vs empty              |
| TC_010    | 2026-08-31 | Adnan Sami Anirban | UART_INT_EN RW                                                  |
| TC_011    | 2026-08-31 | Adnan Sami Anirban | Read-as-zero (RAZ) on write-only offsets (TXR/TXD/RXR)          |
| TC_012    | 2026-08-31 | Adnan Sami Anirban | Illegal address -> write_error / read_error                    |
| TC_013    | 2026-08-31 | Adnan Sami Anirban | mstrb == 0 write treated as error (PR-15 compliance)            |

| REVISION | DATE       | AUTHOR             | DESCRIPTION                                            |
|----------|------------|--------------------|--------------------------------------------------------|
| 0.1      | 2026-08-31 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-08-31 | Adnan Sami Anirban | Stable release                                         |
| 1.1      | 2026-08-31 | Adnan Sami Anirban | Fixed self-clear TCs (hidden idle-cycle race); moved   |
|          |            |                    | each TC into its own task, dispatched via TEST select  |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
This file is part of ADN-VLSI/adn_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_uart_register_interface_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  `include "adn_uart_pkg.sv"
  `include "pmi/typedef.svh"

  import adn_uart_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int  ADDR_WIDTH = 32;
  localparam int  DATA_WIDTH = 32;
  localparam time CLK_PERIOD = 10ns;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `PMI_T(pmi, ADDR_WIDTH, DATA_WIDTH)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic clk_i;
  logic arst_ni;

  pmi_req_t pmi_req;
  pmi_rsp_t pmi_rsp;

  uart_ctrl_reg_t uart_ctrl;
  uart_cfg_reg_t  uart_cfg;
  uart_stat_reg_t uart_stat;
  uart_int_reg_t  uart_int_en;

  uart_data_t tx_data;
  logic       tx_data_valid;
  logic       tx_data_ready;

  uart_data_t rx_data;
  logic       rx_data_valid;
  logic       rx_data_ready;

  uart_id_t tx_req_id;
  logic     tx_req_valid;
  logic     tx_req_ready;

  uart_id_t tx_grant_id;
  logic     tx_grant_valid;
  logic     tx_grant_ready;

  uart_id_t rx_req_id;
  logic     rx_req_valid;
  logic     rx_req_ready;

  uart_id_t rx_grant_id;
  logic     rx_grant_valid;
  logic     rx_grant_ready;

  uart_count_t tx_data_cnt;
  uart_count_t rx_data_cnt;
  logic        tx_uart_idle;

  // combinational side-effects captured during the request cycle of the
  // most recent pmi_write / pmi_read call (see METHODS section)
  logic       mon_tx_data_valid;
  logic       mon_tx_req_valid;
  logic       mon_rx_req_valid;
  logic       mon_tx_grant_ready;
  logic       mon_rx_grant_ready;
  logic       mon_rx_data_ready;
  uart_id_t   mon_tx_req_id;
  uart_id_t   mon_rx_req_id;
  uart_data_t mon_tx_data;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // (none — each TC task keeps its own working variables as automatic locals)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // (none — DUT is connected with flat signals, no SV interface used)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLASSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // (none — directed task-based testbench, no class-based VIP)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // (none)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_uart_register_interface #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .pmi_req_t (pmi_req_t),
      .pmi_rsp_t (pmi_rsp_t)
  ) dut (
      .clk_i  (clk_i),
      .arst_ni(arst_ni),

      .pmi_req_i(pmi_req),
      .pmi_rsp_o(pmi_rsp),

      .uart_ctrl_o  (uart_ctrl),
      .uart_cfg_o   (uart_cfg),
      .uart_stat_o  (uart_stat),
      .uart_int_en_o(uart_int_en),

      .tx_data_o      (tx_data),
      .tx_data_valid_o(tx_data_valid),
      .tx_data_ready_i(tx_data_ready),

      .rx_data_i      (rx_data),
      .rx_data_valid_i(rx_data_valid),
      .rx_data_ready_o(rx_data_ready),

      .tx_req_id_o   (tx_req_id),
      .tx_req_valid_o(tx_req_valid),
      .tx_req_ready_i(tx_req_ready),

      .tx_grant_id_i   (tx_grant_id),
      .tx_grant_valid_i(tx_grant_valid),
      .tx_grant_ready_o(tx_grant_ready),

      .rx_req_id_o   (rx_req_id),
      .rx_req_valid_o(rx_req_valid),
      .rx_req_ready_i(rx_req_ready),

      .rx_grant_id_i   (rx_grant_id),
      .rx_grant_valid_i(rx_grant_valid),
      .rx_grant_ready_o(rx_grant_ready),

      .tx_data_cnt_i (tx_data_cnt),
      .rx_data_cnt_i (rx_data_cnt),
      .tx_uart_idle_i(tx_uart_idle)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // --- checker helpers -----------------------------------------------------
  // wraps note_case() with a named diagnostic print so console output stays
  // readable; swap for your team's preferred assertion helper if
  // adn_common_tb_headers.sv already provides a named-check macro
  task automatic check(string name, logic [63:0] actual, logic [63:0] expected);
    bit pass;
    pass = (actual === expected);
    if (!pass) $display("[%0t] FAIL: %-46s exp=0x%0h got=0x%0h", $time, name, expected, actual);
    else $display("[%0t] PASS: %-46s got=0x%0h", $time, name, actual);
    note_case(pass);
  endtask

  task automatic check_bit(string name, logic actual, logic expected);
    check(name, {63'b0, actual}, {63'b0, expected});
  endtask

  // --- bus driver -----------------------------------------------------------
  task automatic pmi_idle();
    pmi_req.maddr  = '0;
    pmi_req.mwe    = 1'b0;
    pmi_req.mwdata = '0;
    pmi_req.mstrb  = '0;
    pmi_req.mreq   = 1'b0;
  endtask

  // 0-wait-state PMI: response is combinational on the same cycle mreq is
  // asserted, register updates land on the following posedge.
  //
  // NOTE: no leading @(negedge clk_i) here — the caller is guaranteed to
  // already be sitting on a negedge (every task exits on one, and the main
  // sequence syncs to one before the first call). Adding a second wait here
  // would insert a hidden idle clock cycle between back-to-back
  // transactions — that hidden cycle's own posedge is what let CTRL's
  // self-clear bits (uart_rst / tx_fifo_flush / rx_fifo_flush) auto-clear
  // one cycle "early", before a follow-up read ever sampled the set value.
  task automatic pmi_write_strb(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data,
                                 input logic [DATA_WIDTH/8-1:0] strb, output logic resp);
    pmi_req.maddr  = addr;
    pmi_req.mwdata = data;
    pmi_req.mwe    = 1'b1;
    pmi_req.mstrb  = strb;
    pmi_req.mreq   = 1'b1;
    #(CLK_PERIOD / 4);
    resp              = pmi_rsp.mresp;
    mon_tx_data_valid = tx_data_valid;
    mon_tx_req_valid  = tx_req_valid;
    mon_rx_req_valid  = rx_req_valid;
    mon_tx_data       = tx_data;
    mon_tx_req_id     = tx_req_id;
    mon_rx_req_id     = rx_req_id;
    @(negedge clk_i);
    pmi_idle();
  endtask

  task automatic pmi_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data,
                            output logic resp);
    pmi_write_strb(addr, data, '1, resp);
  endtask

  task automatic pmi_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] rdata,
                           output logic resp);
    // see NOTE in pmi_write_strb — no leading @(negedge clk_i) here either
    pmi_req.maddr = addr;
    pmi_req.mwe   = 1'b0;
    pmi_req.mreq  = 1'b1;
    #(CLK_PERIOD / 4);
    rdata              = pmi_rsp.mrdata;
    resp               = pmi_rsp.mresp;
    mon_tx_grant_ready = tx_grant_ready;
    mon_rx_grant_ready = rx_grant_ready;
    mon_rx_data_ready  = rx_data_ready;
    @(negedge clk_i);
    pmi_idle();
  endtask

  // --- common setup -----------------------------------------------------
  task automatic drive_default_inputs();
    tx_data_ready  = 1'b0;
    rx_data_valid  = 1'b0;
    rx_data        = '0;
    tx_req_ready   = 1'b0;
    rx_req_ready   = 1'b0;
    tx_grant_valid = 1'b0;
    tx_grant_id    = '0;
    rx_grant_valid = 1'b0;
    rx_grant_id    = '0;
    tx_data_cnt    = '0;
    rx_data_cnt    = '0;
    tx_uart_idle   = 1'b0;
    pmi_idle();
  endtask

  // --- test cases -----------------------------------------------------------

  task automatic tc_001_reset_values();
    $display("\n===== TC_001: Reset values =====");
    check("uart_ctrl_o reset value", uart_ctrl, 32'h0);
    check("uart_cfg_o reset value", uart_cfg, 32'h0003_405B);
    check("uart_int_en_o reset value", uart_int_en, 32'h0);
  endtask

  task automatic tc_002_ctrl_rw_self_clear();
    uart_ctrl_reg_t         wr_ctrl;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   resp;

    $display("\n===== TC_002: UART_CTRL RW + self-clearing bits =====");
    wr_ctrl = '0;
    wr_ctrl.tx_en = 1'b1;
    wr_ctrl.rx_en = 1'b1;
    pmi_write(UART_CTRL_OFFSET, wr_ctrl, resp);
    check_bit("CTRL write mresp", resp, 1'b0);
    pmi_read(UART_CTRL_OFFSET, rdata, resp);
    check("CTRL readback (tx_en/rx_en)", rdata, wr_ctrl);

    wr_ctrl = '0;
    wr_ctrl.uart_rst = 1'b1;
    pmi_write(UART_CTRL_OFFSET, wr_ctrl, resp);
    pmi_read(UART_CTRL_OFFSET, rdata, resp);
    check_bit("uart_rst set the cycle after write", rdata[0], 1'b1);
    pmi_read(UART_CTRL_OFFSET, rdata, resp);
    check_bit("uart_rst auto-cleared next cycle", rdata[0], 1'b0);

    wr_ctrl = '0;
    wr_ctrl.tx_fifo_flush = 1'b1;
    wr_ctrl.rx_fifo_flush = 1'b1;
    pmi_write(UART_CTRL_OFFSET, wr_ctrl, resp);
    pmi_read(UART_CTRL_OFFSET, rdata, resp);
    check_bit("tx_fifo_flush set", rdata[1], 1'b1);
    check_bit("rx_fifo_flush set", rdata[2], 1'b1);
    pmi_read(UART_CTRL_OFFSET, rdata, resp);
    check_bit("tx_fifo_flush auto-cleared", rdata[1], 1'b0);
    check_bit("rx_fifo_flush auto-cleared", rdata[2], 1'b0);
  endtask

  task automatic tc_003_cfg_gated_write();
    uart_cfg_reg_t          wr_cfg;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   resp;

    $display("\n===== TC_003: UART_CFG write gated on TX/RX FIFO empty =====");
    wr_cfg = '0;
    wr_cfg.clk_div = 12'd100;
    wr_cfg.psclr   = 4'd3;
    wr_cfg.db      = 2'd1;
    wr_cfg.pen     = 1'b1;

    tx_data_cnt.count = '0;
    rx_data_cnt.count = '0;
    pmi_write(UART_CFG_OFFSET, wr_cfg, resp);
    check_bit("CFG write allowed when FIFOs empty", resp, 1'b0);
    pmi_read(UART_CFG_OFFSET, rdata, resp);
    check("CFG readback after allowed write", rdata, wr_cfg);

    tx_data_cnt.count = 10'd3;
    pmi_write(UART_CFG_OFFSET, 32'hDEAD_BEEF, resp);
    check_bit("CFG write blocked when TX FIFO non-empty", resp, 1'b1);
    pmi_read(UART_CFG_OFFSET, rdata, resp);
    check("CFG unchanged after blocked write (TX)", rdata, wr_cfg);

    tx_data_cnt.count = '0;
    rx_data_cnt.count = 10'd1;
    pmi_write(UART_CFG_OFFSET, 32'hDEAD_BEEF, resp);
    check_bit("CFG write blocked when RX FIFO non-empty", resp, 1'b1);
    pmi_read(UART_CFG_OFFSET, rdata, resp);
    check("CFG unchanged after blocked write (RX)", rdata, wr_cfg);

    rx_data_cnt.count = '0;
  endtask

  task automatic tc_004_stat_ro_combinational();
    uart_stat_reg_t         exp_stat;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   resp;

    $display("\n===== TC_004: UART_STAT read-only + combinational status =====");
    pmi_write(UART_STAT_OFFSET, 32'hFFFF_FFFF, resp);
    check_bit("STAT write rejected (RO)", resp, 1'b1);

    tx_data_cnt.count = '0;
    rx_data_cnt.count = '0;
    tx_uart_idle      = 1'b1;
    @(negedge clk_i);
    pmi_read(UART_STAT_OFFSET, rdata, resp);
    exp_stat          = '0;
    exp_stat.tx_empty = 1'b1;
    exp_stat.rx_empty = 1'b1;
    check_bit("STAT read mresp", resp, 1'b0);
    check("STAT value (empty FIFOs, TX idle)", rdata, exp_stat);

    tx_data_cnt.count = 10'(UART_FIFO_DEPTH);
    rx_data_cnt.count = 10'(UART_FIFO_DEPTH);
    tx_uart_idle       = 1'b0;
    @(negedge clk_i);
    pmi_read(UART_STAT_OFFSET, rdata, resp);
    exp_stat         = '0;
    exp_stat.tx_full = 1'b1;
    exp_stat.rx_full = 1'b1;
    exp_stat.tx_cnt  = 10'(UART_FIFO_DEPTH);
    exp_stat.rx_cnt  = 10'(UART_FIFO_DEPTH);
    check("STAT value (full FIFOs)", rdata, exp_stat);

    tx_data_cnt.count = '0;
    rx_data_cnt.count = '0;
    tx_uart_idle       = 1'b0;
  endtask

  task automatic tc_005_tx_data_path();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_005: TX data path (UART_TXD_OFFSET) =====");
    tx_data_ready = 1'b1;
    pmi_write(UART_TXD_OFFSET, 32'h0000_00A5, resp);
    check_bit("TXD write mresp (ready=1)", resp, 1'b0);
    check_bit("tx_data_valid_o pulsed", mon_tx_data_valid, 1'b1);
    check("tx_data_o.data", mon_tx_data.data, 8'hA5);

    tx_data_ready = 1'b0;
    pmi_write(UART_TXD_OFFSET, 32'h0000_005A, resp);
    check_bit("TXD write mresp (ready=0 -> error)", resp, 1'b1);
    check_bit("tx_data_valid_o not asserted when not ready", mon_tx_data_valid, 1'b0);
  endtask

  task automatic tc_006_tx_arb_request();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_006: TX arbitration request (UART_TXR_OFFSET) =====");
    tx_req_ready = 1'b1;
    pmi_write(UART_TXR_OFFSET, 32'h0000_0011, resp);
    check_bit("TXR write mresp (ready=1)", resp, 1'b0);
    check_bit("tx_req_valid_o pulsed", mon_tx_req_valid, 1'b1);
    check("tx_req_id_o.id", mon_tx_req_id.id, 8'h11);

    tx_req_ready = 1'b0;
    pmi_write(UART_TXR_OFFSET, 32'h0000_0022, resp);
    check_bit("TXR write mresp (ready=0 -> error)", resp, 1'b1);
    check_bit("tx_req_valid_o not asserted when not ready", mon_tx_req_valid, 1'b0);
  endtask

  task automatic tc_007_tx_grant_peek_pop();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_007: TX grant peek (TXGP) vs pop (TXG) =====");
    tx_grant_valid = 1'b1;
    tx_grant_id.id = 8'h77;

    pmi_read(UART_TXGP_OFFSET, rdata, resp);
    check_bit("TXGP read mresp", resp, 1'b0);
    check("TXGP peek value", rdata, 32'h77);
    check_bit("TXGP does not pop", mon_tx_grant_ready, 1'b0);

    pmi_read(UART_TXGP_OFFSET, rdata, resp);
    check("TXGP peek stable (still pending)", rdata, 32'h77);

    pmi_read(UART_TXG_OFFSET, rdata, resp);
    check_bit("TXG read mresp", resp, 1'b0);
    check("TXG pop value", rdata, 32'h77);
    check_bit("TXG pops grant", mon_tx_grant_ready, 1'b1);

    tx_grant_valid = 1'b0;  // simulate grant now consumed upstream
    pmi_read(UART_TXG_OFFSET, rdata, resp);
    check_bit("TXG read mresp when no grant pending", resp, 1'b0);
    check("TXG returns 0 when no grant pending", rdata, 32'h0);
    check_bit("TXG does not pop when no grant", mon_tx_grant_ready, 1'b0);
  endtask

  task automatic tc_008_rx_arb_request_grant();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_008: RX arbitration request/grant (mirror of TX) =====");
    rx_req_ready = 1'b1;
    pmi_write(UART_RXR_OFFSET, 32'h0000_0033, resp);
    check_bit("RXR write mresp (ready=1)", resp, 1'b0);
    check_bit("rx_req_valid_o pulsed", mon_rx_req_valid, 1'b1);
    check("rx_req_id_o.id", mon_rx_req_id.id, 8'h33);

    rx_req_ready = 1'b0;
    pmi_write(UART_RXR_OFFSET, 32'h0000_0044, resp);
    check_bit("RXR write mresp (ready=0 -> error)", resp, 1'b1);
    check_bit("rx_req_valid_o not asserted when not ready", mon_rx_req_valid, 1'b0);

    rx_grant_valid = 1'b1;
    rx_grant_id.id = 8'h88;
    pmi_read(UART_RXGP_OFFSET, rdata, resp);
    check("RXGP peek value", rdata, 32'h88);
    check_bit("RXGP does not pop", mon_rx_grant_ready, 1'b0);

    pmi_read(UART_RXG_OFFSET, rdata, resp);
    check("RXG pop value", rdata, 32'h88);
    check_bit("RXG pops grant", mon_rx_grant_ready, 1'b1);

    rx_grant_valid = 1'b0;
    pmi_read(UART_RXG_OFFSET, rdata, resp);
    check("RXG returns 0 when no grant pending", rdata, 32'h0);
    check_bit("RXG does not pop when no grant", mon_rx_grant_ready, 1'b0);
  endtask

  task automatic tc_009_rx_data_path();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_009: RX data path (UART_RXD_OFFSET) =====");
    rx_data_valid = 1'b1;
    rx_data.data  = 8'hC3;
    pmi_read(UART_RXD_OFFSET, rdata, resp);
    check_bit("RXD read mresp", resp, 1'b0);
    check("RXD pop value", rdata, 32'hC3);
    check_bit("RXD pops RX FIFO", mon_rx_data_ready, 1'b1);

    rx_data_valid = 1'b0;
    pmi_read(UART_RXD_OFFSET, rdata, resp);
    check_bit("RXD read mresp when empty", resp, 1'b0);
    check("RXD returns 0 when empty", rdata, 32'h0);
    check_bit("RXD does not pop when empty", mon_rx_data_ready, 1'b0);
  endtask

  task automatic tc_010_int_en_rw();
    uart_int_reg_t          wr_int;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   resp;

    $display("\n===== TC_010: UART_INT_EN RW =====");
    wr_int = '0;
    wr_int.tx_empty_en = 1'b1;
    wr_int.rx_full_en  = 1'b1;
    pmi_write(UART_INT_EN_OFFSET, wr_int, resp);
    check_bit("INT_EN write mresp", resp, 1'b0);
    pmi_read(UART_INT_EN_OFFSET, rdata, resp);
    check("INT_EN readback", rdata, wr_int);
  endtask

  task automatic tc_011_raz_write_only();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_011: Read-as-zero on write-only offsets =====");
    pmi_read(UART_TXR_OFFSET, rdata, resp);
    check_bit("TXR read mresp (RAZ)", resp, 1'b0);
    check("TXR read-as-zero", rdata, 32'h0);

    pmi_read(UART_TXD_OFFSET, rdata, resp);
    check_bit("TXD read mresp (RAZ)", resp, 1'b0);
    check("TXD read-as-zero", rdata, 32'h0);

    pmi_read(UART_RXR_OFFSET, rdata, resp);
    check_bit("RXR read mresp (RAZ)", resp, 1'b0);
    check("RXR read-as-zero", rdata, 32'h0);
  endtask

  task automatic tc_012_illegal_address();
    logic [DATA_WIDTH-1:0] rdata;
    logic                  resp;

    $display("\n===== TC_012: Illegal address access =====");
    pmi_write(12'h100, 32'hDEAD_BEEF, resp);
    check_bit("Illegal write -> error", resp, 1'b1);

    pmi_read(12'h100, rdata, resp);
    check_bit("Illegal read -> error", resp, 1'b1);
    check("Illegal read returns 0", rdata, 32'h0);
  endtask

  task automatic tc_013_mstrb_zero_error();
    uart_ctrl_reg_t before_ctrl;
    logic           resp;

    $display("\n===== TC_013: mstrb == 0 write treated as error (PR-15) =====");
    before_ctrl = uart_ctrl;
    pmi_write_strb(UART_CTRL_OFFSET, 32'hFFFF_FFFF, 4'h0, resp);
    check_bit("mstrb==0 write treated as error", resp, 1'b1);
    check("CTRL unchanged after mstrb==0 write", uart_ctrl, before_ctrl);
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial clk_i = 1'b0;
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  initial begin
    arst_ni = 1'b0;
    repeat (5) @(posedge clk_i);
    arst_ni = 1'b1;
  end

  // safety timeout in case a task hangs waiting on a signal
  initial begin
    #(CLK_PERIOD * 2000);
    $error("TIMEOUT: testbench did not finish in time");
    $finish;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial

    drive_default_inputs();

    wait (arst_ni === 1'b1);
    @(posedge clk_i);
    // establish the negedge baseline the pmi_* tasks assume
    @(negedge clk_i);

    // TEST is expected to come from adn_common_tb_headers.sv (populated via
    // +TEST=TC_xxx plusarg, as seen in the "TEST: default" banner). Adjust
    // the case selector name here if your harness uses a different variable.
    case (test_name)
      "TC_001": tc_001_reset_values();
      "TC_002": tc_002_ctrl_rw_self_clear();
      "TC_003": tc_003_cfg_gated_write();
      "TC_004": tc_004_stat_ro_combinational();
      "TC_005": tc_005_tx_data_path();
      "TC_006": tc_006_tx_arb_request();
      "TC_007": tc_007_tx_grant_peek_pop();
      "TC_008": tc_008_rx_arb_request_grant();
      "TC_009": tc_009_rx_data_path();
      "TC_010": tc_010_int_en_rw();
      "TC_011": tc_011_raz_write_only();
      "TC_012": tc_012_illegal_address();
      "TC_013": tc_013_mstrb_zero_error();
      default: begin
        tc_001_reset_values();
        tc_002_ctrl_rw_self_clear();
        tc_003_cfg_gated_write();
        tc_004_stat_ro_combinational();
        tc_005_tx_data_path();
        tc_006_tx_arb_request();
        tc_007_tx_grant_peek_pop();
        tc_008_rx_arb_request_grant();
        tc_009_rx_data_path();
        tc_010_int_en_rw();
        tc_011_raz_write_only();
        tc_012_illegal_address();
        tc_013_mstrb_zero_error();
      end
    endcase

    $finish;

  end

endmodule