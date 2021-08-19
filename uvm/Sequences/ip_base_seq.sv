`ifndef IP_BASE_SEQ_SV
 `define IP_BASE_SEQ_SV

`include "seq_item.sv"
import uvm_pkg::*;     
`include "uvm_macros.svh" 

class ip_base_seq extends uvm_sequence#(ip_seq_item);

   `uvm_object_utils(ip_base_seq)
   `uvm_declare_p_sequencer(ip_sequencer)

   function new(string name = "ip_base_seq");
      super.new(name);
   endfunction

   // objections are raised in pre_body
   virtual task pre_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.raise_objection(this, {"Running sequence '", get_full_name(), "'"});
   endtask : pre_body

   // objections are dropped in post_body
   virtual task post_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.drop_objection(this, {"Completed sequence '", get_full_name(), "'"});
   endtask : post_body

endclass : ip_base_seq

`endif