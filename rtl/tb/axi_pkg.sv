package axi_pkg;
    typedef enum { AXI_READ, AXI_WRITE } axi_cmd_t;

    class axi_transaction;
        rand axi_cmd_t cmd;
        rand logic [31:0] addr;
        rand logic [31:0] wdata;

        logic [31:0] rdata;
        logic [1:0]  resp;

        constraint aligned { addr[1:0] == 2'b00; }

        function new();
            cmd   = AXI_READ;
            addr  = 0;
            wdata = 0;
            rdata = 0;
            resp  = 0;
        endfunction
    endclass


    // ================= DRIVER =================
    class axi_driver;
        virtual axi_if vif; // full interface handle

        // make driver tolerant while debugging
        localparam int NEW_TIMEOUT = 2000;

        function new(virtual axi_if vif);
            this.vif = vif;
        endfunction

        task reset();
            vif.drv_cb.AWVALID <= 0;
            vif.drv_cb.WVALID  <= 0;
            vif.drv_cb.BREADY  <= 0;
            vif.drv_cb.ARVALID <= 0;
            vif.drv_cb.RREADY  <= 0;
            wait(vif.ARESETN);
            repeat(3) @(vif.drv_cb);
        endtask

        task drive(axi_transaction t);
            if (t.cmd == AXI_WRITE)
                drive_write(t);
            else
                drive_read(t);
        endtask

        // -------- WRITE (AW then W then wait for B) --------
        task drive_write(axi_transaction t);
            int timeout;

            // AW channel: assert VALID and give DUT one posedge to sample
            vif.drv_cb.AWADDR  <= t.addr;
            vif.drv_cb.AWVALID <= 1;
            @(vif.drv_cb);

            timeout = 0;
            while (!vif.drv_cb.AWREADY && timeout < NEW_TIMEOUT) begin
                @(vif.drv_cb); timeout++;
            end
            if (timeout >= NEW_TIMEOUT) begin
                $error("AXI AW TIMEOUT @ %h", t.addr);
            end
            vif.drv_cb.AWVALID <= 0;

            // W channel
            vif.drv_cb.WDATA  <= t.wdata;
            vif.drv_cb.WVALID <= 1;
            @(vif.drv_cb);

            timeout = 0;
            while (!vif.drv_cb.WREADY && timeout < NEW_TIMEOUT) begin
                @(vif.drv_cb); timeout++;
            end
            if (timeout >= NEW_TIMEOUT) begin
                $error("AXI W TIMEOUT @ %h", t.addr);
            end
            vif.drv_cb.WVALID <= 0;

            // wait for write response
            vif.drv_cb.BREADY <= 1;
            timeout = 0;
            while (!vif.drv_cb.BVALID && timeout < NEW_TIMEOUT) begin
                @(vif.drv_cb); timeout++;
            end
            if (timeout >= NEW_TIMEOUT) begin
                $error("AXI WRITE RESP TIMEOUT @ %h", t.addr);
            end
            t.resp = vif.drv_cb.BRESP;
            vif.drv_cb.BREADY <= 0;
        endtask

        // -------- READ (AR then wait for R) --------
        task drive_read(axi_transaction t);
            int timeout;

            vif.drv_cb.ARADDR  <= t.addr;
            vif.drv_cb.ARVALID <= 1;
            @(vif.drv_cb);

            timeout = 0;
            while (!vif.drv_cb.ARREADY && timeout < NEW_TIMEOUT) begin
                @(vif.drv_cb); timeout++;
            end
            if (timeout >= NEW_TIMEOUT) begin
                $error("AXI AR TIMEOUT @ %h", t.addr);
            end
            vif.drv_cb.ARVALID <= 0;

            vif.drv_cb.RREADY <= 1;
            timeout = 0;
            while (!vif.drv_cb.RVALID && timeout < NEW_TIMEOUT) begin
                @(vif.drv_cb); timeout++;
            end
            if (timeout >= NEW_TIMEOUT) begin
                $error("AXI READ TIMEOUT @ %h", t.addr);
            end

            t.rdata = vif.drv_cb.RDATA;
            t.resp  = vif.drv_cb.RRESP;
            vif.drv_cb.RREADY <= 0;
        endtask
    endclass


    // ================= MONITOR =================
    class axi_monitor;
        virtual axi_if vif;

        function new(virtual axi_if vif);
            this.vif = vif;
        endfunction

        task run();
            forever begin
                @(vif.mon_cb);
                if (vif.mon_cb.BVALID)
                    $display("[MON] BVALID=%0b BRESP=%0d time=%0t", vif.mon_cb.BVALID, vif.mon_cb.BRESP, $time);
                if (vif.mon_cb.RVALID)
                    $display("[MON] RVALID RDATA=%h RRESP=%0d time=%0t", vif.mon_cb.RDATA, vif.mon_cb.RRESP, $time);
            end
        endtask
    endclass


    // ================= AGENT =================
    class axi_agent;
        virtual axi_if vif;

        axi_driver  drv;
        axi_monitor mon;

        function new(virtual axi_if vif);
            this.vif = vif;
            drv = new(vif);
            mon = new(vif);
        endfunction

        task start();
            drv.reset();
            fork
                mon.run();
            join_none
        endtask
    endclass
endpackage
