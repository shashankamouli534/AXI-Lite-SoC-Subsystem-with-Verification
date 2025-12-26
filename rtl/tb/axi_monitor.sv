class axi_monitor;

    virtual axi_if.MONITOR vif;
    mailbox #(axi_transaction) mon_mb;

    function new(virtual axi_if.MONITOR vif,
                 mailbox #(axi_transaction) mon_mb);
        this.vif = vif;
        this.mon_mb = mon_mb;
    endfunction

    task run();
        forever begin
            fork
                monitor_write();
                monitor_read();
            join_any
        end
    endtask

    task monitor_write();
        axi_transaction t;

        wait(vif.mon_cb.AWVALID && vif.mon_cb.AWREADY);
        wait(vif.mon_cb.WVALID  && vif.mon_cb.WREADY);

        t = new();
        t.cmd   = axi_transaction::AXI_WRITE;
        t.addr  = vif.mon_cb.AWADDR;
        t.wdata = vif.mon_cb.WDATA;

        wait(vif.mon_cb.BVALID && vif.mon_cb.BREADY);
        t.resp = vif.mon_cb.BRESP;

        mon_mb.put(t);
        t.display("MON WRITE");
    endtask

    task monitor_read();
        axi_transaction t;

        wait(vif.mon_cb.ARVALID && vif.mon_cb.ARREADY);

        t = new();
        t.cmd  = axi_transaction::AXI_READ;
        t.addr = vif.mon_cb.ARADDR;

        wait(vif.mon_cb.RVALID && vif.mon_cb.RREADY);
        t.rdata = vif.mon_cb.RDATA;
        t.resp  = vif.mon_cb.RRESP;

        mon_mb.put(t);
        t.display("MON READ");
    endtask

endclass
