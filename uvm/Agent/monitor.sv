`ifndef IP_MONITOR_SV
`define IP_MONITOR_SV

`include "ip_seq_pkg.sv"
import ip_seq_pkg::*;

class ip_monitor extends uvm_monitor;
    `include "ip_seq_pkg.sv"   
    `include "seq_item.sv"
    
        `uvm_component_utils(ip_monitor)
    
    uvm_analysis_port #(ip_seq_item) coverage_port;    
    uvm_analysis_port #(ip_seq_item) scoreboard_port;    

   // The virtual interface used to drive and view HDL signals.
   virtual 	interface ip_if vif;
   //string
   string s;
   // current transaction
   ip_seq_item curr_it;

   function new(string name = "ip_monitor", uvm_component parent = null);
       super.new(name,parent);      
       scoreboard_port = new("scoreboard_port", this); 
       coverage_port = new("coverage_port", this);       
   endfunction

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if (!uvm_config_db#(virtual ip_if)::get(this, "", "ip_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction : connect_phase
   
   task main_phase(uvm_phase phase);
       forever begin
	   curr_it = ip_seq_item::type_id::create("curr_it", this);

	   @(posedge vif.clk);
	  
	   // collect transactions
	   curr_it.config1           = vif.config1; 
	   curr_it.config2           = vif.config2; 
	   curr_it.config3           = vif.config3; 
	   curr_it.config4           = vif.config4; 
	   curr_it.config5           = vif.config5; 
	   curr_it.config6           = vif.config6; 
	   curr_it.axi_write_next    = vif.axi_write_next_i;
	   curr_it.axi_write_done    = vif.axi_write_done_i;
	   curr_it.axi_read_valid    = vif.axi_read_valid_i;
	   curr_it.axi_read_last     = vif.axi_read_last_i;
	   curr_it.axi_read_data     = vif.axi_read_data_i;
	   curr_it.axi_write_data    = vif.axi_write_data_o;
	   curr_it.axi_write_init    = vif.axi_write_init_o;
	   curr_it.axi_write_address = vif.axi_write_address_o;
	   curr_it.axi_read_ready    = vif.axi_read_ready_o;
	   curr_it.axi_read_init     = vif.axi_read_init_o;
	   curr_it.axi_read_address  = vif.axi_read_address_o;

	   `uvm_info(get_type_name(), $sformatf("Item collected: \n%s", curr_it.sprint()), UVM_HIGH)
	   
	   //*******write_done and write_next check*******
	   AssrtWrtDn: assert(curr_it.axi_write_done + curr_it.axi_write_next != 2)        //checks that write_done and write_next arent 1 at the same time (if we are done with writing we don't ask for more data)
	   begin
	       s = "\n No conflict of axi_write_done and axi_write_next. \n";
	       `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
	   end
	   else begin
	       s = $sformatf("\n Conflict ! Desc: write operation is done, but we (the driver) are asking for more data, check SEQUENCE. \n");
	       `uvm_error(get_type_name(), $sformatf("%s", s))	  
	   end
	   
	   //*******check output signals when reset is active*******
	   if (vif.rst == 1) begin 
	       AssrtRstHndlRAddr: assert(curr_it.axi_read_address == 0)      //checks that outputs are correct when reset signal is active
	       begin
	           s = "\n Output axi_read_address is 0, as expected. \n";
	           `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
	       end 
	       else begin
	           s = $sformatf("\n Error ! axi_read_address is %d, but should be 0 ! \n", curr_it.axi_read_address);
	           `uvm_error(get_type_name(), $sformatf("%s", s))		       
	       end
	       
	       AssrtRstHndlWAddr: assert(curr_it.axi_write_address == 0)     //checks that outputs are correct when reset signal is active
	       begin
	           s = "\n Output axi_write_address is 0, as expected. \n";
	           `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
	       end 
	       else begin
	           s = $sformatf("\n Error ! axi_write_address is %d, but should be 0 ! \n", curr_it.axi_write_address);
	           `uvm_error(get_type_name(), $sformatf("%s", s))		       
	       end	   
	   
	       AssrtRstHndlWData: assert(curr_it.axi_write_data == 0)        //checks that outputs are correct when reset signal is active
	       begin
	           s = "\n Output axi_write_data is 0, as expected. \n";
	           `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
	       end 
	       else begin
	           s = $sformatf("\n Error ! axi_write_data is %d, but should be 0 ! \n", curr_it.axi_write_data);
	           `uvm_error(get_type_name(), $sformatf("%s", s))		       
	       end	   
	   end
	   
       scoreboard_port.write(curr_it);
       coverage_port.write(curr_it);
       end
   endtask : main_phase

endclass : ip_monitor

`endif // IP_MONITOR_SV