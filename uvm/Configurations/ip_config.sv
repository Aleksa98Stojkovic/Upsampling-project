`ifndef IP_CONFIG_SV
`define IP_CONFIG_SV

class ip_config extends uvm_object;

   uvm_active_passive_enum is_active = UVM_ACTIVE;
   
   `uvm_object_utils_begin (ip_config)
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
   `uvm_object_utils_end

   function new(string name = "ip_config");
      super.new(name);
   endfunction

endclass : ip_config

`endif 