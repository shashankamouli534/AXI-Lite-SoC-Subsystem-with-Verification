class axi_env;

    virtual axi_if vif;

    axi_agent      agent;
    axi_scoreboard scb;

    function new(virtual axi_if vif);
        this.vif = vif;

        agent = new(vif);
        scb   = new(agent.mon_mb);
    endfunction

    task start();
        agent.start();
        fork
            scb.run();
        join_none
    endtask

    task send(axi_transaction t);
        agent.drv.drive(t);
    endtask

endclass
