#ifndef CONFIG_HPP_INCLUDED
#define CONFIG_HPP_INCLUDED

#include "common.hpp"
#include "Interfaces.hpp"
#include <tlm>
#include <tlm_utils/simple_target_socket.h>

class Config : public sc_core::sc_module
{
    public:

        Config(sc_core::sc_module_name);

        // Interfaces
        sc_core::sc_port<reg_pb_if> reg_pb_port;         // PB
        sc_core::sc_port<reg_wmem_if> reg_wmem_port;     // WMEM
        sc_core::sc_port<reg_cache_if> reg_cache_port;   // CACHE
        sc_core::sc_port<reg_router_if> reg_router_port; // Router

        tlm_utils::simple_target_socket<Config> bus_soc; // Interconnect

    private:

        // TLM communication
        typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
        void b_transport_config(pl_t&, sc_core::sc_time&);
};

#endif // CONFIG_HPP_INCLUDED
