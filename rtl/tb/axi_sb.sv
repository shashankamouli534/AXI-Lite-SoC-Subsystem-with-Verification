class axi_scoreboard;

    mailbox #(axi_transaction) mon_mb;

    logic ctrl_enable;
    logic status_busy;
    logic [31:0] data_in;
    logic [31:0] data_out;

    function new(mailbox #(axi_transaction) mon_mb);
        this.mon_mb = mon_mb;
    endfunction

    task run();
        axi_transaction t;
        forever begin
            mon_mb.get(t);
            if(t.cmd == axi_transaction::AXI_WRITE)
                check_write(t);
            else
                check_read(t);
        end
    endtask

    task check_write(axi_transaction t);
        if(t.resp != 0)
            $error("WRITE FAILED");
        case(t.addr)
            32'h0: ctrl_enable = t.wdata[0];
            32'h8: data_in = t.wdata;
        endcase
        if(ctrl_enable) begin
            status_busy = 1;
            data_out = data_in + 32'h10;
            status_busy = 0;
        end
    endtask

    task check_read(axi_transaction t);
        logic [31:0] exp;
        case(t.addr)
            32'h0: exp = {31'b0, ctrl_enable};
            32'h4: exp = {31'b0, status_busy};
            32'h8: exp = data_in;
            32'hC: exp = data_out;
            default: exp = 32'hDEAD_BEEF;
        endcase

        if(t.rdata !== exp)
            $error("READ MISMATCH exp=%h got=%h", exp, t.rdata);
        else
            $display("READ OK %h", t.rdata);
    endtask

endclass
