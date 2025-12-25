`timescale 1ns/1ps

class axi_transaction;
    axi_cmd_e cmd;
    bit [31:0] addr;
    bit [31:0] wdata;
    bit [31:0] rdata;
    bit [1:0]  resp;

    function void display(string tag="");
        $display("%0t %s CMD=%s ADDR=0x%08h WDATA=0x%08h RDATA=0x%08h RESP=%0d",
                 $time,
                 tag,
                 (cmd==AXI_WRITE)?"WRITE":"READ",
                 addr, wdata, rdata, resp);
    endfunction
endclass

interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic ACLK,
    input logic ARESETN
);

    logic                  AWVALID;
    logic                  AWREADY;
    logic [ADDR_WIDTH-1:0] AWADDR;

    logic                  WVALID;
    logic                  WREADY;
    logic [DATA_WIDTH-1:0] WDATA;

    logic                  BVALID;
    logic                  BREADY;
    logic [1:0]            BRESP;

    logic                  ARVALID;
    logic                  ARREADY;
    logic [ADDR_WIDTH-1:0] ARADDR;

    logic                  RVALID;
    logic                  RREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;

    // DRIVER
    clocking drv_cb @(posedge ACLK);
        default input #1step output #1step;

        output AWVALID, AWADDR; input AWREADY;
        output WVALID,  WDATA;  input WREADY;

        input  BVALID, BRESP; output BREADY;

        output ARVALID, ARADDR; input ARREADY;

        input  RVALID,  RDATA, RRESP; output RREADY;
    endclocking

    // MONITOR
    clocking mon_cb @(posedge ACLK);
        default input #1step;

        input AWVALID, AWREADY, AWADDR;
        input WVALID,  WREADY,  WDATA;
        input BVALID,  BREADY,  BRESP;
        input ARVALID, ARREADY, ARADDR;
        input RVALID,  RREADY,  RDATA, RRESP;
    endclocking

    modport DRIVER  (clocking drv_cb, input ARESETN);
    modport MONITOR (clocking mon_cb, input ARESETN);
    modport DUT (
        input  ACLK, ARESETN,

        input  AWVALID, AWADDR,
        output AWREADY,

        input  WVALID,  WDATA,
        output WREADY,

        output BVALID,  BRESP,
        input  BREADY,

        input  ARVALID, ARADDR,
        output ARREADY,

        output RVALID,  RDATA, RRESP,
        input  RREADY
    );

endinterface

class axi_monitor;

    virtual interface axi_if.MONITOR vif;
    mailbox #(axi_transaction) mon_mb;

    function new(virtual interface axi_if.MONITOR vif,
                 mailbox #(axi_transaction) mon_mb);
        this.vif    = vif;
        this.mon_mb = mon_mb;
    endfunction

    task run();
        forever begin
            fork
                monitor_write();
                monitor_read();
            join_any
        end
    endtask

    task monitor_write();
        axi_transaction txn;

        wait (vif.mon_cb.AWVALID && vif.mon_cb.AWREADY);
        wait (vif.mon_cb.WVALID  && vif.mon_cb.WREADY);

        txn = new();
        txn.cmd   = AXI_WRITE;
        txn.addr  = vif.mon_cb.AWADDR;
        txn.wdata = vif.mon_cb.WDATA;

        wait (vif.mon_cb.BVALID && vif.mon_cb.BREADY);
        txn.resp = vif.mon_cb.BRESP;

        mon_mb.put(txn);
        txn.display("MON WRITE:");
    endtask

    task monitor_read();
        axi_transaction txn;

        wait (vif.mon_cb.ARVALID && vif.mon_cb.ARREADY);

        txn = new();
        txn.cmd  = AXI_READ;
        txn.addr = vif.mon_cb.ARADDR;

        wait (vif.mon_cb.RVALID && vif.mon_cb.RREADY);
        txn.rdata = vif.mon_cb.RDATA;
        txn.resp  = vif.mon_cb.RRESP;

        mon_mb.put(txn);
        txn.display("MON READ:");
    endtask

endclass

class axi_driver;

    virtual interface axi_if.DRIVER vif;

    function new(virtual interface axi_if.DRIVER vif);
        this.vif = vif;
    endfunction

    task reset_drive();
        vif.drv_cb.AWVALID <= 0;
        vif.drv_cb.WVALID  <= 0;
        vif.drv_cb.BREADY  <= 0;
        vif.drv_cb.ARVALID <= 0;
        vif.drv_cb.RREADY  <= 0;
        @(posedge vif.ARESETN);
    endtask

    task write(input bit [31:0] addr, input bit [32:0] data);
        @(vif.drv_cb);
        vif.drv_cb.AWADDR  <= addr;
        vif.drv_cb.WDATA   <= data;
        vif.drv_cb.AWVALID <= 1;
        vif.drv_cb.WVALID  <= 1;

        wait(vif.drv_cb.AWREADY && vif.drv_cb.WREADY);
        @(vif.drv_cb);
        vif.drv_cb.AWVALID <= 0;
        vif.drv_cb.WVALID  <= 0;

        vif.drv_cb.BREADY <= 1;
        wait(vif.drv_cb.BVALID);
        @(vif.drv_cb);
        vif.drv_cb.BREADY <= 0;
    endtask

    task read(input bit [31:0] addr);
        @(vif.drv_cb);
        vif.drv_cb.ARADDR  <= addr;
        vif.drv_cb.ARVALID <= 1;

        wait(vif.drv_cb.ARREADY);
        @(vif.drv_cb);
        vif.drv_cb.ARVALID <= 0;

        vif.drv_cb.RREADY <= 1;
        wait(vif.drv_cb.RVALID);
        @(vif.drv_cb);
        vif.drv_cb.RREADY <= 0;
    endtask

endclass

module dut_dummy(axi_if.DUT axi);

    logic [31:0] mem [0:255];

    // Write
    always @(posedge axi.ACLK) begin
        if(!axi.ARESETN) begin
            axi.AWREADY <= 0;
            axi.WREADY  <= 0;
            axi.BVALID  <= 0;
            axi.BRESP   <= 0;
        end
        else begin
            axi.AWREADY <= axi.AWVALID;
            axi.WREADY  <= axi.WVALID;

            if(axi.AWVALID && axi.WVALID) begin
                mem[axi.AWADDR] <= axi.WDATA;
                axi.BVALID <= 1;
                axi.BRESP  <= 0;
            end
            else if(axi.BREADY)
                axi.BVALID <= 0;
        end
    end

    // Read
    always @(posedge axi.ACLK) begin
        if(!axi.ARESETN) begin
            axi.ARREADY <= 0;
            axi.RVALID  <= 0;
            axi.RRESP   <= 0;
            axi.RDATA   <= 0;
        end
        else begin
            axi.ARREADY <= axi.ARVALID;

            if(axi.ARVALID) begin
                axi.RDATA  <= mem[axi.ARADDR];
                axi.RVALID <= 1;
                axi.RRESP  <= 0;
            end
            else if(axi.RREADY)
                axi.RVALID <= 0;
        end
    end

endmodule

module testbench;

    logic ACLK;
    logic ARESETN;

    always #5 ACLK = ~ACLK;

    axi_if axi_if_i(.ACLK(ACLK), .ARESETN(ARESETN));

    dut_dummy dut(.axi(axi_if_i));

    mailbox #(axi_transaction) mon_mb = new();

    axi_monitor mon;
    axi_driver  drv;

    initial begin
        ACLK = 0;
        ARESETN = 0;
        repeat(5) @(posedge ACLK);
        ARESETN = 1;
    end

    initial begin
        drv = new(axi_if_i.DRIVER);
        mon = new(axi_if_i.MONITOR, mon_mb);

        drv.reset_drive();

        fork
            mon.run();
        join_none

        drv.write(32'h10, 32'hAAAA_BBBB);
        drv.read (32'h10);

        repeat(10) @(posedge ACLK);
        $finish;
    end

endmodule
