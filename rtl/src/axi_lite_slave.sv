// ============================================================================
// axi_lite_slave.sv
// Clean, protocol-correct AXI4-Lite slave
// Single outstanding transaction
// ============================================================================

module axi_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  ACLK,
    input  logic                  ARESETN,

    // -------- Connections to Custom IP --------
    output logic                  ctrl_enable,
    output logic [DATA_WIDTH-1:0] data_in,
    input  logic                  status_busy,
    input  logic [DATA_WIDTH-1:0] data_out,

    // ---------------- Write Address Channel ----------------
    input  logic                  AWVALID,
    output logic                  AWREADY,
    input  logic [ADDR_WIDTH-1:0] AWADDR,

    // ---------------- Write Data Channel -------------------
    input  logic                  WVALID,
    output logic                  WREADY,
    input  logic [DATA_WIDTH-1:0] WDATA,

    // ---------------- Write Response Channel ---------------
    output logic                  BVALID,
    input  logic                  BREADY,
    output logic [1:0]            BRESP,

    // ---------------- Read Address Channel -----------------
    input  logic                  ARVALID,
    output logic                  ARREADY,
    input  logic [ADDR_WIDTH-1:0] ARADDR,

    // ---------------- Read Data Channel --------------------
    output logic                  RVALID,
    input  logic                  RREADY,
    output logic [DATA_WIDTH-1:0] RDATA,
    output logic [1:0]            RRESP
);

    // =========================================================================
    // Internal state
    // =========================================================================
    logic [ADDR_WIDTH-1:0] aw_addr;
    logic [ADDR_WIDTH-1:0] ar_addr;
    logic [DATA_WIDTH-1:0] wdata;

    logic aw_seen;
    logic w_seen;

    logic wr_en;
    logic rd_en;

    logic wr_addr_valid;
    logic rd_addr_valid;

    logic [DATA_WIDTH-1:0] reg_rdata;

    // =========================================================================
    // Address decode (write)
    // =========================================================================
    logic wr_sel_ctrl, wr_sel_status, wr_sel_data_in, wr_sel_data_out;

    addr_decode u_wr_decode (
        .addr        (aw_addr),
        .sel_ctrl    (wr_sel_ctrl),
        .sel_status  (wr_sel_status),
        .sel_data_in (wr_sel_data_in),
        .sel_data_out(wr_sel_data_out),
        .addr_valid  (wr_addr_valid)
    );

    // =========================================================================
    // Address decode (read)
    // =========================================================================
    logic rd_sel_ctrl, rd_sel_status, rd_sel_data_in, rd_sel_data_out;

    addr_decode u_rd_decode (
        .addr        (ar_addr),
        .sel_ctrl    (rd_sel_ctrl),
        .sel_status  (rd_sel_status),
        .sel_data_in (rd_sel_data_in),
        .sel_data_out(rd_sel_data_out),
        .addr_valid  (rd_addr_valid)
    );

    // =========================================================================
    // Register block (AXI-agnostic)
    // =========================================================================
    reg_block u_regblock (
        .clk             (ACLK),
        .rst_n           (ARESETN),

        // write side
        .wr_en           (wr_en),
        .wdata           (wdata),
        .wr_sel_ctrl     (wr_sel_ctrl),
        .wr_sel_data_in  (wr_sel_data_in),

        // read side
        .rd_en           (rd_en),
        .rd_sel_ctrl     (rd_sel_ctrl),
        .rd_sel_status   (rd_sel_status),
        .rd_sel_data_in  (rd_sel_data_in),
        .rd_sel_data_out (rd_sel_data_out),

        // custom IP inputs
        .status_busy     (status_busy),
        .ip_data_out     (data_out),

        // outputs
        .rdata           (reg_rdata),
        .ctrl_enable     (ctrl_enable),
        .data_in         (data_in)
    );

    // =========================================================================
    // WRITE CHANNEL
    // =========================================================================
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            AWREADY <= 1'b1;
            WREADY  <= 1'b1;
            BVALID  <= 1'b0;
            BRESP   <= 2'b00;

            aw_seen <= 1'b0;
            w_seen  <= 1'b0;
            wr_en   <= 1'b0;
            aw_addr <= '0;
            wdata   <= '0;
        end else begin
            wr_en <= 1'b0;

            // Ready only when no outstanding response
            AWREADY <= !aw_seen && !BVALID;
            WREADY  <= !w_seen  && !BVALID;

            // Capture write address
            if (AWVALID && AWREADY) begin
                aw_addr <= AWADDR;
                aw_seen <= 1'b1;
            end

            // Capture write data
            if (WVALID && WREADY) begin
                wdata  <= WDATA;
                w_seen <= 1'b1;
            end

            // Execute write when both address and data are present
            if (aw_seen && w_seen && !BVALID) begin
                wr_en  <= 1'b1;
                BVALID <= 1'b1;
                BRESP  <= wr_addr_valid ? 2'b00 : 2'b10; // OKAY / SLVERR
                aw_seen <= 1'b0;
                w_seen  <= 1'b0;
            end

            // Complete write response
            if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end
        end
    end

    // =========================================================================
    // READ CHANNEL
    // =========================================================================
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY <= 1'b1;
            RVALID  <= 1'b0;
            RDATA   <= '0;
            RRESP   <= 2'b00;
            rd_en   <= 1'b0;
            ar_addr <= '0;
        end else begin
            rd_en <= 1'b0;

            // Ready if no outstanding read (or completing one)
            ARREADY <= !RVALID || (RVALID && RREADY);

            // Accept read address
            if (ARVALID && ARREADY) begin
                ar_addr <= ARADDR;
                rd_en   <= 1'b1;
                RVALID  <= 1'b1;
            end

            // Drive read data AFTER address phase
            if (rd_en) begin
                RDATA <= reg_rdata;
                RRESP <= rd_addr_valid ? 2'b00 : 2'b10; // OKAY / SLVERR
            end

            // Complete read transaction
            if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

endmodule
