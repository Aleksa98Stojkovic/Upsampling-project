`timescale 1ns/1ps

module ip_verif_top;

   import uvm_pkg::*;     // import the UVM library
`include "uvm_macros.svh" // Include the UVM macros

   import ip_test_pkg::*;

   logic clk;
   logic rst = 0;

   // interface
   ip_if vif(clk, rst);

   
   // DUT
   IP_with_router_top DUT(
                .clk_i      ( clk ),
                .rst_i      ( rst ),
                .config1    ( vif.config1 ),
                .config2    ( vif.config2 ),
                .config3    ( vif.config3 ),
                .config4    ( vif.config4 ),
                .config5    ( vif.config5 ),
                .config6    ( vif.config6 ),
                .axi_write_address_o    ( vif.axi_write_address_o ),
                .axi_write_init_o       ( vif.axi_write_init_o ),
                .axi_write_data_o       ( vif.axi_write_data_o ),
                .axi_write_next_i       ( vif.axi_write_next_i ),
                .axi_write_done_i       ( vif.axi_write_done_i ),
                .axi_read_init_o        ( vif.axi_read_init_o ),
                .axi_read_data_i        ( vif.axi_read_data_i ),
                .axi_read_addr_o        ( vif.axi_read_address_o ),
                .axi_read_last_i        ( vif.axi_read_last_i ),
                .axi_read_valid_i       ( vif.axi_read_valid_i ),
                .axi_read_ready_o       ( vif.axi_read_ready_o )
                );

   // run test
   initial begin     
       uvm_config_db#(virtual ip_if)::set(null, "uvm_test_top.env", "ip_if", vif);
       run_test("ip_test1");
   end
   // clock and reset init.
   initial begin
       clk <= 1;                  
       rst <= 1;
       for (int i = 0; i < 8; i++) begin
	   @(posedge clk);
       end
       rst <= 0;
   end

   // clock generation
   always #50 clk = ~clk;

endmodule : ip_verif_top