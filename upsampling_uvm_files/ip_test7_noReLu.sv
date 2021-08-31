`ifndef IP_TEST7_NORELU_SV
`define IP_TEST7_NORELU_SV

`include "ip_seq_pkg.sv"
import ip_seq_pkg::*;

    `include "envireonment.sv"   

class ip_test7_noReLu extends test_base;

    `uvm_component_utils(ip_test7_noReLu)
    
    sequence1 seq1;
    
    function new(string name = "ip_test7_noReLu", uvm_component parent = null);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        seq1 = sequence1::type_id::create("seq1");
        
        uvm_config_db #(string)::set(null, "ip_test", "input_fp", "dram_content7.txt");
        uvm_config_db #(string)::set(null, "ip_test", "result_fp", "result7.txt");
        uvm_config_db #(bit)::set(null, "ip_test", "relu", 0);
    endfunction : build_phase

    task main_phase(uvm_phase phase);
        phase.raise_objection(this );
        seq1.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask : main_phase

endclass

`endif