#ifndef ROUTER_HPP_INCLUDED
#define ROUTER_HPP_INCLUDED

#include "common.hpp"
#include "Interfaces.hpp"

class Router : public sc_core::sc_channel, public cache_router_if, public reg_router_if
{
    public:

        Router(sc_core::sc_module_name);

        // ---- Interfaces ---- //
        sc_core::sc_port<router_dram_if> router_dram_port; // DRAM

    protected:

        // ---- Router SAHE ---- //
        int sel_mux;

        // ---- Internals ---- //

        // ---- Processes ---- //

        // ---- Helper functions ---- //

        // Events

        // Hierarchical channels
        void read_cache_router(const int &address, std::vector<dram_word> &data);
        void write_reg_router(int &data);
};

#endif // ROUTER_HPP_INCLUDED
