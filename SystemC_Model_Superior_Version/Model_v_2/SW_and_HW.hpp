#ifndef SW_AND_HW_HPP_INCLUDED
#define SW_AND_HW_HPP_INCLUDED

#include "common.hpp"
#include <tlm_utils/simple_initiator_socket.h>

class SW_and_HW : public sc_core::sc_module
{
    public:

        SC_HAS_PROCESS(SW_and_HW);
        SW_and_HW(sc_core::sc_module_name);

        // Interfaces
        tlm_utils::simple_initiator_socket<SW_and_HW> soc;

    protected:

        // Process
        void Software();

        // TLM
        typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;


};

#endif // SW_AND_HW_HPP_INCLUDED
