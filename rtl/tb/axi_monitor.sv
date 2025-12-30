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
