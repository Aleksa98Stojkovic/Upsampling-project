`ifndef IP_SEQ_ITEM_SV
 `define IP_SEQ_ITEM_SV

parameter CONFIG_WIDTH = 32;
parameter DATA_WIDTH = 64;
parameter ADDRESS_WIDTH = 32;

class ip_seq_item extends uvm_sequence_item;

  static bit [DATA_WIDTH - 1 : 0]  memory_space[0:14911]; //0-1599: ifm, 1600-10815: weights. After first randomization disable with rand_mode(0)
  static bit [DATA_WIDTH - 1 : 0]  result[0:4095];       //expected results stored here   
  
  //inputs to dut:
   bit [CONFIG_WIDTH - 1 : 0]        config1 = 1600*8;
   bit [CONFIG_WIDTH - 1 : 0]        config2 = 10815*8;
   rand bit [CONFIG_WIDTH - 1 : 0]   config3;
   rand bit [CONFIG_WIDTH - 1 : 0]   config4;
   rand bit [CONFIG_WIDTH - 1 : 0]   config5;
   bit      [DATA_WIDTH - 1 : 0]     axi_read_data = 0;
   bit                               axi_read_last = 0;
   rand bit                          axi_read_valid;    //constraint in a way that not too many 0s occur in series to speed up simulation
   bit                               axi_write_done = 0;
   rand bit                          axi_write_next;    //constraint in a way that not too many 0s occur in series to speed up simulation
   //outputs from dut (used for monitoring):
   bit [CONFIG_WIDTH - 1 : 0]        config6;
   bit [ADDRESS_WIDTH - 1 : 0]       axi_read_address;
   bit [ADDRESS_WIDTH - 1 : 0]       axi_write_address;
   bit                               axi_read_init;
   bit                               axi_read_ready;
   bit                               axi_write_init;
   bit [DATA_WIDTH - 1 : 0]          axi_write_data;
   
//constraints
   //constraint 

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
   `uvm_object_utils_end

   function new (string name = "ip_seq_item");
      super.new(name);
   endfunction // new

endclass : ip_seq_item

`endif