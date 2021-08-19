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

   bit [DATA_WIDTH - 1 : 0] sb_memory_space[0:14911];   //array for simulating memory 
   int ofm_offs = 10815;                                //variable for holding address where OFM starts
   int weights_offs = 1600;                             //variable for holding address where weights start
   bit [5 : 0]  rcnt_64 = 0;                            //counter for number of data read to IP
   bit [5 : 0]  wcnt_64 = 0;                            //counter for number of data written from IP
   int read_init_happened = 0;                          //variable for holding the number of read init signals that happened (expected 1 for each read operation)
   int read_data_num = 0;                               //variable for holding number of data read by IP
   int write_data_num = 0;                              //variable for holding number of data written by IP
   int read_last_happened = 0;                          //variable for holding the number of times last data signals that happened (expected 1 for each read operation)
   bit [ADDRESS_WIDTH - 1 : 0] read_address_var  = 0;   //variable for holding start address of to-be-read data     
   int write_init_happened = 0;                         //variable for holding the number of write init signals that happened (expected 1 for each write operation)
   int write_next_happened = 0;                         //variable for holding the number of write next signals that happened (expected 64 for each write operation)
   int write_done_happened = 0;                         //variable for holding the number of write done signals that happened (expected 1 for each write operation)
   bit [ADDRESS_WIDTH - 1 : 0] write_address_var  = 0;  //variable for holding start address of to-be-written data 
   bit [DATA_WIDTH - 1 : 0]   expected_result =0 ;      //variable for holding expected result of convolution with 3x3 kernel
   string s;                                            //debug info messages stored here
  
    
	function new(string name = "ip_scoreboard", uvm_component parent = null);
		super.new(name,parent);
		item_collected_imp = new("item_collected_imp", this);
	endfunction
	
	extern virtual function void write(ip_seq_item ip_item);
	extern virtual function void store_read_data(ip_seq_item ip_item);
	extern virtual function void store_write_data(ip_seq_item ip_item);

   extern virtual function void check_phase(uvm_phase phase);
   
endclass;
///////////////////////////////////////////////////////clone_object//////////////////////////////////////
function void ip_scoreboard::write(ip_seq_item ip_item);

    $cast(clone_item,ip_item.clone());	
        
    store_read_data(clone_item);    
    store_write_data(clone_item);
    
endfunction : write
/////////////////////////////////////////////////////store_read_data/////////////////////////////////////
function void ip_scoreboard::store_read_data(ip_seq_item ip_item);                      //proly good?

    if (clone_item.axi_read_init == 1) begin 
        read_init_happened++;
        read_address_var = clone_item.axi_read_address;
        sb_memory_space[read_address_var/8] = clone_item.axi_read_data;                 // reading first data packet
        read_data_num++;                                                                // Incrementing number of data packets read incremented
    end
    if (read_init_happened != 0) begin              // "If read init has happened" 
        if (clone_item.axi_read_ready == 1  && clone_item.axi_read_valid == 1) begin    // "If IP is ready to read data and the data on the input of the IP is valid, data will be put into the IP. We store the input data to later cross-check calculation results."
            sb_memory_space[read_address_var/8 + rcnt_64] = clone_item.axi_read_data;   // "/8 needed because we are reading 64bit data, but addresses are seperating 8bits of data."
            rcnt_64++;
            read_data_num++;
            if (clone_item.axi_read_last == 1) begin 
                read_last_happened++;
                rcnt_64 = 0;
            end 
        end
    end 
    
endfunction : store_read_data
///////////////////////////////////////////////////store_write_data//////////////////////////////////////
function void ip_scoreboard::store_write_data(ip_seq_item ip_item);

    if (clone_item.axi_write_init == 1) begin 
        write_init_happened++;
        write_data_num++;
        write_address_var = clone_item.axi_write_address;    
    end
    if (write_init_happened != 0) begin 
        if (clone_item.axi_write_next == 1) begin 
            sb_memory_space[write_address_var/8 + wcnt_64] = clone_item.axi_write_data;
            write_data_num++;
            wcnt_64++;
            write_next_happened++;
            write_done_happened += clone_item.axi_write_done;
        end
    end 

