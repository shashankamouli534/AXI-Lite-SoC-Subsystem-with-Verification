// ============================================================================
// axi_params_pkg.sv
// Common AXI-Lite parameters and constants
// Used by RTL and Testbench
// ============================================================================

package axi_params_pkg;

    // ------------------------------------------------------------------------
    // AXI-Lite basic parameters
    // ------------------------------------------------------------------------
    parameter int AXI_ADDR_WIDTH = 32;
    parameter int AXI_DATA_WIDTH = 32;
    parameter int AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

    // ------------------------------------------------------------------------
    // AXI response encodings (from AMBA spec)
    // ------------------------------------------------------------------------
    typedef enum logic [1:0] {
        AXI_RESP_OKAY   = 2'b00,
        AXI_RESP_EXOKAY = 2'b01, // not used in AXI-Lite, kept for completeness
        AXI_RESP_SLVERR = 2'b10,
        AXI_RESP_DECERR = 2'b11
    } axi_resp_t;

    // ------------------------------------------------------------------------
    // Register map offsets (byte offsets)
    // ------------------------------------------------------------------------
    parameter logic [AXI_ADDR_WIDTH-1:0] REG_CTRL_OFFSET     = 32'h0000_0000;
    parameter logic [AXI_ADDR_WIDTH-1:0] REG_STATUS_OFFSET   = 32'h0000_0004;
    parameter logic [AXI_ADDR_WIDTH-1:0] REG_DATA_IN_OFFSET  = 32'h0000_0008;
    parameter logic [AXI_ADDR_WIDTH-1:0] REG_DATA_OUT_OFFSET = 32'h0000_000C;

    // ------------------------------------------------------------------------
    // CTRL register bit definitions
    // ------------------------------------------------------------------------
    parameter int CTRL_ENABLE_BIT = 0;

    // ------------------------------------------------------------------------
    // STATUS register bit definitions
    // ------------------------------------------------------------------------
    parameter int STATUS_BUSY_BIT = 0;

    // ------------------------------------------------------------------------
    // Utility localparams
    // ------------------------------------------------------------------------
    localparam int WORD_ADDR_LSB = 2; // for 32-bit word alignment

endpackage
