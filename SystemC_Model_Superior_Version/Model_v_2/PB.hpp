#ifndef PB_HPP_INCLUDED
#define PB_HPP_INCLUDED

#include "common.hpp"
#include "Interfaces.hpp"

class PB : public sc_core::sc_channel, public cache_pb_if, public reg_pb_if
{

        public:
        SC_HAS_PROCESS(PB);
        PB(sc_core::sc_module_name);

        // ---- Interfaces ---- //
        sc_core::sc_port<pb_cache_if> pb_cache_port; // CACHE
        sc_core::sc_port<pb_dram_if> pb_dram_port;   // DRAM
        sc_core::sc_port<pb_wmem_if> pb_wmem_port;   // WMEM


    protected:

        // ---- PB SAHE ---- //
        int write_base_address;
        int num_of_pix;
        int bias_base_address;
        int output_width;
        int relu;

        // ---- Internals ---- //
        std::vector<data_point> bias;
        std::vector<data_point> data_stick;

        // ---- Processes ---- //
        void Process();

        // ---- Helper functions ---- //

        // Events
        sc_core::sc_event run;

        // Hierarchical channels
        void write_cache_pb(std::vector<data_point> &data);
        void run_cache_pb();
        void write_reg_pb(const int sahe_number, int &data);


};


#endif // PB_HPP_INCLUDED
