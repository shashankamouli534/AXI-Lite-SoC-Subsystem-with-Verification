`timescale 1ns/1ps

module tb;

logic ACLK;
logic ARESETN;

initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
end

initial begin
    ARESETN = 0;
    repeat(10) @(posedge ACLK);
    ARESETN = 1;
end

axi_if axi(.*);

top_soc dut(
    .ACLK(ACLK), .ARESETN(ARESETN),
    .AWVALID(axi.AWVALID), .AWREADY(axi.AWREADY), .AWADDR(axi.AWADDR),
    .WVALID(axi.WVALID), .WREADY(axi.WREADY), .WDATA(axi.WDATA),
    .BVALID(axi.BVALID), .BREADY(axi.BREADY), .BRESP(axi.BRESP),
    .ARVALID(axi.ARVALID), .ARREADY(axi.ARREADY), .ARADDR(axi.ARADDR),
    .RVALID(axi.RVALID), .RREADY(axi.RREADY), .RDATA(axi.RDATA), .RRESP(axi.RRESP)
);

mailbox #(axi_transaction) mon_mb = new();

axi_driver drv;
axi_monitor mon;
axi_scoreboard scb;

initial begin
    drv = new(axi.DRIVER);
    mon = new(axi.MONITOR, mon_mb);
    scb = new(mon_mb);

    drv.reset();
    fork
        mon.run();
        scb.run();
    join_none
end

task send(input axi_transaction t);
    drv.drive(t);
endtask

initial begin
    axi_transaction t;

    wait(ARESETN);
    $display("TEST START");

    t = new(); t.cmd = axi_transaction::AXI_WRITE; t.addr=32'h8; t.wdata=32'h1234_5678; send(t);
    t = new(); t.cmd = axi_transaction::AXI_WRITE; t.addr=32'h0; t.wdata=1; send(t);
    t = new(); t.cmd = axi_transaction::AXI_READ;  t.addr=32'h4; send(t);
    t = new(); t.cmd = axi_transaction::AXI_READ;  t.addr=32'hC; send(t);

    repeat(10) begin
        t = new();
        assert(t.randomize());
        send(t);
    end

    #100;
    $finish;
end

initial begin
    $dumpfile("axi.vcd");
    $dumpvars(0,tb);
end

endmodule
