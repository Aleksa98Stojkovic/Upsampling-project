`ifndef IP_TEST_PKG_SV
 `define IP_TEST_PKG_SV

package ip_test_pkg;

    import uvm_pkg::*;      // import the UVM library   
    `include "uvm_macros.svh"   // Include the UVM macros

    `include "ip_config.sv"

    import ip_seq_pkg::*;
    import ip_config_pkg::*;
    
    //include tests:
    `include "envireonment.sv"
    `include "scoreboard.sv"
    `include "test_base.sv"
    `include "ip_test1.sv"

endpackage : ip_test_pkg

`endif