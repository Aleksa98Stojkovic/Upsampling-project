`ifndef IP_AGENT_SV
`define IP_AGENT_SV

   import uvm_pkg::*;      // import the UVM library   
   
    `include "uvm_macros.svh"   // Include the UVM macros
    `include "ip_seq_pkg.sv"   
    `include "ip_config.sv"   
    `include "monitor.sv"   
    `include "driver.sv"   
    `include "ip_sequencer.sv"
    
    import ip_seq_pkg::*;
    
class ip_agent extends uvm_agent;


    //import ip_config_pkg::*;
        // components
    ip_driver drv;
    ip_sequencer seqr;
    ip_monitor mon;
   virtual interface ip_if vif;
   // configuration
   ip_config cfg;

   `uvm_component_utils_begin(ip_agent)
       `uvm_field_object(cfg, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "ip_agent", uvm_component parent = null);
       super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       /************Getting from configuration database*******************/
       if (!uvm_config_db#(virtual ip_if)::get(this, "", "ip_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
       
       if(!uvm_config_db#(ip_config)::get(this, "", "ip_config", cfg))
         `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
       /*****************************************************************/
       
       /************xcSetting to configuration database********************/
       uvm_config_db#(virtual ip_if)::set(this, "*", "ip_if", vif);
       /*****************************************************************/
       
       mon = ip_monitor::type_id::create("mon", this);
       if(cfg.is_active == UVM_ACTIVE) begin
           drv = ip_driver::type_id::create("drv", this);
           seqr = ip_sequencer::type_id::create("seqr", this);
       end
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if(cfg.is_active == UVM_ACTIVE) begin
           drv.seq_item_port.connect(seqr.seq_item_export);
       end
   endfunction : connect_phase

endclass : ip_agent

`endif 