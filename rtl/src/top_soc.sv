// ============================================================================
// top_soc.sv
// Top-level SoC wrapper
// - AXI-Lite slave
// - Register block
// - Custom IP
// ============================================================================

module top_soc #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  ACLK,
    input  logic                  ARESETN,

    // ---------------- AXI-Lite Interface ----------------
    input  logic                  AWVALID,
    output logic                  AWREADY,
    input  logic [ADDR_WIDTH-1:0] AWADDR,

    input  logic                  WVALID,
    output logic                  WREADY,
    input  logic [DATA_WIDTH-1:0] WDATA,

    output logic                  BVALID,
    input  logic                  BREADY,
    output logic [1:0]            BRESP,

    input  logic                  ARVALID,
    output logic                  ARREADY,
    input  logic [ADDR_WIDTH-1:0] ARADDR,

    output logic                  RVALID,
    input  logic                  RREADY,
    output logic [DATA_WIDTH-1:0] RDATA,
    output logic [1:0]            RRESP
);

    // ------------------------------------------------------------------------
    // Internal connections
    // ------------------------------------------------------------------------
    logic        ctrl_enable;
    logic [31:0] data_in;
    logic        status_busy;
    logic [31:0] data_out;

    // ------------------------------------------------------------------------
    // AXI-Lite Slave
    // ------------------------------------------------------------------------
    axi_lite_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_axi_slave (
        .ACLK       (ACLK),
        .ARESETN    (ARESETN),

        .AWVALID    (AWVALID),
        .AWREADY    (AWREADY),
        .AWADDR     (AWADDR),

        .WVALID     (WVALID),
        .WREADY     (WREADY),
        .WDATA      (WDATA),

        .BVALID     (BVALID),
        .BREADY     (BREADY),
        .BRESP      (BRESP),

        .ARVALID    (ARVALID),
        .ARREADY    (ARREADY),
        .ARADDR     (ARADDR),

        .RVALID     (RVALID),
        .RREADY     (RREADY),
        .RDATA      (RDATA),
        .RRESP      (RRESP),

        .ctrl_enable(ctrl_enable),
        .data_in    (data_in),
        .status_busy(status_busy),
        .data_out   (data_out)
    );


    // ------------------------------------------------------------------------
    // Custom IP
    // ------------------------------------------------------------------------
    custom_ip #(
        .DATA_WIDTH (DATA_WIDTH),
        .LATENCY    (4)
    ) u_custom_ip (
        .clk         (ACLK),
        .rst_n       (ARESETN),
        .ctrl_enable (ctrl_enable),
        .data_in     (data_in),
        .status_busy (status_busy),
        .data_out    (data_out)
    );

    // ------------------------------------------------------------------------
    // NOTE:
    // ctrl_enable, data_in, status_busy, data_out
    // are connected internally through reg_block inside axi_lite_slave
    // ------------------------------------------------------------------------

endmodule
