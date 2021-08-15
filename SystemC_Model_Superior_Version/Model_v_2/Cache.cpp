#include "Cache.hpp"

using namespace std;
using namespace sc_core;

Cache::Cache(sc_module_name name) :
    sc_channel(name)
{

    SC_THREAD(Process);
    sensitive << run;
    dont_initialize();

    // Filling in the line vector
    for(int i = 0; i < CACHE_LINE; i++)
        line.push_back(i);

    cout << "Cache::Cache is constructed!" << endl;
}

// Transforms data from DDR to a suitable form
void Cache::transformDramData(vector<dram_word> &dram_data, vector<data_point> &data)
{
    data.clear();

    for(int i = 0; i < (int)dram_data.size(); i++) // 16 iterations
    {
        for(int j = 0; j < (BUS_BIT_WIDTH / DATA_BIT_WIDTH); j++) // 4 iterations
        {
            dram_word temp1 = (((long long int)MASK << (j * DATA_BIT_WIDTH)) & dram_data[i]) >> (j * DATA_BIT_WIDTH);
            data_point temp = temp1;
            // Is this a negative number?
            if(temp & (1 << DATA_BIT_WIDTH - 1))
            {
                //cout << "Cache::Negative number detected" << endl;
                temp |= ONES; // adding additional ones to represent negative numbers in two's complement
            }

            // cout << "Cache::size of an integer is: " << sizeof(data_point) << endl;
            //cout << "Cache::temp = " << hex << temp << endl;

            data.push_back(temp);
        }
    }
}

// Fills amount_hash with the right amount of lives
void Cache::insertAmountHash(int amount_hash[], const int &col, const int &cache_line)
{
    int temp = col;

    if((temp == 0) || (temp == (total / height) - 1))
    {
        amount_hash[cache_line] = 1;
    }
    else if((temp == 1) || (temp == (total / height) - 2))
    {
        amount_hash[cache_line] = 2;
    }
    else
        amount_hash[cache_line] = 3;
}

// Main process
void Cache::Process()
{

    int state = 0;
    int row;
    int col;
    vector<dram_word> dram_data;
    vector<data_point> data;
    vector<int> empty_lines;
    int cnt_req = 0;
    int last_req = 0;
    int shift_amount;

    while(true)
    {
        switch(state)
        {
            case 0: // Initial state for filling cache
                {
                    for(int i = 0; i < CACHE_LINE / 3; i++)
                    {
                        for(int j = 0; j < 3; j++)
                        {
                            col = i;
                            row = j;
                            dram_data.clear();
                            cache_router_port->read_cache_router((col * height + row) * (DATA_DEPTH / 4), dram_data);
                            transformDramData(dram_data, data);
                            cache_data.push_back(data);

                            insertAmountHash(amount_hash, col, i * 3 + j);
                        }
                    }

                    // Generate a signal for starting other modules
                    cache_pb_port->run_cache_pb();

                    // Deciding what is going to be the next state
                    state = 1;

                    // resetting row number
                    row = 0;

                    break;
                }

            case 1:
                {
                    vector<data_point> data_stick;
                    // waiting for PB to send a command
                    wait();
                    cnt_req++; // counts the number of requests sent by PB

                    // cout << "Cache::Request number: " << cnt_req << endl;

                    // Reading data from cache memory
                    for(int i = 0; i < KERNEL_SIZE; i++)
                    {
                        int cache_line = line[i];

                        for(int j = 0; j < (int)cache_data[cache_line].size(); j++)
                        {
                            data_stick.push_back(cache_data[cache_line][j]);
                        }

                        // memorizing empty lines
                        amount_hash[cache_line]--;
                        if(amount_hash[cache_line] == 0)
                            empty_lines.push_back(cache_line);
                    }

                    // Shifting line vector
                    //shift_amount = (int)empty_lines.size();
                    if(cnt_req % (total / height - 2) == 0)
                        shift_amount = 9;
                    else
                        shift_amount = 3;

                    for(int i = 0; i < shift_amount; i++)
                    {
                        int temp = line[0];
                        line.erase(line.begin());
                        line.push_back(temp);
                    }

                    // Check if its the last one
                    if(cnt_req == (total / height - 2) * (height - 2))
                        last_req = 1;

                    // Decide next state
                    if(empty_lines.empty())
                        state = 1; // read
                    else
                        state = 2; // write

                    // cout << "Cache::data_stick size is: " << data_stick.size() << endl;

                    // Sending data to PB

                    cache_pb_port->write_cache_pb(data_stick);

                    // cout << "Cache::I am here!" << endl;

                    break;
                }
            case 2:
                {

                    if(col == (total / height - 1)) // Check if we are at the last column
                    {
                        col = 0;

                        if(row < height - 2)
                            row++;
                    }
                    else
                        col++;

                    for(int i = 0; i < 3; i++)
                    {
                        int cache_line = empty_lines[0];
                        empty_lines.erase(empty_lines.begin());

                        dram_data.clear();
                        cache_router_port->read_cache_router((col * height + row + i) * (DATA_DEPTH / 4), dram_data);
                        transformDramData(dram_data, data);
                        cache_data[cache_line] = data;

                        insertAmountHash(amount_hash, col, cache_line);

                    }

                    // Calculating next state based on shoft_amount
                    shift_amount -= 3;
                    if(shift_amount > 0)
                        state = 2;
                    else
                        state = 1;

                    break;
                }

            default:
                cout << "CACHE::Something went wrong, unkonwn state!" << endl;
        }

        // Deciding to finish
        if(last_req)
            break;
    }
}

void Cache::read_pb_cache()
{
    // This will unblock cache process
    run.notify();
}
void Cache::write_reg_cache(const int sahe_number, int &data)
{
    switch(sahe_number)
    {
        case HEIGHT_SAHE:
            height = data;
            break;
        case TOTAL_SAHE:
            total = data;
            break;
        case CACHE_START_SAHE:
            start = data;
            run.notify();
            break;
        default:
            cout << "CACHE::This SAHE does not exist!" << endl;
    }
}

