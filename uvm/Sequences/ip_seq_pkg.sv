`ifndef IP_SEQ_PKG_SV
 `define IP_SEQ_PKG_SV
 
 package ip_seq_pkg;

   import uvm_pkg::*;      // import the UVM library
    `include "uvm_macros.svh" // Include the UVM macros

 `include "seq_item.sv"
 `include "ip_sequencer.sv"
 `include "ip_base_seq.sv"
 `include "sequence1.sv"
 `include "agent.sv"

endpackage 
     
`endif