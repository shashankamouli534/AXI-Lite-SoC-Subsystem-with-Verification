class axi_transaction;

    typedef enum logic { AXI_READ, AXI_WRITE } axi_cmd_t;

    rand axi_cmd_t cmd;
    rand logic [31:0] addr;
    rand logic [31:0] wdata;

         logic [31:0] rdata;
         logic [1:0]  resp;

    constraint aligned { addr[1:0] == 2'b00; }

    function new();
        cmd = AXI_READ;
        addr = 0;
        wdata = 0;
        rdata = 0;
        resp = 0;
    endfunction

    function void display(string tag="");
        $display("%0t %s CMD=%s ADDR=%h WDATA=%h RDATA=%h RESP=%0d",
            $time, tag,
            (cmd==AXI_WRITE)?"WRITE":"READ",
            addr, wdata, rdata, resp);
    endfunction
endclass
