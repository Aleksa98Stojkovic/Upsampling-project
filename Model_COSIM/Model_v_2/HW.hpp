#ifndef HW_HPP_INCLUDED
#define HW_HPP_INCLUDED

#include "common.hpp"
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include "DRAM.hpp"
#include "IP_rtl_full.hpp"
#include "Interconnect.hpp"

class HW : public sc_core::sc_module
{

    public:

        HW(sc_core::sc_module_name);

        // Interfaces
        tlm_utils::simple_target_socket<HW> cpu_soc; // SW

    protected:

        tlm_utils::simple_initiator_socket<HW> Interconnect_soc;
        DRAM dram;
        IP_rtl_full ip_rtl_full;
        Interconnect interconnect;

        typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
        void b_transport_cpu(pl_t&, sc_core::sc_time&);


};


#endif // HW_HPP_INCLUDED
