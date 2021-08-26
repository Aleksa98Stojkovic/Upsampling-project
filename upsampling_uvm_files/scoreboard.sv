`ifndef IP_SCOREBOARD_SV
`define IP_SCOREBOARD_SV

import uvm_pkg::*;      // import the UVM library   
`include "ip_seq_pkg.sv"
import ip_seq_pkg::*;

class ip_scoreboard extends uvm_scoreboard; 

    uvm_analysis_imp#(ip_seq_item, ip_scoreboard) item_collected_imp;
    
	`uvm_component_utils(ip_scoreboard)
    //`uvm_analysis_imp_decl(_item_collected_port)
  //variables, objects, arrays etc. used for storing input objects and checking:
  ip_seq_item clone_item;
  
   typedef enum { read_data_state, read_wait_init_state } read_store_stages;                           
   typedef enum { write_result_state, write_wait_init_state } write_store_stages;    
   read_store_stages read_store_state = read_wait_init_state;
   write_store_stages write_store_state = write_wait_init_state;
   
   bit [DATA_WIDTH - 1 : 0] sb_memory_space[0:14911];   //array for simulating memory 
   bit [DATA_WIDTH - 1 : 0] input_from_file[0:10815];
   int ofm_offs = 10816;                                //variable for holding address where OFM starts
   int weights_offs = 1600;                             //variable for holding address where weights start
   bit [5 : 0]  rcnt_64 = 0;                            //counter for number of data read to IP
   bit [5 : 0]  wcnt_64 = 0;                            //counter for number of data written from IP
   int read_init_happened = 0;                          //variable for holding the number of read init signals that happened (expected 1 for each read operation)
   int read_data_num = 0;                               //variable for holding number of data read by IP
   int write_data_num = 0;                              //variable for holding number of data written by IP
   int read_last_happened = 0;                          //variable for holding the number of times last data signals that happened (expected 1 for each read operation)
   int write_done_happened = 0;                         //variable for holding the number of time write done has been activated
   bit [ADDRESS_WIDTH - 1 : 0] read_address_var  = 0;   //variable for holding start address of to-be-read data     
   int write_init_happened = 0;                         //variable for holding the number of write init signals that happened (expected 1 for each write operation)
   int write_next_happened = 0;                         //variable for holding the number of write next signals that happened (expected 64 for each write operation)
   int write_done_happened = 0;                         //variable for holding the number of write done signals that happened (expected 1 for each write operation)
   bit [ADDRESS_WIDTH - 1 : 0] write_address_var  = 0;  //variable for holding start address of to-be-written data 
   bit [DATA_WIDTH - 1 : 0]  result[0:4095];            //expected results stored here   
   int min_read_op = 229;
   string s;                                            //debug info messages stored here
       int fd;
       int d =0;    
       string line;
    
	function new(string name = "ip_scoreboard", uvm_component parent = null);
		super.new(name,parent);		
	endfunction
	
	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);
		item_collected_imp = new("item_collected_imp", this);
    endfunction: build_phase
	
	extern virtual function void write(ip_seq_item ip_item);

    extern virtual function void check_phase(uvm_phase phase);
   
endclass;
///////////////////////////////////////////////////////clone_object//////////////////////////////////////
function void ip_scoreboard::write(ip_seq_item ip_item);

    $cast(clone_item,ip_item.clone());	
	       `uvm_info(get_type_name(), $sformatf("Item collected: \n%s", clone_item.sprint()), UVM_HIGH)
	       
    //*******STORE READ DATA*******
    
    case (read_store_state)
    
        read_wait_init_state : begin
        
            if (clone_item.axi_read_init == 1) begin 
                `uvm_info(get_type_name(), $sformatf("Read data address: %0d \n", read_address_var/8 + rcnt_64), UVM_HIGH)
                read_init_happened++;
                read_address_var = clone_item.axi_read_address;
                read_store_state = read_data_state;           
            end
        end
        
        read_data_state : begin
        
            if (clone_item.axi_read_ready == 1  && clone_item.axi_read_valid == 1) begin    // "If IP is ready to read data and the data on the input of the IP is valid, data will be put into the IP. We store the input data to later cross-check calculation results."
                sb_memory_space[read_address_var/8 + rcnt_64] = clone_item.axi_read_data;   // "/8 needed because we are reading 64bit data, but addresses are seperating 8bits of data."
                `uvm_info(get_type_name(), $sformatf("Written read data %0d on address: %0d \n",sb_memory_space[read_address_var/8 + rcnt_64] ,read_address_var/8+rcnt_64), UVM_HIGH)
                rcnt_64++;
                read_data_num++;
                if (clone_item.axi_read_last == 1) begin 
                    read_last_happened++;        
                    rcnt_64 = 0;
                    read_store_state = read_wait_init_state;
                end 
            end
        end
    endcase;
    //*******STORE WRITE DATA******* 
    case (write_store_state) 
    
        write_wait_init_state : begin
        
            if (clone_item.axi_write_init == 1) begin 
                write_init_happened++;
                write_address_var = clone_item.axi_write_address; 
                write_store_state = write_result_state;
            end        
        end
        
        write_result_state : begin
        
            if (clone_item.axi_write_next == 1) begin 
                sb_memory_space[write_address_var/8 + wcnt_64] = clone_item.axi_write_data;
                `uvm_info(get_type_name(), $sformatf("Written result data %0d on address: %0d \n",sb_memory_space[write_address_var/8 + wcnt_64] ,write_address_var/8 + wcnt_64), UVM_HIGH)
                write_data_num++;
                wcnt_64++;
                write_next_happened++;          
            end   
            
            if (clone_item.axi_write_done == 1) begin
                wcnt_64 = 0;
                write_done_happened ++;
                write_store_state = write_wait_init_state;    
            end      
        end
    
    endcase;
    
    endfunction : write

