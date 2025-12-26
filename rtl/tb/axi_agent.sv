class axi_agent;

    virtual axi_if vif;

    axi_driver  drv;
    axi_monitor mon;

    mailbox #(axi_transaction) mon_mb;

    function new(virtual axi_if vif);
        this.vif = vif;
        mon_mb = new();

        drv = new(vif.DRIVER);
        mon = new(vif.MONITOR, mon_mb);
    endfunction

    task start();
        drv.reset();
        fork
            mon.run();
        join_none
    endtask

endclass
