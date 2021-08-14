#include "IP.hpp"

using namespace std;
using namespace sc_core;

IP::IP(sc_module_name name) :
    sc_module(name),
    pb("Processing_Block"),
    cache("Cache"),
    wmem("Memory"),
    router("Router")

{
    // Cache ports
    cache.cache_pb_port.bind(pb);
    cache.cache_router_port.bind(router);

    // PB ports
    pb.pb_cache_port.bind(cache);
    pb.pb_wmem_port.bind(wmem);

    cout << "IP is created!" << endl;
}
