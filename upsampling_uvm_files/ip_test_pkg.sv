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
    `include "ip_test2.sv"
    `include "ip_test3.sv"
    `include "ip_test4.sv"
    `include "ip_test5.sv"
    `include "ip_test6_noReLu.sv"
    `include "ip_test7_noReLu.sv"
    `include "ip_test8_noReLu.sv"
    `include "ip_test9_noReLu.sv"
    `include "ip_test10_noReLu.sv"

endpackage : ip_test_pkg

`endif