////////////////////////////////////////////////////check_phase/////////////////////////////////////////
/*
*   Info for read operation:
*   Each read operations reads 64 packets of data; thats 64 packets of 64 bits -> for each read_init there has to be 64packets of data read
*
*   Info for write operation:
*   Each write operation writes 64 packets of data; same as read op.
*/
//todo: add rst_happened to cfg file and do checking (maybe not needed)
function void ip_scoreboard::check_phase(uvm_phase phase);

    //*******READ RESULTS FROM FILE*******
      fd = $fopen(clone_item.res_fp,"r");
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
            result[d][j] = line[63-j]-48;
        end  
        `uvm_info(get_type_name(),$sformatf("Result data read from file: %0d to address %0d.",result[d], d),UVM_HIGH)
        d++;
        if (d == 4096) begin 
            break;
        end 
      end 
      $fclose(fd);
      d = 0;    
            
      fd = $fopen(clone_item.in_fp,"r");
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
            input_from_file[d][j] = line[63-j]-48;
        end  
        `uvm_info(get_type_name(),$sformatf("Input read from file: %0d to address %0d.",input_from_file[d], d),UVM_HIGH)
        d++;
        if (d == 14912) begin 
            break;
        end 
      end 
      $fclose(fd);
      d = 0;
    //*******READ OPERATION CHECKS*******
    //*******check for correct number of data read*******
    AssrtRInitHpnd : assert( read_init_happened - read_data_num/64 == 1 )     

    begin 
        s = "\n Number of data packets read by IP is correct. \n";
        `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
    end 
    else begin 
        s = $sformatf("\n Number of data packets read by IP is INCORRECT ! Expected %d, but got %d \n", read_init_happened, read_data_num/64);
        `uvm_error(get_type_name(), $sformatf("%s", s)) 
    end
    //*******check for read_init and read_last signals*******
    AssrtRLastHpnd : assert(read_init_happened - read_last_happened == 1)   
    begin
        s = "\n Number of read_init and read_last signal activations match. \n";
        `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)    
    end 
    else begin 
        s = $sformatf("\n Number of read_init and read_last don't match ! Number of read_init is %d, number of read_last is %d \n", read_init_happened, read_last_happened);
        `uvm_error(get_type_name(), $sformatf("%s", s)) 
    end
    //******check for read data matching*******
    for (int i=0; i<ofm_offs;i++) begin 
        AssrtRData : assert(sb_memory_space[i] == input_from_file[i]) begin
              s = $sformatf("\n Read data match on address %0d is %0d.\n", i, sb_memory_space[i]);
             `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH) 
        end
        else begin
              s = $sformatf("\n Read data mismatch on address %d ! Expected %0d , but got %0d !\n", i, input_from_file[i], sb_memory_space[i]);
             `uvm_error(get_type_name(), $sformatf("%s", s)) 
        end
    end
    //*******WRITE OPERATIONS CHECKS*******
    //*******check for correct number of data read*******
    AssrtWInitHpnd : assert(write_data_num - write_init_happened*64 == 0)     //for every read operation (read init activated) we need 64 packets of data -> read_data_num - read_init_happened*64 = 0
    begin 
        s = "\n Number of data packets written by IP is correct. \n";
        `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
    end 
    else begin 
        s = $sformatf("\n Number of data packets written by IP is INCORRECT ! Expected %d, but got %d \n", write_init_happened, write_data_num/64);
        `uvm_error(get_type_name(), $sformatf("%s", s)) 
    end    
    //*******cross-check write_init and write_done signals*******
    AssrtWInDn : assert(write_init_happened - write_done_happened == 0)   //for each write init ther should be one write done
    begin 
            s = $sformatf("\n Number of write_init and write_last signal activations match. \n");
            `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)       
    end 
    else begin 
            s = $sformatf("\n Number of write_init and write_done don't match ! Number of write_init is %d, number of write_done is %d \n", write_init_happened, write_done_happened);
            `uvm_error(get_type_name(), $sformatf("%s", s))   
    end
    //*******RESULT CHECKS*******
    //*******checking if written data matches with expected data-we read the expected data from a file generated by a .py script*******
    for (int i=0; i<=4095; i++) begin 
        AssrtRes : assert(sb_memory_space[ofm_offs+i] == result[i]) 
        begin 
            s = $sformatf("\n Result on address %d is %0d and is correct ! \n", i+ofm_offs, sb_memory_space[ofm_offs+i] );
            `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)    
        end         
        else begin 
            s = $sformatf("\n Result mismatch on result address %0d ! Expected %d , but got %0d ! \n", i+ofm_offs, result[i], sb_memory_space[ofm_offs+i]  );
            `uvm_error(get_type_name(), $sformatf("%s", s))          
        end
    end
     
endfunction : check_phase
    
`endif // IP_SCOREBOARD_SV