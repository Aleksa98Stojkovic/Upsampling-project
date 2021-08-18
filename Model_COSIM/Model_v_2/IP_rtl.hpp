#ifndef IP_RTL_HPP_INCLUDED
#define IP_RTL_HPP_INCLUDED

#include "common.hpp"

class IP_rtl : public sc_core::sc_foreign_module
{
    public:

        // Constructor
        IP_rtl(sc_core::sc_module_name name) :
            sc_core::sc_foreign_module(name),
            clk_i("clk_i"),
            rst_i("rst_i"),
            config1("config1"),
            config2("config2"),
            config3("config3"),
            config4("config4"),
            config5("config5"),
            config6("config6"),
            axi_write_address_o("axi_write_address_o"),
            axi_write_init_o("axi_write_init_o"),
            axi_write_data_o("axi_write_data_o"),
            axi_write_next_i("axi_write_next_i"),
            axi_write_done_i("axi_write_done_i"),
            axi_read_init_o("axi_read_init_o"),
            axi_read_data_i("axi_read_data_i"),
            axi_read_addr_o("axi_read_addr_o"),
            axi_read_last_i("axi_read_last_i"),
            axi_read_valid_i("axi_read_valid_i"),
            axi_read_ready_o("axi_read_ready_o")
        {}

        // Clock and reset
        sc_core::sc_in<bool> clk_i;
        sc_core::sc_in<sc_dt::sc_logic> rst_i;

        // Config registers
        sc_core::sc_in<sc_dt::sc_lv<32>> config1;
        sc_core::sc_in<sc_dt::sc_lv<32>> config2;
        sc_core::sc_in<sc_dt::sc_lv<32>> config3;
        sc_core::sc_in<sc_dt::sc_lv<32>> config4;
        sc_core::sc_in<sc_dt::sc_lv<32>> config5;
        sc_core::sc_out<sc_dt::sc_lv<32>> config6;

        // Axi write port
        sc_core::sc_out<sc_dt::sc_lv<32>> axi_write_address_o;
        sc_core::sc_out<sc_dt::sc_logic> axi_write_init_o;
        sc_core::sc_out<sc_dt::sc_lv<64>> axi_write_data_o;
        sc_core::sc_in<sc_dt::sc_logic> axi_write_next_i;
        sc_core::sc_in<sc_dt::sc_logic> axi_write_done_i;

        // Axi read port
        sc_core::sc_out<sc_dt::sc_logic> axi_read_init_o;
        sc_core::sc_in<sc_dt::sc_lv<64>> axi_read_data_i;
        sc_core::sc_out<sc_dt::sc_lv<32>> axi_read_addr_o;
        sc_core::sc_in<sc_dt::sc_logic> axi_read_last_i;
        sc_core::sc_in<sc_dt::sc_logic> axi_read_valid_i;
        sc_core::sc_out<sc_dt::sc_logic> axi_read_ready_o;

        const char* hdl_name() const { return "IP_with_router_top"; }
};

#endif // IP_RTL_HPP_INCLUDED
