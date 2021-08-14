#ifndef WMEM_HPP_INCLUDED
#define WMEM_HPP_INCLUDED

#include "common.hpp"
#include "Interfaces.hpp"

class WMEM : public sc_core::sc_channel, public pb_wmem_if, public reg_wmem_if
{

    public:
        WMEM(sc_core::sc_module_name);

        // ---- Interfaces ---- //

    protected:

        // ---- WMEM SAHE ---- //
        int weight_base_address;
        int start;

        // ---- Internals ---- //
        std::vector< std::vector<data_point>> weights;

        // ---- Processes ---- //

        // ---- Helper functions ---- //

        // Events

        // Hierarchical channels
        void read_pb_wmem(const int &packet, std::vector<data_point> &data);
        void write_reg_wmem(const int sahe_number, int &data);
};




#endif // WMEM_HPP_INCLUDED
