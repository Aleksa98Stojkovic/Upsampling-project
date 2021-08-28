`ifndef IP_COV_COL_SV
`define IP_COV_COL_SV

class ip_cov_col extends uvm_scoreboard;

	uvm_analysis_imp#(ip_seq_item, ip_cov_col) cc_item_collected_port;

	`uvm_component_utils(ip_cov_col)
    //`uvm_analysis_imp(cc_item_collected_port)
	
    int data_a, num_of_data_a;
  //clone items
    ip_seq_item clone_item;

	extern function new(string name = "ip_cov_col", uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);	
 	extern virtual function void write(ip_seq_item if_item);

// coverage
 covergroup ip_cg;
    option.per_instance = 1;
    //*******READ OPERATIONS BINS*******
    RAddr : coverpoint clone_item.axi_read_address {
        bins ADDR_READ = {[32'h0 : 32'h15000]} with (item % 512 ==0);
    }
    RInit: coverpoint clone_item.axi_read_init {
        option.goal = 230;
        bins READ_INIT_HAPPENED = {1};
    }
    RReady: coverpoint clone_item.axi_read_ready {
        bins READ_READY_HAPPENED = {1};
    }
    RValid: coverpoint clone_item.axi_read_valid {
        bins READ_VALID_HAPPENED = {1};
    }
    RLast: coverpoint clone_item.axi_read_last {
        option.goal = 229;
        bins READ_LAST_HAPPENED = {1};
    }
    CxRdyVal: cross RReady, RValid {
        option.at_least = 10816;
        bins RdyValOL = binsof(RReady.READ_READY_HAPPENED) && binsof(RValid.READ_VALID_HAPPENED);
    }
    
    //*******WRITE OPERATIONS BINS*******
    WAddr : coverpoint clone_item.axi_write_address {
        bins ADDR_WRITE = {[32'h15200 : 32'h1D000]} with (item % 512 == 0);
    }    
    WInit: coverpoint clone_item.axi_write_init {
        option.goal = 64;
        bins WRITE_INIT_HAPPENED = {1};
    }
    WNext: coverpoint clone_item.axi_write_next {
        option.at_least = 4096;
        bins WRITE_NEXT_HAPPENED = {1};
    }
    WDone: coverpoint clone_item.axi_write_done {
        option.goal = 64;
        bins WRITE_DONE_HAPPENED = {1};
    }  
    WDnNxt: cross WDone, WNext {
        illegal_bins DnNxtOL = binsof(WDone.WRITE_DONE_HAPPENED) && binsof(WNext.WRITE_NEXT_HAPPENED) intersect {1};
    }

  endgroup : ip_cg

endclass

// constructor
function ip_cov_col::new(string name = "ip_cov_col", uvm_component parent);
  super.new(name,parent);
    ip_cg = new();
    cc_item_collected_port = new("cc_item_collected_port", this);
endfunction : new

function void ip_cov_col::build_phase(uvm_phase phase);
	super.build_phase(phase);
endfunction: build_phase

function void ip_cov_col::write(ip_seq_item if_item);
	$cast(clone_item,if_item.clone());	
    ip_cg.sample();
endfunction: write

`endif // IP_COV_COL_SV