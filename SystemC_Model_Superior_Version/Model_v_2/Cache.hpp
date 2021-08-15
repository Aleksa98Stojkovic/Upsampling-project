#ifndef CACHE_HPP_INCLUDED
#define CACHE_HPP_INCLUDED

#include "common.hpp"
#include "Interfaces.hpp"

class Cache : public sc_core::sc_channel, public reg_cache_if, public pb_cache_if
{
    public:
        SC_HAS_PROCESS(Cache);
        Cache(sc_core::sc_module_name);

        // ---- Interfaces ---- //
        sc_core::sc_port<cache_pb_if> cache_pb_port;         // PB
        sc_core::sc_port<cache_router_if> cache_router_port; // Router

    protected:

        // ---- Cache SAHE ---- //
        int height;
        int total;
        int start;

        // ---- Internals ---- //
        int amount_hash[CACHE_LINE];
        std::vector<std::vector<data_point>> cache_data;
        std::vector<unsigned char> line;
        const int base_address = BASE_ADDRESS;

        // ---- Processes ---- //
        void Process();

        // ---- Helper functions ---- //
        void transformDramData(std::vector<dram_word> &dram_data, std::vector<data_point> &data);
        void insertAmountHash(int amount_hash[], const int &address, const int &cache_line);

        // Events
        sc_core::sc_event run;

        // Hierarchical channels
        void read_pb_cache();
        void write_reg_cache(const int sahe_number, int &data);

};



#endif // CACHE_HPP_INCLUDED
