#ifndef IP_RTL_FULL_HPP_INCLUDED
#define IP_RTL_FULL_HPP_INCLUDED

#include "common.hpp"
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include "IP_rtl.hpp"
#include "Interfaces.hpp"

class IP_rtl_full : public sc_core::sc_module
{
    public:

        SC_HAS_PROCESS(IP_rtl_full);
        IP_rtl_full(sc_core::sc_module_name);

        // Interfaces
        tlm_utils::simple_target_socket<IP_rtl_full> bus_soc;        // Interconnect
        sc_core::sc_port<ip_rtl_full_dram_if> ip_rtl_full_dram_port; // DRAM

    protected:

        // Interface signals
        // Clock and reset
        sc_core::sc_clock clk_i;
        sc_core::sc_signal<sc_dt::sc_logic> rst_i;

        // Config registers
        sc_core::sc_signal<sc_dt::sc_lv<32>> config1;
        sc_core::sc_signal<sc_dt::sc_lv<32>> config2;
        sc_core::sc_signal<sc_dt::sc_lv<32>> config3;
        sc_core::sc_signal<sc_dt::sc_lv<32>> config4;
        sc_core::sc_signal<sc_dt::sc_lv<32>> config5;
        sc_core::sc_signal<sc_dt::sc_lv<32>> config6;

        // Axi write port
        sc_core::sc_signal<sc_dt::sc_lv<32>> axi_write_address_o;
        sc_core::sc_signal<sc_dt::sc_logic> axi_write_init_o;
        sc_core::sc_signal<sc_dt::sc_lv<64>> axi_write_data_o;
        sc_core::sc_signal<sc_dt::sc_logic> axi_write_next_i;
        sc_core::sc_signal<sc_dt::sc_logic> axi_write_done_i;

        // Axi read port
        sc_core::sc_signal<sc_dt::sc_logic> axi_read_init_o;
        sc_core::sc_signal<sc_dt::sc_lv<64>> axi_read_data_i;
        sc_core::sc_signal<sc_dt::sc_lv<32>> axi_read_addr_o;
        sc_core::sc_signal<sc_dt::sc_logic> axi_read_last_i;
        sc_core::sc_signal<sc_dt::sc_logic> axi_read_valid_i;
        sc_core::sc_signal<sc_dt::sc_logic> axi_read_ready_o;

        // Component
        IP_rtl ip_rtl;

        // Processes
        void AXI_read();
        void AXI_write();
        void Reset();
        void ChangeConfig();

        // TLM
        typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
        void b_transport_bus(pl_t& pl, sc_core::sc_time& offset);
};

#endif // IP_RTL_FULL_HPP_INCLUDED
