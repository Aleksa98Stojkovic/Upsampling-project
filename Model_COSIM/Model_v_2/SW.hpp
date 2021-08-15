#ifndef SW_HPP_INCLUDED
#define SW_HPP_INCLUDED

#include "common.hpp"
#include <tlm_utils/simple_initiator_socket.h>

class SW : public sc_core::sc_module
{
    public:

        SC_HAS_PROCESS(SW);
        SW(sc_core::sc_module_name);

        // Interfaces
        tlm_utils::simple_initiator_socket<SW> soc;

    protected:

        // Process
        void Software();

        // TLM
        typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;


};


#endif // SW_HPP_INCLUDED