endfunction : store_write_data
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
    
    //*******READ OPERATION CHECKS*******
    //*******check for correct number of data read*******
    AssrtRInitHpnd : assert(read_data_num - read_init_happened*64 == 0)     //for every read operation (read init activated) we need 64 packets of data -> read_data_num - read_init_happened*64 = 0
    begin 
        s = "\n Number of data packets read by IP is correct. \n";
        `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)
    end 
    else begin 
        s = $sformatf("\n Number of data packets read by IP is INCORRECT ! Expected %d, but got %d \n", read_init_happened*64, read_data_num);
        `uvm_error(get_type_name(), $sformatf("%s", s)) 
    end
    //*******check for read_init and read_last signals*******
    AssrtRLastHpnd : assert(read_init_happened - read_last_happened == 0)   //for every read operaton (read init activated) we need 1 read last activated
    begin
        s = "\n Number of read_init and read_last signal activations match. \n";
        `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)    
    end 
    else begin 
        s = $sformatf("\n Number of read_init and read_last don't match ! Number of read_init is %d, number of read_last is %d \n", read_init_happened, read_last_happened);
        `uvm_error(get_type_name(), $sformatf("%s", s)) 
    end
    //*******cross checking memory spaces*******
    for (int i=0; i<64; i++) begin
        AssrtMemMatch : assert(sb_memory_space[read_address_var +i] == clone_item.memory_space[read_address_var +i])   //data read from the memory should be on the same addresses (checking only for the last transfer of data, if one transfer is correct, others should be too)          
        begin 
            s = $sformatf("\n Data items on address %d match\n", read_address_var/8+i);
            `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)    
        end 
        else begin 
            s = $sformatf("\n Mismatch of data on address %d ! Expected: %d, but got %d\n", read_address_var +i, clone_item.memory_space[read_address_var +i], sb_memory_space[read_address_var/8 +i]);
            `uvm_error(get_type_name(), $sformatf("%s", s)) 
            //print data before, of, and after address read_address_var+i
            `uvm_info(get_type_name(), $sformatf("\n Read data and addresses: \n"), UVM_LOW)
            `uvm_info(get_type_name(), $sformatf(" SB Data %d is on Address %d", sb_memory_space[read_address_var +i], read_address_var +i), UVM_LOW)       //print value on address..
            `uvm_info(get_type_name(), $sformatf(" SB Data %d is on Address %d", sb_memory_space[read_address_var +i+1], read_address_var +i+1), UVM_LOW)   //..and value on next address
            
            `uvm_info(get_type_name(), $sformatf("\n Memory data and addresses: \n"), UVM_LOW)
            `uvm_info(get_type_name(), $sformatf(" SB Data %d is on Address %d", clone_item.memory_space[read_address_var +i], read_address_var +i), UVM_LOW)
            `uvm_info(get_type_name(), $sformatf(" SB Data %d is on Address %d", clone_item.memory_space[read_address_var +i+1], read_address_var +i+1), UVM_LOW)        
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
        s = $sformatf("\n Number of data packets written by IP is INCORRECT ! Expected %d, but got %d \n", write_init_happened*64, write_data_num);
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
    for (int i=0; i<4095; i++) begin 
        AssrtRes : assert(sb_memory_space[10815+i] == clone_item.result[i]) 
        begin 
            s = $sformatf("\n Data number %d of 4096 matches ! \n", i);
            `uvm_info(get_type_name(), $sformatf("%s", s), UVM_HIGH)    
        end         
        else begin 
            s = $sformatf("\n Data mismatch on data-number %d ! \n", i );
            `uvm_error(get_type_name(), $sformatf("%s", s))          
        end
    end
     
endfunction : check_phase
    
`endif // IP_SCOREBOARD_SV