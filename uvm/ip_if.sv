`ifndef IP_IF_SV
 `define IP_IF_SV

interface ip_if (input clk, logic rst);

parameter CONFIG_WIDTH = 32;
parameter DATA_WIDTH = 64;
parameter ADDRESS_WIDTH = 32;

//inputs to dut
   logic [CONFIG_WIDTH - 1 : 0]   config1;
   logic [CONFIG_WIDTH - 1 : 0]   config2;
   logic [CONFIG_WIDTH - 1 : 0]   config3;
   logic [CONFIG_WIDTH - 1 : 0]   config4;
   logic [CONFIG_WIDTH - 1 : 0]   config5;
   logic                          axi_write_done_i;
   logic                          axi_write_next_i;
   logic [DATA_WIDTH - 1 : 0]     axi_read_data_i;
   logic                          axi_read_last_i;   
   logic                          axi_read_valid_i;
//outputs to dut
   logic [CONFIG_WIDTH - 1 : 0]   config6;
   logic                          axi_write_init_o;
   logic [DATA_WIDTH - 1 : 0]     axi_write_data_o;
   logic [ADDRESS_WIDTH - 1 : 0]  axi_write_address_o;
   logic                          axi_read_ready_o;
   logic                          axi_read_init_o;
   logic [ADDRESS_WIDTH - 1 : 0]  axi_read_address_o;
   
endinterface : ip_if

`endif