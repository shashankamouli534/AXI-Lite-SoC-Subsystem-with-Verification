// ============================================================================
// axi_if.sv
// AXI4-Lite interface for verification
// Used by driver, monitor, assertions
// ============================================================================

interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic ACLK,
    input logic ARESETN
);

    // ---------------- Write Address Channel ----------------
    logic                  AWVALID;
    logic                  AWREADY;
    logic [ADDR_WIDTH-1:0] AWADDR;

    // ---------------- Write Data Channel -------------------
    logic                  WVALID;
    logic                  WREADY;
    logic [DATA_WIDTH-1:0] WDATA;

    // ---------------- Write Response Channel ---------------
    logic                  BVALID;
    logic                  BREADY;
    logic [1:0]            BRESP;

    // ---------------- Read Address Channel -----------------
    logic                  ARVALID;
    logic                  ARREADY;
    logic [ADDR_WIDTH-1:0] ARADDR;

    // ---------------- Read Data Channel --------------------
    logic                  RVALID;
    logic                  RREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;

    // =========================================================================
    // Clocking block for DRIVER
    // =========================================================================
    clocking drv_cb @(posedge ACLK);
        default input #1step output #1step;

        // Write address
        output AWVALID, AWADDR;
        input  AWREADY;

        // Write data
        output WVALID, WDATA;
        input  WREADY;

        // Write response
        input  BVALID, BRESP;
        output BREADY;

        // Read address
        output ARVALID, ARADDR;
        input  ARREADY;

        // Read data
        input  RVALID, RDATA, RRESP;
        output RREADY;
    endclocking

    // =========================================================================
    // Clocking block for MONITOR
    // =========================================================================
    clocking mon_cb @(posedge ACLK);
        default input #1step;

        // Observe everything
        input AWVALID, AWREADY, AWADDR;
        input WVALID,  WREADY,  WDATA;
        input BVALID,  BREADY,  BRESP;
        input ARVALID, ARREADY, ARADDR;
        input RVALID,  RREADY,  RDATA, RRESP;
    endclocking

    // =========================================================================
    // Modports
    // =========================================================================
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
