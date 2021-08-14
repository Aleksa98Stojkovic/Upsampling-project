----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.07.2021 14:54:03
-- Design Name: 
-- Module Name: bias_ROM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bias_ROM is
    generic(
         width      : natural := 32;
         addr_width : natural := 6; 
         size       : natural := 64);
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         
         ------------------- Input data interface -------------------
         addr_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         ------------------- Output data interface -------------------
         rdata_o : out std_logic_vector(width - 1 downto 0)
         );
end bias_ROM;

architecture Behavioral of bias_ROM is

type rom_type is array(0 to size - 1) of std_logic_vector(width - 1 downto 0);

-- Funkcija koja inicijalizuje BRAM preko txt fajla --
impure function init_rom_hex return rom_type is
  file text_file : text open read_mode is "D:\Vivado_projekti\rom_hex.txt"; -- staviti apsolutnu adresu
  variable text_line : line;
  variable rom_content : rom_type;
  variable c : character;
  variable offset : integer;
  variable hex_val : std_logic_vector(3 downto 0);
begin
  for i in 0 to size - 1 loop
    readline(text_file, text_line);
 
    offset := 0;
 
    while offset < rom_content(i)'high loop
      read(text_line, c);
 
      case c is
        when '0' => hex_val := "0000";
        when '1' => hex_val := "0001";
        when '2' => hex_val := "0010";
        when '3' => hex_val := "0011";
        when '4' => hex_val := "0100";
        when '5' => hex_val := "0101";
        when '6' => hex_val := "0110";
        when '7' => hex_val := "0111";
        when '8' => hex_val := "1000";
        when '9' => hex_val := "1001";
        when 'A' | 'a' => hex_val := "1010";
        when 'B' | 'b' => hex_val := "1011";
        when 'C' | 'c' => hex_val := "1100";
        when 'D' | 'd' => hex_val := "1101";
        when 'E' | 'e' => hex_val := "1110";
        when 'F' | 'f' => hex_val := "1111";
 
        when others =>
          hex_val := "XXXX";
          assert false report "Found non-hex character '" & c & "'";
      end case;
 
      rom_content(i)(rom_content(i)'high - offset
        downto rom_content(i)'high - offset - 3) := hex_val;
      offset := offset + 4;
 
    end loop;
  end loop;
 
  return rom_content;
end function;

signal bram : rom_type := (others => (others => '0'));
--signal bram : rom_type := (X"0000001c",
--X"0000000e",
--X"0000002f",
--X"00000020",
--X"00000038",
--X"00000031",
--X"00000009",
--X"00000032",
--X"00000008",
--X"00000013",
--X"00000005",
--X"00000021",
--X"00000036",
--X"00000010",
--X"0000002d",
--X"00000030",
--X"0000003c",
--X"0000000a",
--X"00000018",
--X"00000012",
--X"0000002e",
--X"0000003d",
--X"00000019",
--X"00000027",
--X"0000000f",
--X"00000034",
--X"0000003f",
--X"00000022",
--X"00000001",
--X"00000007",
--X"00000037",
--X"0000003e",
--X"0000001a",
--X"00000029",
--X"00000003",
--X"0000003a",
--X"00000026",
--X"0000001d",
--X"00000024",
--X"0000003b",
--X"00000014",
--X"00000015",
--X"00000035",
--X"0000000d",
--X"00000011",
--X"00000023",
--X"0000001f",
--X"0000000b",
--X"00000017",
--X"0000001b",
--X"0000002a",
--X"00000039",
--X"0000000c",
--X"0000002b",
--X"00000016",
--X"00000025",
--X"00000028",
--X"00000000",
--X"00000002",
--X"00000006",
--X"0000001e",
--X"00000033",
--X"0000002c",
--X"00000004"
--);



begin

memory : process(clk_i)
begin
   
    if(rising_edge(clk_i)) then

        rdata_o <= bram(to_integer(unsigned(addr_i)));
        
    end if;

end process;

end Behavioral;
