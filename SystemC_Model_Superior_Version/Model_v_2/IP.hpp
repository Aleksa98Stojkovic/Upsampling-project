#ifndef IP_HPP_INCLUDED
#define IP_HPP_INCLUDED

#include "common.hpp"
#include "PB.hpp"
#include "Cache.hpp"
#include "WMEM.hpp"
#include "Router.hpp"

class IP : public sc_core::sc_module
{
    public:

        IP(sc_core::sc_module_name);

        // Components
        Cache  cache;
        PB     pb;
        WMEM   wmem;
        Router router;
};



#endif // IP_HPP_INCLUDED
