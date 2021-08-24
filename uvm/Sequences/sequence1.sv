`ifndef SEQUENCE1_SV
 `define SEQUENCE1_SV

class sequence1 extends ip_base_seq;

   `uvm_object_utils (sequence1)
   
       string line;
       int fd;
       int d =0;    
       int limit = 10000;  
    
   function new(string name = "sequence1");
      super.new(name);
   endfunction

   virtual task body();

      fd = $fopen("C:/Users/Robi/Documents/GenTBData/dram_content1.txt","r");
      if (fd) begin
          `uvm_info(get_type_name(),$sformatf("File opened successfuly: %d", fd), UVM_LOW)
      end
      else begin 
          `uvm_info(get_type_name(),$sformatf("Failed to open file: %d", fd), UVM_LOW)
      end
      //store data into sequence item field
      while (!$feof(fd)) begin
        $fscanf(fd, "%s", line);
        //`uvm_info(get_type_name(), $sformatf(" %0d %s", d, line), UVM_LOW)  
        for (int j =0; j<64; j++) begin
            req.memory_space[d][j] = line[63-j]-48;
        end  
        //`uvm_info(get_type_name(),$sformatf("Data read from file: %0d .",req.memory_space[d]),UVM_LOW)
        d++;
        if (d == 14912) begin 
            break;
        end 
      end 
      $fclose(fd);
      d = 0;
      
      fd = $fopen("C:/Users/Robi/Documents/GenTBData/result1.txt","r");
      if (fd) begin
          `uvm_info(get_type_name(),$sformatf("File opened successfuly: %d", fd), UVM_LOW)
      end
      else begin 
          `uvm_info(get_type_name(),$sformatf("Failed to open file: %d", fd), UVM_LOW)
      end
      //store data into sequence item field
      while (!$feof(fd)) begin
        $fscanf(fd, "%s", line);
        //`uvm_info(get_type_name(), $sformatf(" %0d %s", d, line), UVM_LOW)  
        for (int j =0; j<64; j++) begin
            req.result[d][j] = line[63-j]-48;
        end  
        //`uvm_info(get_type_name(),$sformatf("Data read from file: %0d .",req.result[d]),UVM_LOW)
        d++;
        if (d == 4096) begin 
            break;
        end 
      end 
      $fclose(fd);
      d = 0;
      
      for (int i=1; i<limit; i++ )  begin
        //if (i) begin      add constraints for sel_axi
        //else begin 
        //end 
	       `uvm_do_with(req, { 
	                           req.config3[0]     == 0; 
	                           req.config3[1]     == 1;    //ReLu = True       
	                           req.config3[4:2]     == 0;    //not used
	                           req.config3[13:5]  == 10; 
	                           req.config3[31:14] == 100;
	                           req.config4[11:0]  == 0;
	                           req.config4[31:30] == 0;
	                           req.config4[29:12] == 64;
	                           req.config5[8:0]   == 8;
	                           req.config5[31:9]  == 0;
	                    });  //todo: add constraints which will produce different driving scenarios;
      end
   endtask : body

endclass : sequence1

`endif