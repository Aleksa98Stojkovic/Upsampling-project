`ifndef IP_SEQ_ITEM_SV
 `define IP_SEQ_ITEM_SV

parameter CONFIG_WIDTH = 32;
parameter DATA_WIDTH = 64;
parameter ADDRESS_WIDTH = 32;

class ip_seq_item extends uvm_sequence_item;
  
  //inputs to dut:
   bit [CONFIG_WIDTH - 1 : 0]        config1 = 1600*8;
   bit [CONFIG_WIDTH - 1 : 0]        config2 = 10816*8;
   rand bit [CONFIG_WIDTH - 1 : 0]   config3;
   rand bit [CONFIG_WIDTH - 1 : 0]   config4;
   rand bit [CONFIG_WIDTH - 1 : 0]   config5;
   bit      [DATA_WIDTH - 1 : 0]     axi_read_data;
   bit                               axi_read_last = 0;
   rand bit                          axi_read_valid;    
   bit                               axi_write_done = 0;
   rand bit                          axi_write_next;    
   //outputs from dut (used for monitoring):
   bit [CONFIG_WIDTH - 1 : 0]        config6;
   bit [ADDRESS_WIDTH - 1 : 0]       axi_read_address;
   bit [ADDRESS_WIDTH - 1 : 0]       axi_write_address;
   bit                               axi_read_init;
   bit                               axi_read_ready;
   bit                               axi_write_init;
   bit [DATA_WIDTH - 1 : 0]          axi_write_data;
   
//constraints
    //none

   `uvm_object_utils_begin(ip_seq_item)      
      `uvm_field_int(config1, UVM_DEFAULT)
      `uvm_field_int(config2, UVM_DEFAULT)
      `uvm_field_int(config3, UVM_DEFAULT)
      `uvm_field_int(config4, UVM_DEFAULT)
      `uvm_field_int(config5, UVM_DEFAULT)
      `uvm_field_int(axi_write_done, UVM_DEFAULT)
      `uvm_field_int(axi_write_next, UVM_DEFAULT)
      `uvm_field_int(axi_read_data, UVM_DEFAULT)
      `uvm_field_int(axi_read_last, UVM_DEFAULT)
      `uvm_field_int(axi_read_valid, UVM_DEFAULT)
      `uvm_field_int(config6, UVM_DEFAULT)
      `uvm_field_int(axi_read_address, UVM_DEFAULT)
      `uvm_field_int(axi_write_address, UVM_DEFAULT)
      `uvm_field_int(axi_read_init, UVM_DEFAULT)
      `uvm_field_int(axi_read_ready, UVM_DEFAULT)
      `uvm_field_int(axi_write_init, UVM_DEFAULT)
      `uvm_field_int(axi_write_data, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "ip_seq_item");
      super.new(name);
   endfunction // new

endclass : ip_seq_item

`endif