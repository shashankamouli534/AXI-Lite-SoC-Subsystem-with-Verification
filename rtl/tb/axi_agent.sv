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
