#ifndef COMMON_H_INCLUDED
#define COMMON_H_INCLUDED

#include <vector>
#include <iostream>
#include <string>
#include <cstdlib>
#include <cmath>
#include <stack>
#include <fstream>
#include <string>
#include <sstream>
/**/
/* Treba dodati onu biblioteku za rad sa 64-bitnim int brojevima */
/**/

#define DP 11
#define MAC_WIDTH 32
#define MASK 0x80000000
#define DATA_MASK 0x000000000000ffff
#define DATA_WIDTH 16

typedef double t;
typedef unsigned long long int dram_word; /**//* Zameni unsigned long long int sa uint64_t *//**/
typedef long long int sint64;             /**//* Zameni long long int sa int64_t *//**/
typedef std :: vector < std :: vector < std :: vector <t>>> float3D;
typedef std :: vector < std :: vector < std :: vector < std :: vector <t>>>> float4D;
const std :: vector <t> mean = {114.44399999999999, 111.4605, 103.02000000000001};

// Dodatne funkcije
// kakav pointer vraca drajver? Verovatno unsigned char
void Write_DRAM_content(std::vector <dram_word> &data, std::vector <dram_word> &weights, dram_word* dram);
// Konvertujemo fixed point u float
t Fxp2Float(dram_word *data); // Ovo treba proveriti
// Konvertujemo float u fixed point
dram_word Float2Fxp(t &data, int n, int f); // proveriti ovu funkciju!
// Formatiramo podatke kako bi ih IP razumeo i kvantizujemo ih
void formatData(std::vector <dram_word> &data_o, float3D &data_i);
// Formatiramo tezine kako bi ih IP razumeo, tezine su vec kvantizovane
void formatWeight(std::vector <dram_word> &weight_o, std::string path); // Podaci se nalaze u txt fajlu koji je foramtiran kako treba
// Pretvara podatke koje dobija od IP-ja u float i upisuje ih u dobrom redosledu
void formatDataIP(float3D &data, dram_word* data_ip);
// Dodaje nule oko ulaza
void zero_padding(float3D &data);
// Dodaje nule za prvu konvoluciju, jer je tamo broj kanala jednak 3
void zero_padding_input(float3D &data);
// Upis u drajver
void write_driver(std::string path, int reg_num, int val);
// Citanje iz drajvera
int read_driver(std::string path, bool read_pointer); // ako je read_pointer = false -> cita se config, a u suprotnom pokazivac
// Radi malu konvoluciju
void convlove(float3D &data_i, std::string w_path, int layer_num, int relu);
#endif // COMMON_H_INCLUDED
