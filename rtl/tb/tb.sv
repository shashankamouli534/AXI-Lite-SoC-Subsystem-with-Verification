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

// ================= DUT =================
top_soc dut(
    .ACLK(ACLK), .ARESETN(ARESETN),

    .AWVALID(axi.AWVALID), .AWREADY(axi.AWREADY), .AWADDR(axi.AWADDR),
    .WVALID(axi.WVALID), .WREADY(axi.WREADY), .WDATA(axi.WDATA),
    .BVALID(axi.BVALID), .BREADY(axi.BREADY), .BRESP(axi.BRESP),
    .ARVALID(axi.ARVALID), .ARREADY(axi.ARREADY), .ARADDR(axi.ARADDR),
    .RVALID(axi.RVALID), .RREADY(axi.RREADY), .RDATA(axi.RDATA), .RRESP(axi.RRESP)
);

// ================= ENV =================
axi_env env;

initial begin
    env = new(axi);
    env.start();
end

// ================= TEST =================
task send(input axi_transaction t);
    env.send(t);
endtask

initial begin
    axi_transaction t;
    wait(ARESETN);
    $display("TEST START");

    t = new(); t.cmd=axi_transaction::AXI_WRITE; t.addr=32'h8; t.wdata=32'h1234_5678; send(t);
    t = new(); t.cmd=axi_transaction::AXI_WRITE; t.addr=32'h0; t.wdata=1;              send(t);
    t = new(); t.cmd=axi_transaction::AXI_READ;  t.addr=32'h4;                        send(t);
    t = new(); t.cmd=axi_transaction::AXI_READ;  t.addr=32'hC;                        send(t);

    repeat(10) begin
        t = new();
        assert(t.randomize());
        send(t);
    end

    #100;
    $finish;
end

initial begin
    $dumpfile("axi_env.vcd");
    $dumpvars(0,tb);
end

endmodule
