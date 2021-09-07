----------------------------------------------------------------------------------
-- Company: FTN
-- Engineer: Aleksa Stojkovic, Boris Radovanovic
-- 
-- Create Date: 07/17/2021 10:15:31 PM
-- Design Name: 
-- Module Name: RF_for_write - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity RF_for_write is
  generic(
       RF_size : natural := 15;
       addr_width : natural := 4);
  Port(
       --------------- Clocking and reset interface ---------------
       clk_i : in std_logic;
       rst_i : in std_logic;
       
       --------------- Input interface ---------------
       empty_line_i : std_logic;
       en_i : in std_logic;
       write_i : in std_logic;
       wdata_i : in std_logic;
       
       --------------- Output interface ---------------
       rdata_o : out std_logic;
       wcounter_o : out std_logic_vector(addr_width - 1 downto 0)
       
       );
end RF_for_write;

architecture Behavioral of RF_for_write is

-- Counters --
signal counter1, counter2 : std_logic_vector(addr_width - 1 downto 0);

signal en : std_logic;

-- Register File --
type RF_type is array(0 to RF_size - 1) of std_logic;
signal RF : RF_type;
-- Write port 1 --
signal write1 : std_logic;
signal wdata1 : std_logic;
signal waddress1 : std_logic_vector(addr_width - 1 downto 0);
-- Write port 2 --
signal write2 : std_logic;
signal wdata2 : std_logic;
signal waddress2 : std_logic_vector(addr_width - 1 downto 0);
-- Read port --
signal rdata : std_logic;
signal raddress : std_logic_vector(addr_width - 1 downto 0);

-- Comparators --
signal comp1, comp2 : std_logic;

begin

First_Counter : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            counter1 <= (others => '0'); 
        else
            if(empty_line_i = '1') then
                if(comp1 = '1') then
                    counter1 <= (others => '0');    
                else
                    counter1 <= std_logic_vector(unsigned(counter1) + to_unsigned(1, counter1'length));
                end if;
            else
                counter1 <= counter1;
            end if;
        end if;
    end if;
end process;


Second_Counter : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            counter2 <= (others => '0'); 
        else
            if(en = '1') then
                if(comp2 = '1') then
                    counter2 <= (others => '0');    
                else
                    counter2 <= std_logic_vector(unsigned(counter2) + to_unsigned(1, counter2'length));
                end if;
            else
                counter2 <= counter2;
            end if;
        end if;
    end if;
end process;

en <= en_i;

Comparator1:
comp1 <= '1' when counter1 = std_logic_vector(to_unsigned(RF_size - 1, counter1'length)) else
         '0';

Comparator2:
comp2 <= '1' when counter2 = std_logic_vector(to_unsigned(RF_size - 1, counter2'length)) else
         '0';

wcounter_o <= counter2;

Register_file : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            RF <= (others => '0');
        else
            if(write1 = '1') then
                RF(to_integer(unsigned(waddress1))) <= wdata1;
            end if;
            
            if(write2 = '1') then
                RF(to_integer(unsigned(waddress2))) <= wdata2;
            end if;
        end if; 
    end if;
end process;

rdata <= RF(to_integer(unsigned(raddress)));

rdata_o <= rdata;
raddress <= counter2;

-- Write side --
waddress2 <= counter2;
write2 <= write_i;
wdata2 <= wdata_i;

-- Read side --
waddress1 <= counter1;
write1 <=  empty_line_i;
wdata1 <= '0';




end Behavioral;
