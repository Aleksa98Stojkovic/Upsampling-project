----------------------------------------------------------------------------------
-- Company: FTN
-- Engineer: Aleska Stojkovic
-- 
-- Create Date: 07/10/2021 09:33:53 PM
-- Design Name: Register_bank_sync
-- Module Name: Register_bank_sync - Behavioral
-- Project Name: Upsampling_RTL
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


entity Register_bank_sync is
    generic(
            width      : natural := 2;
            reg_num    : natural := 15;
            addr_width : natural := 4
            );
    Port(
         --------------- Clocking and reset interface ---------------
        clk_i : in std_logic;
        rst_i : in std_logic;
        
        ------------------- Read interface -------------------
        rdata    : out std_logic_vector(width - 1 downto 0);
        raddress : in std_logic_vector(addr_width - 1 downto 0);
        
        ------------------- Write interface -------------------
        wdata1    : in std_logic_vector(width - 1 downto 0);
        waddress1 : in std_logic_vector(addr_width - 1 downto 0);
        write1    : in std_logic;
        
        wdata2    : in std_logic_vector(width - 1 downto 0);
        waddress2 : in std_logic_vector(addr_width - 1 downto 0);
        write2    : in std_logic
        );
end Register_bank_sync;

architecture Behavioral of Register_bank_sync is

type reg_bank is array(0 to reg_num - 1) of std_logic_vector(width - 1 downto 0);
signal bank : reg_bank;

begin

Write_reg_bank : process(clk_i) is
begin

    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            bank <= (others => (others => '0'));
        else
            if(write1 = '1') then
                bank(to_integer(unsigned(waddress1))) <= wdata1;
            end if;
            
            if(write2 = '1') then
                bank(to_integer(unsigned(waddress2))) <= wdata2;
            end if;
            
        end if;
        
    end if;

end process;

--read_reg_bank : process(clk_i) is
--begin

--    if(rising_edge(clk_i)) then
--        rdata <= bank(to_integer(unsigned(raddress)));
--    end if;

--end process;

-- Ipak ce biti asinhrono citanje
rdata <= bank(to_integer(unsigned(raddress)));

end Behavioral;
