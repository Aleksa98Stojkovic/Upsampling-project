`ifndef SEQUENCE1_SV
 `define SEQUENCE1_SV

class sequence1 extends ip_base_seq;

   `uvm_object_utils (sequence1)
        
       bit relu; 
       string in_fp_seq;    // = "C:/Users/Robi/Documents/GenTBData/dram_content1.txt";
       string res_fp_seq;   // = "C:/Users/Robi/Documents/GenTBData/result1.txt";
       int limit = 60000;     
    
    
   function new(string name = "sequence1");
      super.new(name);
      
   endfunction


   virtual task body();
      
                    if (!uvm_config_db#(bit)::get(null, "ip_test", "relu", relu))
            `uvm_fatal("RELU_ERR",{"ReLu configuration must be set !!! ",get_full_name()})
      
      for (int i=1; i<limit; i++ )  begin

	       `uvm_do_with(req, { 
	                           req.config3[0]     == 0; 
	                           req.config3[1]     == relu;    //ReLu = True       
	                           req.config3[4:2]   == 0;       //not used
	                           req.config3[13:5]  == 10; 
	                           req.config3[31:14] == 100;
	                           req.config4[11:0]  == 0;
	                           req.config4[31:30] == 0;
	                           req.config4[29:12] == 64;
	                           req.config5[8:0]   == 8;
	                           req.config5[31:9]  == 0;
	                    });  
      end
   endtask : body

endclass : sequence1

`endif