// ============================================================================
// tb.sv
// AXI-Lite Verification Environment Top
// Drives DUT + Runs Driver, Monitor, Scoreboard
// ============================================================================

`timescale 1ns/1ps

module tb;

    // ------------------------------------------------------------------------
    // Clock + Reset
    // ------------------------------------------------------------------------
    logic ACLK;
    logic ARESETN;

    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;   // 100 MHz
    end

    initial begin
        ARESETN = 0;
        repeat(10) @(posedge ACLK);
        ARESETN = 1;
    end

    // ------------------------------------------------------------------------
    // AXI Interface
    // ------------------------------------------------------------------------
    axi_if axi_if_inst(
        .ACLK    (ACLK),
        .ARESETN (ARESETN)
    );

    // ------------------------------------------------------------------------
    // DUT Instance
    // ------------------------------------------------------------------------
    top_soc dut (
        .ACLK     (ACLK),
        .ARESETN  (ARESETN),

        .AWVALID  (axi_if_inst.AWVALID),
        .AWREADY  (axi_if_inst.AWREADY),
        .AWADDR   (axi_if_inst.AWADDR),

        .WVALID   (axi_if_inst.WVALID),
        .WREADY   (axi_if_inst.WREADY),
        .WDATA    (axi_if_inst.WDATA),

        .BVALID   (axi_if_inst.BVALID),
        .BREADY   (axi_if_inst.BREADY),
        .BRESP    (axi_if_inst.BRESP),

        .ARVALID  (axi_if_inst.ARVALID),
        .ARREADY  (axi_if_inst.ARREADY),
        .ARADDR   (axi_if_inst.ARADDR),

        .RVALID   (axi_if_inst.RVALID),
        .RREADY   (axi_if_inst.RREADY),
        .RDATA    (axi_if_inst.RDATA),
        .RRESP    (axi_if_inst.RRESP)
    );

    // ------------------------------------------------------------------------
    // Mailbox + ENV Components
    // ------------------------------------------------------------------------
    mailbox #(axi_transaction) mon_mb = new();

    axi_driver     drv;
    axi_monitor    mon;
    axi_scoreboard scb;

    // ------------------------------------------------------------------------
    // Environment Bring-Up
    // ------------------------------------------------------------------------
    initial begin
        drv = new(axi_if_inst.DRIVER);
        mon = new(axi_if_inst.MONITOR, mon_mb);
        scb = new(mon_mb);

        // Start monitor + scoreboard
        fork
            mon.run();
            scb.run();
        join_none;
    end

    // ------------------------------------------------------------------------
    // TEST SEQUENCE
    // ------------------------------------------------------------------------
    task drive_txn(input axi_transaction txn);
        drv.drive(txn);
        txn.display("DRV SENT: ");
    endtask

    initial begin
        axi_transaction t;

        wait(ARESETN == 1);
        $display("RESET DONE, STARTING TEST");

        // ------------------------------
        // WRITE: DATA_IN = 0x1234_5678
        // ------------------------------
        t = new();
        t.cmd   = axi_transaction::AXI_WRITE;
        t.addr  = 32'h0000_0008; // DATA_IN
        t.wdata = 32'h1234_5678;
        drive_txn(t);

        // ------------------------------
        // WRITE: CTRL enable
        // ------------------------------
        t = new();
        t.cmd   = axi_transaction::AXI_WRITE;
        t.addr  = 32'h0000_0000; // CTRL
        t.wdata = 32'h1;
        drive_txn(t);

        // ------------------------------
        // READ STATUS
        // ------------------------------
        t = new();
        t.cmd  = axi_transaction::AXI_READ;
        t.addr = 32'h0000_0004;
        drive_txn(t);

        // ------------------------------
        // READ DATA_OUT (expect DATA_IN + 0x10)
        // ------------------------------
        t = new();
        t.cmd  = axi_transaction::AXI_READ;
        t.addr = 32'h0000_000C;
        drive_txn(t);

        // ------------------------------
        // Optional: Random Stress
        // ------------------------------
        repeat(5) begin
            t = new();
            assert(t.randomize());
            drive_txn(t);
        end

        // ------------------------------
        // Finish
        // ------------------------------
        #100;
        $display("TEST COMPLETE");
        $finish;
    end

    // ------------------------------------------------------------------------
    // Wave Dump (Optional — Questa supports VCD too)
    // ------------------------------------------------------------------------
    initial begin
        $dumpfile("axi_soc.vcd");
        $dumpvars(0, tb);
    end

endmodule
