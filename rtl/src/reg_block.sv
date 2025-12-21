// =============================================================
// reg_block.sv
// Register storage + semantics (AXI-agnostic)
// =============================================================
module reg_block (
    input  logic        clk,
    input  logic        rst_n,

    // write side
    input  logic        wr_en,
    input  logic [31:0] wdata,
    input  logic        wr_sel_ctrl,
    input  logic        wr_sel_data_in,

    // read side
    input  logic        rd_en,
    input  logic        rd_sel_ctrl,
    input  logic        rd_sel_status,
    input  logic        rd_sel_data_in,
    input  logic        rd_sel_data_out,

    // inputs from custom IP
    input  logic        status_busy,
    input  logic [31:0] ip_data_out,

    // outputs to bus
    output logic [31:0] rdata,

    // outputs to custom IP
    output logic        ctrl_enable,
    output logic [31:0] data_in
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_enable <= 1'b0;
            data_in     <= 32'b0;
        end else if (wr_en) begin
            if (wr_sel_ctrl)
                ctrl_enable <= wdata[0];

            if (wr_sel_data_in)
                data_in <= wdata;
        end
    end
    always_comb begin
        rdata = 32'b0;

        if (rd_en) begin
            unique case (1'b1)
                rd_sel_ctrl:
                    rdata = {31'b0, ctrl_enable};

                rd_sel_status:
                    rdata = {31'b0, status_busy};

                rd_sel_data_in:
                    rdata = data_in;

                rd_sel_data_out:
                    rdata = ip_data_out;

                default:
                    rdata = 32'hDEADBEEF; // visible invalid read
            endcase
        end
    end

endmodule
