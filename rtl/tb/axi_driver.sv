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
