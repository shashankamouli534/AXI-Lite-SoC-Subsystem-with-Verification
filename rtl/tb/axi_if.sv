interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic ACLK,
    input  logic ARESETN
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

    // ================= DRIVER CLOCKING =================
    clocking drv_cb @(posedge ACLK);
        default input #1step output #1step;
        output AWVALID, AWADDR;
        output WVALID,  WDATA;
        output BREADY;
        output ARVALID, ARADDR;
        output RREADY;

        input  AWREADY, WREADY;
        input  BVALID, BRESP;
        input  ARREADY;
        input  RVALID, RDATA, RRESP;
    endclocking

    // ================= MONITOR CLOCKING =================
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
    modport DUT(
        input  ACLK, ARESETN,
        input  AWVALID, AWADDR, WVALID, WDATA, BREADY,
        input  ARVALID, ARADDR, RREADY,
        output AWREADY, WREADY, BVALID, BRESP,
        output ARREADY, RVALID, RDATA, RRESP
    );
endinterface
