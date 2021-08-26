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
   
   typedef enum { read_data_state, read_wait_init_state } read_stages;                           //IP read FSM
   typedef enum {write_result_state, write_wait_init_state, write_done_state } write_stages;    //IP write result FSM
   typedef enum {startup_state, axi_sel_wmem_state, axi_sel_cache_state, proc_done, read_all_state } config_stages;
   read_stages ip_read_state = read_wait_init_state;
   write_stages ip_write_state = write_wait_init_state;
   config_stages ip_cfg3_state = startup_state;
   
   static bit [DATA_WIDTH - 1 : 0]  memory_space[0:14911]; //0-1599: ifm, 1600-10815: weights. After first randomization disable with rand_mode(0)
   int weight_offset   = 1600;      //Address of first weight data
   int ofm_offset      = 10816;     //Address of first OFM data
   bit [ADDRESS_WIDTH - 1 : 0] read_address_var  = 0;        
   bit [ADDRESS_WIDTH - 1 : 0] write_address_var = 0;
   int rcnt_64    = 0;
   int wcnt_64    = 0;
   bit read_flag = 0;
   bit valid_prev = 0;
   bit ready_prev = 0;

       int fd;
       int d =0;    
       string line;
   
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
      
      seq_item_port.get_next_item(req);

      fd = $fopen(req.in_fp,"r");
      if (fd) begin
          `uvm_info(get_type_name(),$sformatf("File opened successfuly: %d", fd), UVM_LOW)
      end
      else begin 
          `uvm_info(get_type_name(),$sformatf("Failed to open file: %d", fd), UVM_LOW)
      end
      //store data into sequence item field
      while (!$feof(fd)) begin
        $fscanf(fd, "%s", line);
        for (int j =0; j<64; j++) begin
            memory_space[d][j] = line[63-j]-48;
        end  
        `uvm_info(get_type_name(),$sformatf("Data read from file: %0d to address &0d .",memory_space[d], d),UVM_HIGH)
        d++;
        if (d == 14912) begin 
            break;
        end 
      end 
      $fclose(fd);
      d = 0;
      
      seq_item_port.item_done();
            
      forever begin     //******forever begin*******
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

            vif.axi_read_last_i   = req.axi_read_last;
            vif.axi_read_data_i   = 0;  
            vif.axi_read_valid_i = req.axi_read_valid;  
            //vif.axi_read_valid_i = 1;
            
            if ( vif.axi_read_ready_o == 0 && valid_prev == 1 ) begin
                vif.axi_read_valid_i = 1;
            end

            if ( ip_cfg3_state == proc_done ) begin
                vif.axi_read_valid_i = 0;         
            end          
                      
            case (ip_read_state)
            
                read_wait_init_state: begin     
                 
                    vif.axi_read_valid_i  = 0;
                    if (vif.axi_read_init_o == 1) begin                        
                        read_address_var = vif.axi_read_address_o;
                        //vif.axi_read_valid_i  = 0;
                        ip_read_state = read_data_state;  
                    end 
                end
                
                read_data_state: begin 
                    
                    vif.axi_read_data_i = memory_space[read_address_var/8 + rcnt_64];      
                         
                    if ( rcnt_64 == 63 && vif.axi_read_valid_i  == 1 ) begin 
                            vif.axi_read_last_i  = 1;
                    end    
                    
                    if (vif.axi_read_ready_o == 1 && vif.axi_read_valid_i == 1) begin
                                                //$display("in read state  %0d\n", rcnt_64);
                        if (ip_cfg3_state == axi_sel_wmem_state) begin
                            `uvm_info(get_type_name(),$sformatf("WMEM Reading data: %d on address %d.", memory_space[read_address_var/8 + rcnt_64], read_address_var/8 + rcnt_64), UVM_HIGH)
                        end
                        else if (ip_cfg3_state == axi_sel_cache_state) begin
                            `uvm_info(get_type_name(),$sformatf("CACHE Reading data: %d on address %d.", memory_space[read_address_var/8 + rcnt_64], read_address_var/8 + rcnt_64), UVM_HIGH)
                        end   
                        
                        rcnt_64++;  
                        //$display("%0d \n",rcnt_64);
                        
                        if (rcnt_64 == 64) begin
                            rcnt_64 = 0;
                            ip_read_state = read_wait_init_state;   //wait start state
                        end
                    end




                    
//                    vif.axi_read_data_i = memory_space[read_address_var/8 + rcnt_64];      
                         
//                    if ( rcnt_64 == 63 && vif.axi_read_valid_i  == 1 ) begin 
//                            vif.axi_read_last_i  = 1;
//                    end    
                    
//                    if (vif.axi_read_ready_o == 1 && vif.axi_read_valid_i == 1) begin
//                                                //$display("in read state  %0d\n", rcnt_64);
//                        if (ip_cfg3_state == axi_sel_wmem_state) begin
//                            `uvm_info(get_type_name(),$sformatf("WMEM Reading data: %d on address %d.", memory_space[read_address_var/8 + rcnt_64], read_address_var/8 + rcnt_64), UVM_HIGH)
//                        end
//                        else if (ip_cfg3_state == axi_sel_cache_state) begin
//                            `uvm_info(get_type_name(),$sformatf("CACHE Reading data: %d on address %d.", memory_space[read_address_var/8 + rcnt_64], read_address_var/8 + rcnt_64), UVM_HIGH)
//                        end   
                        
//                        rcnt_64++;  
//                        //$display("%0d \n",rcnt_64);
                        
//                        if (rcnt_64 == 64) begin
//                            rcnt_64 = 0;
//                            ip_read_state = read_wait_init_state;   //wait start state
//                        end
//                    end
                    
                end 
                
            endcase;
            ready_prev = vif.axi_read_ready_o;
            valid_prev = vif.axi_read_valid_i;    
//*************************************IP write results FSM********************************************
            vif.axi_write_done_i = req.axi_write_done;
            vif.axi_write_next_i = 0;
            
            case (ip_write_state)
            
                write_wait_init_state: begin
                    if (vif.axi_write_init_o == 1) begin
                        ip_write_state = write_result_state;
                    end                
                end
                write_result_state: begin
                    vif.axi_write_next_i = req.axi_write_next;
                    //vif.axi_write_next_i = 1;
                    vif.axi_write_done_i = req.axi_write_done;
                    
                    if (vif.axi_write_next_i == 1) begin
                        wcnt_64++;
                        if (wcnt_64 == 65) begin
                            wcnt_64 = 0;
                            ip_write_state = write_done_state;
                            vif.axi_write_next_i = 0;
                            vif.axi_write_done_i = 1;
                        end
                    end
                end
                write_done_state: begin
                    vif.axi_write_done_i = 0;
                    vif.axi_write_next_i = 0;
                    ip_write_state = write_wait_init_state;
                end
                
            endcase;
      end   //end if rst != 1
        
      seq_item_port.item_done();
      end   //end forever loop
   endtask : main_phase

endclass : ip_driver

`endif