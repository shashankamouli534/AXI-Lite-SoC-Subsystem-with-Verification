module tb;
    import axi_pkg::*;

    logic ACLK;
    logic ARESETN;

    // clock
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end

    // reset
    initial begin
        ARESETN = 0;
        repeat(10) @(posedge ACLK);
        ARESETN = 1;
    end

    // vcd
    initial begin
        $dumpfile("sim_fixed.vcd");
        $dumpvars(0, tb);
    end

    // interface
    axi_if axi(
        .ACLK(ACLK),
        .ARESETN(ARESETN)
    );

    // DUT -- ensure top_soc and other RTL are compiled in same work library
    top_soc dut(
        .ACLK(ACLK), .ARESETN(ARESETN),
        .AWVALID(axi.AWVALID), .AWREADY(axi.AWREADY), .AWADDR(axi.AWADDR),
        .WVALID(axi.WVALID),   .WREADY(axi.WREADY),   .WDATA(axi.WDATA),
        .BVALID(axi.BVALID),   .BREADY(axi.BREADY),   .BRESP(axi.BRESP),
        .ARVALID(axi.ARVALID), .ARREADY(axi.ARREADY), .ARADDR(axi.ARADDR),
        .RVALID(axi.RVALID),   .RREADY(axi.RREADY),   .RDATA(axi.RDATA), .RRESP(axi.RRESP)
    );

    // agent
    axi_agent env;

    // ----------------------------
    // Cycle monitor / debug (prints per clock)
    // ----------------------------
    initial begin
        @(posedge ARESETN);
        $display("TIME    AWV AWR AWADDR      WV WR WDATA       BVAL BRESP  ARV ARR ARADDR     RV RDATA   aw_seen w_seen wr_addr_valid");
        forever @(posedge ACLK) begin
            string wv;
            if ($isunknown(dut.u_axi_slave.wr_addr_valid)) wv = "X";
            else wv = (dut.u_axi_slave.wr_addr_valid ? "V" : "N");

            $display("%0t   %b   %b   %h   %b   %b   %h   %b     %b    %b   %b   %h   %b    %s",
                $time,
                axi.AWVALID, axi.AWREADY, axi.AWADDR,
                axi.WVALID, axi.WREADY, axi.WDATA,
                axi.BVALID, axi.BRESP,
                axi.ARVALID, axi.ARREADY, axi.ARADDR,
                axi.RVALID, axi.RDATA,
                // internals -- these hierarchical refs are okay for debug but brittle
                ( $isunknown(dut.u_axi_slave.aw_seen) ? 1'bx : dut.u_axi_slave.aw_seen ),
                ( $isunknown(dut.u_axi_slave.w_seen)  ? 1'bx : dut.u_axi_slave.w_seen ),
                wv
            );
        end
    end

    // ----------------------------
    // Lightweight assertions (TB-side)
    // ----------------------------
    reg [7:0] resp_wait_cnt;
    reg [7:0] r_wait_cnt;
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            resp_wait_cnt <= 0;
            r_wait_cnt    <= 0;
        end else begin
            if ((dut.u_axi_slave.aw_seen) && (dut.u_axi_slave.w_seen) && !axi.BVALID) begin
                resp_wait_cnt <= resp_wait_cnt + 1;
                if (resp_wait_cnt > 20) begin
                    $error("DBG: aw_seen && w_seen but BVALID not asserted within 20 cycles. aw_seen=%0b w_seen=%0b aw_addr=%h wdata=%h at time=%0t",
                           dut.u_axi_slave.aw_seen, dut.u_axi_slave.w_seen, dut.u_axi_slave.aw_addr, dut.u_axi_slave.wdata, $time);
                    resp_wait_cnt <= 0;
                end
            end else resp_wait_cnt <= 0;

            if (dut.u_axi_slave.rd_en && !axi.RVALID) begin
                r_wait_cnt <= r_wait_cnt + 1;
                if (r_wait_cnt > 20) begin
                    $error("DBG: rd_en asserted but RVALID not asserted in 20 cycles. ar_addr=%h at time=%0t",
                        dut.u_axi_slave.ar_addr, $time);
                    r_wait_cnt <= 0;
                end
            end else r_wait_cnt <= 0;
        end
    end

    // ----------------------------
    // Module-scope helper task: poll STATUS
    // ----------------------------
    task automatic wait_for_idle(input int timeout_cycles = 5000);
        int retry;
        logic [31:0] st;
        axi_transaction rt;
        begin
            retry = 0;
            forever begin
                rt = new();
                rt.cmd = AXI_READ;
                rt.addr = 32'h4;
                env.drv.drive(rt);
                st = rt.rdata;
                if (rt.resp != 0) begin
                    $error("STATUS READ FAILED resp=%0d", rt.resp);
                    disable wait_for_idle;
                end
                if ((st & 32'h1) == 0) begin
                    // idle
                    disable wait_for_idle;
                end
                retry++;
                if (retry > timeout_cycles) begin
                    $error("wait_for_idle TIMEOUT after %0d polls", retry);
                    disable wait_for_idle;
                end
                repeat(2) @(posedge ACLK);
            end
        end
    endtask

    // ----------------------------
    // Test sequence
    // ----------------------------
    initial begin
        axi_transaction t;

        wait(ARESETN);
        env = new(axi);
        env.start();

        $display("====== TEST START ======");

        // write DATA_IN
        t = new(); t.cmd = AXI_WRITE; t.addr = 32'h8; t.wdata = 32'h12345678;
        env.drv.drive(t);

        // pulse ctrl: write 1 then clear to 0
        t = new(); t.cmd = AXI_WRITE; t.addr = 32'h0; t.wdata = 1;
        env.drv.drive(t);
        repeat (1) @(posedge ACLK);
        t = new(); t.cmd = AXI_WRITE; t.addr = 32'h0; t.wdata = 0;
        env.drv.drive(t);

        // poll STATUS until busy==0
        wait_for_idle(5000);

        // read data_out
        t = new(); t.cmd = AXI_READ; t.addr = 32'hC;
        env.drv.drive(t);
        $display("DATA_OUT = %h (RRESP=%0d)", t.rdata, t.resp);

        // random safe accesses
        repeat(5) begin
            t = new();
            assert(t.randomize());
            env.drv.drive(t);
        end

        $display("====== TEST END ======");
        #100 $finish;
    end

    // watchdog
    initial begin
        #200000;
        $error("WATCHDOG TIMEOUT – EXITING");
        $finish;
    end
endmodule
