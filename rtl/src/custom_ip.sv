// ============================================================================
// custom_ip.sv
// Simple register-controlled IP
// - Start via ctrl_enable
// - Busy for FIXED latency
// - Produces deterministic output
// ============================================================================

module custom_ip #(
    parameter DATA_WIDTH = 32,
    parameter LATENCY    = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  ctrl_enable,
    input  logic [DATA_WIDTH-1:0] data_in,

    output logic                  status_busy,
    output logic [DATA_WIDTH-1:0] data_out
);

    logic [$clog2(LATENCY+1)-1:0] cnt;
    logic                         active;

    // ------------------------------------------------------------------------
    // Control FSM (very simple)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt         <= '0;
            active      <= 1'b0;
            status_busy <= 1'b0;
            data_out    <= '0;
        end else begin
            // Start condition
            if (ctrl_enable && !active) begin
                active      <= 1'b1;
                status_busy <= 1'b1;
                cnt         <= '0;
            end

            // Operation in progress
            if (active) begin
                cnt <= cnt + 1'b1;

                if (cnt == LATENCY-1) begin
                    // Finish operation
                    active      <= 1'b0;
                    status_busy <= 1'b0;

                    // Example computation
                    data_out <= data_in + 32'h10;
                end
            end
        end
    end

endmodule
