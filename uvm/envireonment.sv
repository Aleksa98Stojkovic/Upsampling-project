`ifndef IP_ENV_SV
 `define IP_ENV_SV

    `include "agent.sv"   
    `include "scoreboard.sv"   
    `include "coverage_collector.sv"   
    
class ip_env extends uvm_env;

    ip_agent agent;
    ip_scoreboard sb;
    ip_cov_col cc;
    ip_config cfg;
    virtual interface ip_if  vif;

   `uvm_component_utils (ip_env)

   function new(string name = "ip_env", uvm_component parent = null);
       super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       /************Geting from configuration database*******************/
       if (!uvm_config_db#(virtual ip_if)::get(this, "", "ip_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
       
       if(!uvm_config_db#(ip_config)::get(this, "", "ip_config", cfg))
         `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
       /*****************************************************************/


       /************Setting to configuration database********************/
       uvm_config_db#(ip_config)::set(this, "*agent", "ip_config", cfg);
       uvm_config_db#(virtual ip_if)::set(this, "if_agent", "ip_if", vif);
       
       uvm_config_db#(ip_config)::set(this, "sb", "ip_config", cfg);
       uvm_config_db#(virtual ip_if)::set(this, "if_scoreboard", "ip_if", vif);
             
       uvm_config_db#(ip_config)::set(this, "cc", "ip_config", cfg);
       uvm_config_db#(virtual ip_if)::set(this, "if_cov_col", "ip_if", vif);
       /*****************************************************************/
       agent = ip_agent::type_id::create("if_agent", this);
       sb = ip_scoreboard::type_id::create("if_scoreboard", this);
       cc = ip_cov_col::type_id::create("if_cov_col", this);
   endfunction : build_phase
   
   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       agent.mon.scoreboard_port.connect(sb.item_collected_imp);
       agent.mon.coverage_port.connect(cc.cc_item_collected_port);  
   endfunction : connect_phase

endclass : ip_env

`endif