`ifndef IP_SEQUENCER_SV
 `define IP_SEQUENCER_SV

`include "seq_item.sv"
import uvm_pkg::*;     
`include "uvm_macros.svh" 

class ip_sequencer extends uvm_sequencer#(ip_seq_item);

   `uvm_component_utils(ip_sequencer)

   function new(string name = "ip_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction

endclass : ip_sequencer

`endif