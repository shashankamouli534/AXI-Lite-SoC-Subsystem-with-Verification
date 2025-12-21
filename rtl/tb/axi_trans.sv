// ============================================================================
// axi_transaction.sv
// Transaction object for AXI4-Lite
// Used by driver, monitor, scoreboard
// ============================================================================

class axi_transaction;

    // ------------------------------------------------------------------------
    // Transaction type
    // ------------------------------------------------------------------------
    typedef enum logic {
        AXI_READ,
        AXI_WRITE
    } axi_cmd_t;

    // ------------------------------------------------------------------------
    // Fields
    // ------------------------------------------------------------------------
    rand axi_cmd_t        cmd;
    rand logic [31:0]     addr;
    rand logic [31:0]     wdata;

         logic [31:0]     rdata;
         logic [1:0]      resp;

    // ------------------------------------------------------------------------
    // Constraints
    // ------------------------------------------------------------------------
    constraint addr_align_c {
        addr[1:0] == 2'b00; // word aligned
    }

    // Optional: constrain address range later
    // constraint addr_range_c {
    //     addr inside {32'h0, 32'h4, 32'h8, 32'hC};
    // }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function new();
        cmd   = AXI_READ;
        addr  = '0;
        wdata = '0;
        rdata = '0;
        resp  = 2'b00;
    endfunction

    // ------------------------------------------------------------------------
    // Utility methods
    // ------------------------------------------------------------------------
    function bit is_read();
        return (cmd == AXI_READ);
    endfunction

    function bit is_write();
        return (cmd == AXI_WRITE);
    endfunction

    function void display(string prefix = "");
        $display("%sAXI_TXN | cmd=%s addr=0x%08h wdata=0x%08h rdata=0x%08h resp=0x%0h",
                 prefix,
                 (cmd == AXI_READ) ? "READ " : "WRITE",
                 addr, wdata, rdata, resp);
    endfunction

endclass
