class axi_driver;

    virtual axi_if.DRIVER vif;

    function new(virtual axi_if.DRIVER vif);
        this.vif = vif;
    endfunction

    task reset();
        vif.drv_cb.AWVALID <= 0;
        vif.drv_cb.WVALID  <= 0;
        vif.drv_cb.BREADY  <= 0;
        vif.drv_cb.ARVALID <= 0;
        vif.drv_cb.RREADY  <= 0;
        wait(vif.ARESETN);
    endtask

    task drive(axi_transaction txn);
        if(txn.cmd == axi_transaction::AXI_WRITE)
            drive_write(txn);
        else
            drive_read(txn);
    endtask

    task drive_write(axi_transaction txn);

        vif.drv_cb.AWADDR  <= txn.addr;
        vif.drv_cb.WDATA   <= txn.wdata;
        vif.drv_cb.AWVALID <= 1;
        vif.drv_cb.WVALID  <= 1;

        fork
            begin
                wait(vif.drv_cb.AWREADY);
                @(vif.drv_cb);
                vif.drv_cb.AWVALID <= 0;
            end
            begin
                wait(vif.drv_cb.WREADY);
                @(vif.drv_cb);
                vif.drv_cb.WVALID <= 0;
            end
        join

        vif.drv_cb.BREADY <= 1;
        wait(vif.drv_cb.BVALID);
        txn.resp = vif.drv_cb.BRESP;
        @(vif.drv_cb);
        vif.drv_cb.BREADY <= 0;

    endtask

    task drive_read(axi_transaction txn);

        vif.drv_cb.ARADDR  <= txn.addr;
        vif.drv_cb.ARVALID <= 1;

        wait(vif.drv_cb.ARREADY);
        @(vif.drv_cb);
        vif.drv_cb.ARVALID <= 0;

        vif.drv_cb.RREADY <= 1;
        wait(vif.drv_cb.RVALID);
        txn.rdata = vif.drv_cb.RDATA;
        txn.resp  = vif.drv_cb.RRESP;
        @(vif.drv_cb);
        vif.drv_cb.RREADY <= 0;

    endtask

endclass
