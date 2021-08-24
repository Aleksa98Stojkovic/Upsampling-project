`ifndef DRIVER_SV
 `define DRIVER_SV
 
`include "ip_seq_pkg.sv"
import ip_seq_pkg::*;
import uvm_pkg::*;     
`include "uvm_macros.svh" 

class ip_driver extends uvm_driver#(ip_seq_item);
    
parameter CONFIG_WIDTH = 32;
parameter DATA_WIDTH = 64;
parameter ADDRESS_WIDTH = 32;

   `uvm_component_utils(ip_driver)
   
   typedef enum {config_read_state,  read_data_state, read_wait_init_state } read_stages;                           //IP read FSM
   typedef enum {config_write_state, write_result_state, write_wait_init_state, write_done_state } write_stages;    //IP write result FSM
   typedef enum {startup_state, axi_sel_wmem_state, axi_sel_cache_state, proc_done } config_stages;
   read_stages ip_read_state = read_wait_init_state;
   write_stages ip_write_state = config_write_state;
   config_stages ip_cfg3_state = startup_state;
   
   int weight_offset   = 1600;      //Address of first weight data
   int ofm_offset      = 10816;     //Address of first OFM data
   bit [ADDRESS_WIDTH - 1 : 0] read_address_var  = 0;        
   bit [ADDRESS_WIDTH - 1 : 0] write_address_var = 0;
   int  rcnt_64 = 0;
   int  wcnt_64 = 0;
   int pkt_cnt          = 0;
   
   virtual interface ip_if vif;
   
   function new(string name = "ip_driver", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (!uvm_config_db#(virtual ip_if)::get(this, "", "ip_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})
   endfunction : connect_phase

   
   task main_phase(uvm_phase phase);
      
      forever begin
         seq_item_port.get_next_item(req);
         `uvm_info(get_type_name(),
                   $sformatf("Driver sending...\n%s", req.sprint()),
                   UVM_HIGH)
         // FSM for correct driving of design
         @(posedge vif.clk);
         #1
         if (vif.rst != 1) begin 
//*********************************************CONFIG******************************************         
            vif.config1 = req.config1;
            vif.config2 = req.config2;
            vif.config3 = req.config3;         
            vif.config4 = req.config4;
            vif.config5 = req.config5;
            //Part for correctly driving config3 register:
            case (ip_cfg3_state) 
            
                startup_state: begin
                    vif.config1 = 0;
                    vif.config2 = 0;
                    vif.config3 = 0;         
                    vif.config4 = 0;
                    vif.config5 = 0;
                    ip_cfg3_state =axi_sel_wmem_state;
                end
                axi_sel_wmem_state: begin 
                
                    vif.config3[0] = 0;
                    vif.config3[3] = 1;
                    vif.config3[4] = 0;     
                    if (vif.config6[0] == 1) begin 
                        ip_cfg3_state = axi_sel_cache_state;
                    end           
                end 
                axi_sel_cache_state: begin 
                
                    vif.config3[0] = 1;
                    vif.config3[3] = 0;
                    vif.config3[4] = 1;
                    if (vif.config6[1] == 1) begin 
                        ip_cfg3_state = proc_done;
                    end
                end
                proc_done: begin 
                
                    vif.config3[0] = 0;
                    vif.config3[3] = 0;
                    vif.config3[4] = 0;                
                end
            endcase;
//******************************************IP read data FSM******************************************
            vif.axi_read_valid_i  = req.axi_read_valid;
            vif.axi_read_data_i = req.memory_space[weight_offset];
            
            case (ip_read_state)
            
                read_wait_init_state: begin           
                    if (vif.axi_read_init_o == 1) begin
                        vif.axi_read_last_i = req.axi_read_last;
                        read_address_var = vif.axi_read_address_o;
                        ip_read_state = read_data_state;                
                    end 
                end
                read_data_state: begin 
                    vif.axi_read_data_i = req.memory_space[read_address_var/8 + rcnt_64];
                    vif.axi_read_last_i = req.axi_read_last;
                    if (rcnt_64 == 63) begin 
                        vif.axi_read_last_i  = 1;
                    end                    
                    if (vif.axi_read_ready_o == 1 && req.axi_read_valid == 1) begin
                        //`uvm_info(get_type_name(),$sformatf("rcnt_64 is :: %d", rcnt_64), UVM_LOW)
                        rcnt_64++;
                        if (rcnt_64 == 64) begin
                            rcnt_64 = 0;
                            pkt_cnt++;
                            `uvm_info(get_type_name(),$sformatf("Number of read packets:  %d", pkt_cnt), UVM_LOW)
                            ip_read_state = read_wait_init_state;   //wait start state
                        end
                    end
                end 
                //read_wait_init_state: begin                                                     
                //    if (vif.axi_read_init_o == 1) begin
                //        read_address_var = vif.axi_read_address_o;
                //        ip_read_state = read_data_state;
                //    end
                //end
            endcase;
            
//*************************************IP write results FSM********************************************
            vif.axi_write_done_i = req.axi_write_done;
            vif.axi_write_next_i = 0;
            case (ip_write_state)
            
                config_write_state: begin
                    if (req.config3[4] == 1 && req.config3[0] == 1)begin
                        ip_write_state = write_wait_init_state;
                    end
                end
                write_wait_init_state: begin
                    if (vif.axi_write_init_o == 1) begin
                        wcnt_64++;
                        ip_write_state = write_result_state;
                    end                
                end
                write_result_state: begin
                    vif.axi_write_next_i = req.axi_write_next;
                    if (req.axi_write_next == 1) begin
                        wcnt_64++;
                        if (wcnt_64 == 64) begin
                            wcnt_64 = 0;
                            ip_write_state = write_done_state;
                            vif.axi_write_next_i = 0;
                        end
                    end
                end
                write_done_state: begin
                    vif.axi_write_done_i = 1;
                    vif.axi_write_next_i = 0;
                end
                
            endcase;
      end   //end if rst != 1
      
        req.config6           = vif.config6;
        //req.axi_read_address  = vif.axi_read_address_o;
        req.axi_write_address = vif.axi_write_address_o;
        req.axi_read_init     = vif.axi_read_init_o;
        req.axi_read_ready    = vif.axi_read_ready_o;
        req.axi_write_init    = vif.axi_write_init_o;
        req.axi_write_data    = vif.axi_write_data_o; 
        
        seq_item_port.item_done();
      end   //end forever loop
   endtask : main_phase

endclass : ip_driver

`endif