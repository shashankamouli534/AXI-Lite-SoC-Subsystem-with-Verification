axi_lite_soc/
├── rtl/                          # Design RTL (NO testbench)
│   ├── axi_lite_slave.sv         # AXI-Lite protocol handling ONLY
│   ├── addr_decode.sv            # Address → one-hot decode
│   ├── reg_block.sv              # Registers + semantics
│   ├── custom_ip.sv              # Simple register-controlled IP
│   ├── top_soc.sv                # RTL integration wrapper
│   │
│   └── pkg/
│       └── axi_params_pkg.sv     # Widths, constants, localparams
│
├── tb/                           # Testbench (transaction-level)
│   ├── axi_if.sv                 # AXI interface + modports
│   ├── axi_transaction.sv        # Read/write transaction class
│   ├── axi_driver.sv             # Drives AXI-Lite bus
│   ├── axi_monitor.sv            # Observes bus → transactions
│   ├── axi_scoreboard.sv         # Expected vs actual checking
│   ├── axi_cov.sv                # Functional coverage
│   ├── axi_assertions.sv         # Protocol SVA (bindable)
│   ├── tb_top.sv                 # Testbench top
│   │
│   └── pkg/
│       └── tb_pkg.sv             # TB typedefs, enums, helpers
│
├── sim/                          # Simulation helpers
│   ├── run.do                    # ModelSim / Questa
│   ├── run.tcl                   # Vivado xsim / generic
│   └── waves.do                  # GTKWave config
