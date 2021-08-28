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
   read_stages ip_read_state_next = read_wait_init_state;
   write_stages ip_write_state = write_wait_init_state;
   write_stages ip_write_state_next = write_wait_init_state;
   config_stages ip_cfg3_state = startup_state;
   
   static bit [DATA_WIDTH - 1 : 0]  memory_space[0:14911]; //0-1599: ifm, 1600-10815: weights. After first randomization disable with rand_mode(0)
   int weight_offset   = 1600;      //Address of first weight data
   int ofm_offset      = 10816;     //Address of first OFM data
   bit [ADDRESS_WIDTH - 1 : 0]      read_address_var  = 0;    
   bit [ADDRESS_WIDTH - 1 : 0]      read_address_var_next  = 0;        
   bit [ADDRESS_WIDTH - 1 : 0]      write_address_var = 0;
   int rcnt_64      = 0;
   int wcnt_64      = 0;
   bit ren_64       = 0;
   bit wen_64       = 0;
        string in_fp;
        int fd;
        int d =0;    
        string line;
   
   virtual interface ip_if vif;
   
   function new(string name = "ip_driver", uvm_component parent = null);
      super.new(name,parent);
   endfunction
    
   function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(string)::get(null, "ip_test", "input_fp", in_fp))
            `uvm_fatal("NO_FP",{"File path of inputs must be set for driver ! ",get_full_name()})
   endfunction : build_phase 
    
   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (!uvm_config_db#(virtual ip_if)::get(this, "", "ip_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})
   endfunction : connect_phase

   extern virtual task comb_read(ip_seq_item item);
   extern virtual task comb_write(ip_seq_item item);
   extern virtual task seqv(ip_seq_item item);

   task main_phase(uvm_phase phase);
      
      seq_item_port.get_next_item(req);

      //fd = $fopen(req.in_fp,"r");
      fd = $fopen(in_fp,"r");
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
         //@(posedge vif.clk);
         //#1
//*********************************************CONFIG******************************************         

            
//******************************************IP read data FSM******************************************      
    fork        
        comb_read(req);
        comb_write(req);
        seqv(req);
    join_any
    disable fork;
    //            vif.axi_read_last_i   = req.axi_read_last;
//            vif.axi_read_data_i   = 0;  
//            vif.axi_read_valid_i  = req.axi_read_valid;  
//            vif.axi_read_valid_i <= 1;
            
//            if ( ready_prev == 0 && valid_prev == 1 ) begin
//                vif.axi_read_valid_i = 1;
//            end

//            if ( ip_cfg3_state == proc_done ) begin
//                vif.axi_read_valid_i = 0;         
//            end          
                      
//            case (ip_read_state)
            
//                read_wait_init_state: begin     
                 
//                    vif.axi_read_valid_i  = 0;
//                    if (vif.axi_read_init_o == 1) begin                        
//                        read_address_var = vif.axi_read_address_o;
//                        //vif.axi_read_valid_i  = 0;
//                        ip_read_state = read_data_state;  
//                    end 
//                end
                
//                read_data_state: begin 
                    
//                    vif.axi_read_data_i = memory_space[read_address_var/8 + rcnt_64];      
                         
//                    if ( rcnt_64 == 63 && vif.axi_read_valid_i  == 1 ) begin 
//                            vif.axi_read_last_i  = 1;
//                    end    
                    
//                    if ( vif.axi_read_ready_o == 1 && vif.axi_read_valid_i == 1 ) begin
                    
//                        $display("Rcnt_64 is  %0d, sim time is %0t .\n", rcnt_64, $time);
                                                
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
                    
//                end 
                
//            endcase;
//            ready_prev = vif.axi_read_ready_o;
//            valid_prev = vif.axi_read_valid_i;    
//*************************************IP write results FSM********************************************
//            vif.axi_write_done_i = req.axi_write_done;
//            vif.axi_write_next_i = 0;
            
//            case (ip_write_state)
            
//                write_wait_init_state: begin
//                    if (vif.axi_write_init_o == 1) begin
//                        ip_write_state = write_result_state;
//                    end                
//                end
//                write_result_state: begin
//                    vif.axi_write_next_i = req.axi_write_next;
//                    //vif.axi_write_next_i = 1;
//                    vif.axi_write_done_i = req.axi_write_done;
                    
//                    if (vif.axi_write_next_i == 1) begin
//                        wcnt_64++;
//                        if (wcnt_64 == 65) begin
//                            wcnt_64 = 0;
//                            ip_write_state = write_done_state;
//                            vif.axi_write_next_i = 0;
//                            vif.axi_write_done_i = 1;
//                        end
//                    end
//                end
//                write_done_state: begin
//                    vif.axi_write_done_i = 0;
//                    vif.axi_write_next_i = 0;
//                    ip_write_state = write_wait_init_state;
//                end
                
//            endcase;        
      seq_item_port.item_done();
      end   //end forever loop
   endtask : main_phase

endclass : ip_driver

//*******Task for Driving Read Operation*******
task ip_driver::comb_read(ip_seq_item item);

    @(ip_read_state, read_wait_init_state, read_data_state, vif.axi_read_init_o, vif.axi_read_address_o, read_address_var, rcnt_64, vif.axi_read_ready_o, ip_cfg3_state, axi_sel_wmem_state, axi_sel_cache_state);
    //******* READ OPERATION *******
    vif.axi_read_last_i  <= 0;
    vif.axi_read_valid_i <= 0;
    vif.axi_read_data_i  <= 0;
    ren_64               <= 0;    
        
    case (ip_read_state)
    
        read_wait_init_state: begin     
            
            ip_read_state_next <= read_wait_init_state;
            
            if (vif.axi_read_init_o == 1) begin
                
                 ip_read_state_next <= read_data_state;
                 read_address_var_next = vif.axi_read_address_o;
            end    
        end
        
        read_data_state: begin
        
            ip_read_state_next <= read_data_state;
            vif.axi_read_valid_i <= 1;
            
            vif.axi_read_data_i <= memory_space[read_address_var/8 + rcnt_64];    
             
            if ( rcnt_64 == 63 ) begin 
                vif.axi_read_last_i  <= 1;
            end  
             
            if ( vif.axi_read_ready_o == 1 ) begin 
                    
                    if (ip_cfg3_state == axi_sel_wmem_state) begin
                        `uvm_info(get_type_name(),$sformatf("WMEM Reading data: %d on address %d.", memory_space[read_address_var/8 + rcnt_64], read_address_var/8 + rcnt_64), UVM_HIGH)
                    end
                    else if (ip_cfg3_state == axi_sel_cache_state) begin
                        `uvm_info(get_type_name(),$sformatf("CACHE Reading data: %d on address %d.", memory_space[read_address_var/8 + rcnt_64], read_address_var/8 + rcnt_64), UVM_HIGH)
                    end   
                    
                    ren_64 <= 1;
                    
                    if (rcnt_64 == 63) begin
                        ip_read_state_next <= read_wait_init_state;   //wait start state
                    end
            end
        end
    
    endcase;
    
endtask : comb_read

task ip_driver::comb_write(ip_seq_item item);
    
    @(ip_write_state, write_wait_init_state, write_result_state, vif.axi_write_init_o, req.axi_write_next, write_done_state, wcnt_64, vif.axi_write_address_o, vif.axi_write_data_o );
    //******* WRITE OPERATION *******
    vif.axi_write_next_i <= 0;
    vif.axi_write_done_i <= 0;
    wen_64               <= 0;
    
    case (ip_write_state)
        
        write_wait_init_state: begin
        
            ip_write_state_next <= write_wait_init_state;
            
            if (vif.axi_write_init_o == 1) begin
                ip_write_state_next <= write_result_state;
            end                
        end
        
        write_result_state: begin
        
            ip_write_state_next  <= write_result_state;
            vif.axi_write_next_i <= req.axi_write_next;
            vif.axi_write_done_i <= 0;
            
            if (vif.axi_write_next_i == 1) begin
            
                wen_64 <= 1;
                if (wcnt_64 == 63) begin
                    ip_write_state_next  <= write_done_state;
                end
            end
        end
        
        write_done_state: begin
            vif.axi_write_done_i <= 1;
            ip_write_state_next  <= write_wait_init_state;
        end
        
    endcase;
           
endtask : comb_write

task ip_driver::seqv(ip_seq_item item);

    //******* READ OPERATION *******
    @(posedge vif.clk);
    
    ip_read_state <= ip_read_state_next;
    
    read_address_var <= read_address_var_next;
    
    if (ren_64 == 1) begin
        if (rcnt_64 == 63) begin
            
            rcnt_64 <= 0;
        end 
        else begin
        
            rcnt_64 <= rcnt_64 + 1; 
        end
    end
    
    //******* WRITE OPERATION *******
    ip_write_state <= ip_write_state_next;
    
    if (wen_64 == 1) begin
        if (wcnt_64 == 63) begin
            
            wcnt_64 <= 0;
        end 
        else begin
        
            wcnt_64 <= wcnt_64 + 1; 
        end
    end
    
    //******* CONFIG REGISTERS *******
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
                     
endtask : seqv
`endif