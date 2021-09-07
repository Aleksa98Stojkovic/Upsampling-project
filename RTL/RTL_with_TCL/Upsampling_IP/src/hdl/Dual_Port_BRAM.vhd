----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.07.2021 21:31:27
-- Design Name: 
-- Module Name: Dual_Port_BRAM - Behavioral
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
--use std.textio.all;

entity Dual_Port_BRAM is
    generic(
         width      : natural := 64;
         addr_width : natural := 10; 
         size       : natural := 576);
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         
         ------------------- Input data interface -------------------
         --write0_i : in std_logic;
         --wdata0_i : in std_logic_vector(width - 1 downto 0);
         addr0_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         write1_i : in std_logic;
         wdata1_i : in std_logic_vector(width - 1 downto 0);
         addr1_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         ------------------- Output data interface -------------------
         rdata0_o : out std_logic_vector(width - 1 downto 0);
         rdata1_o : out std_logic_vector(width - 1 downto 0)
      
         
         );
end Dual_Port_BRAM;

architecture Behavioral of Dual_Port_BRAM is

type ram_type is array(0 to size - 1) of std_logic_vector(width - 1 downto 0);

---- Funkcija koja inicijalizuje BRAM preko txt fajla --
--impure function init_ram_hex return ram_type is
--  file text_file : text open read_mode is "D:\Vivado_projekti\rom_hex.txt"; -- staviti apsolutnu adresu
--  variable text_line : line;
--  variable ram_content : ram_type;
--  variable c : character;
--  variable offset : integer;
--  variable hex_val : std_logic_vector(3 downto 0);
--begin
--  for i in 0 to size - 1 loop
--    readline(text_file, text_line);
 
--    offset := 0;
 
--    while offset < ram_content(i)'high loop
--      read(text_line, c);
 
--      case c is
--        when '0' => hex_val := "0000";
--        when '1' => hex_val := "0001";
--        when '2' => hex_val := "0010";
--        when '3' => hex_val := "0011";
--        when '4' => hex_val := "0100";
--        when '5' => hex_val := "0101";
--        when '6' => hex_val := "0110";
--        when '7' => hex_val := "0111";
--        when '8' => hex_val := "1000";
--        when '9' => hex_val := "1001";
--        when 'A' | 'a' => hex_val := "1010";
--        when 'B' | 'b' => hex_val := "1011";
--        when 'C' | 'c' => hex_val := "1100";
--        when 'D' | 'd' => hex_val := "1101";
--        when 'E' | 'e' => hex_val := "1110";
--        when 'F' | 'f' => hex_val := "1111";
 
--        when others =>
--          hex_val := "XXXX";
--          assert false report "Found non-hex character '" & c & "'";
--      end case;
 
--      ram_content(i)(ram_content(i)'high - offset
--        downto ram_content(i)'high - offset - 3) := hex_val;
--      offset := offset + 4;
 
--    end loop;
--  end loop;
 
--  return ram_content;
--end function;

--signal bram : ram_type := init_ram_hex;
signal bram : ram_type  := (others => (others => '0'));


begin

memory_port0 : process(clk_i)
begin
   
    if(rising_edge(clk_i)) then

        if(write1_i = '1') then
            bram(to_integer(unsigned(addr1_i))) <= wdata1_i;
        end if;
        
        rdata0_o <= bram(to_integer(unsigned(addr0_i)));
        rdata1_o <= bram(to_integer(unsigned(addr1_i)));
        
    end if;

end process;


--memory_port1 : process(clk_i)
--begin
   
--    if(rising_edge(clk_i)) then

--        if(write1_i = '1') then
--            bram(to_integer(unsigned(addr1_i))) <= wdata1_i;
--        end if;
        
--        rdata1_o <= bram(to_integer(unsigned(addr1_i)));
        
--    end if;

--end process;

end Behavioral;

