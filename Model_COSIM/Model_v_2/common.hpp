#ifndef COMMON_HPP_INCLUDED
#define COMMON_HPP_INCLUDED

#include <systemc>
#include <fstream>
#include <string>
#include <vector>

#define CACHE_LINE 15
#define BASE_ADDRESS 0
#define DATA_BIT_WIDTH 16
#define BUS_BIT_WIDTH 64
#define MASK 0x000000000000ffff
#define DATA_DEPTH 64
#define KERNEL_SIZE 9
#define INPUT_DRAM_SIZE 10 * 10 * 16
#define OUTPUT_DRAM_SIZE 8 * 8 * 64
#define ONES 0xffff0000
#define BURST_LEN 64

#define HEIGHT_SAHE 0
#define TOTAL_SAHE 1
#define CACHE_START_SAHE 2

#define WRITE_BASE_ADDRESS_SAHE 0
#define NUM_OF_PIX_SAHE 1
#define BIAS_BASE_ADDRESS_SAHE 2
#define OUTPUT_WIDTH_SAHE 3
#define RELU_SAHE 4

#define WEIGHT_BASE_ADDRESS_SAHE 0
#define WMEM_START_SAHE 1

#define CONFIG1 0
#define CONFIG2 1
#define CONFIG3 2
#define CONFIG4 3
#define CONFIG5 4
#define CONFIG6 5

#define C3_MASK0 0x00000001
#define C3_MASK1 0x00000002
#define C3_MASK2 0x00000008
#define C3_MASK3 0x00000010
#define C3_MASK4 0x00003fe0 /* 0000 0000 0000 0000 0011 1111 1110 0000 */
#define C3_MASK5 0xffffc000 /* 1111 1111 1111 1111 1100 0000 0000 0000 */

#define C4_MASK1 0x00000fff /* 0000 0000 0000 0000 0000 1111 1111 1111 */
#define C4_MASK2 0x3ffff000 /* 0011 1111 1111 1111 1111 0000 0000 0000 */

#define CLK_PERIOD 10

#define WMEM_TRANS 576*16/64


typedef sc_dt::uint64 dram_word;
typedef int data_point;

#endif // COMMON_HPP_INCLUDED
