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
