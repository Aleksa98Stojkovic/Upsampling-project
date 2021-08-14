#ifndef INTERCONNECT_HPP_INCLUDED
#define INTERCONNECT_HPP_INCLUDED

#include "common.hpp"
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>

class Interconnect : public sc_core::sc_module
{
    public:

        Interconnect(sc_core::sc_module_name);

        // Interfaces
        tlm_utils::simple_initiator_socket<Interconnect> config_soc;
        tlm_utils::simple_target_socket<Interconnect> cpu_soc;

    protected:

        typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
        void b_transport_cpu(pl_t&, sc_core::sc_time&);
};




#endif // INTERCONNECT_HPP_INCLUDED
