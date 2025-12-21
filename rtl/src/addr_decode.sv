// =============================================================
// addr_decode.sv
// Word-aligned register decode for AXI-Lite
// =============================================================
module addr_decode (
    input  logic [31:0] addr,

    output logic        sel_ctrl,
    output logic        sel_status,
    output logic        sel_data_in,
    output logic        sel_data_out,
    output logic        addr_valid
);

    always_comb begin
        // defaults
        sel_ctrl     = 1'b0;
        sel_status   = 1'b0;
        sel_data_in  = 1'b0;
        sel_data_out = 1'b0;
        addr_valid   = 1'b1;

        // reject unaligned accesses
        if (addr[1:0] != 2'b00) begin
            addr_valid = 1'b0;
        end else begin
            // word decode
            case (addr[5:2])
                4'h0: sel_ctrl     = 1'b1; // 0x00
                4'h1: sel_status   = 1'b1; // 0x04
                4'h2: sel_data_in  = 1'b1; // 0x08
                4'h3: sel_data_out = 1'b1; // 0x0C
                default: addr_valid = 1'b0;
            endcase
        end
    end

endmodule
