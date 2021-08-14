----------------------------------------------------------------------------------
-- Company: FTN
-- Engineer: Boris_Aleksa
-- 
-- Create Date: 07.07.2021 11:38:38
-- Design Name: FSM_PB
-- Module Name: FSM_PB - Behavioral
-- Project Name: Upsampling_RTL
-- Target Devices: zynq-z7010
-- Tool Versions: -
-- Description: FSM and Address Generator Unit for Processing Block
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

entity FSM_PB is
    generic(
        WIDTH1 : natural := 18;
        WIDTH2 : natural := 10;
        ADDR_WIDTH : natural := 10
    );
    port(
        --------------- Clocking and reset interface ---------------
        clk_i : in std_logic;
        rst_i : in std_logic;
        ------------------- Input data interface -------------------
        w_valid_i    : in std_logic;
        d_valid_i    : in std_logic;
        start_i      : in std_logic;
        
        ------------------- Config register -------------------
        config4 : in std_logic_vector(31 downto 0);
        
        ------------------- Output data interface -------------------
        ready_o       : out std_logic;  
        done_o        : out std_logic;
        en_o          : out std_logic; 
        zero_o        : out std_logic;
        req_o         : out std_logic;
        weight_addr_o : out std_logic_vector(ADDR_WIDTH - 1 downto 0)
     );
end FSM_PB;

architecture Behavioral of FSM_PB is

constant window_size : std_logic_vector(WIDTH2 - 1 downto 0) := std_logic_vector(to_unsigned(9 * 64, WIDTH2)); --9*64
constant window_size_dec : integer := 9 * 64 - 1; 
type state is (idle, init, processing, newPix, delay1, delay2);
signal next_state, current_state : state;
signal i_reg, i_next : std_logic_vector(WIDTH1 - 1 downto 0);
signal j_reg, j_next : std_logic_vector(WIDTH2 - 1 downto 0);
signal add1 : std_logic_vector(WIDTH1 - 1 downto 0);
signal add2 : std_logic_vector(WIDTH2 - 1 downto 0);
signal i_comp : std_logic;
signal j_comp : std_logic;
signal j_reg_comp : std_logic;

signal num_of_pix_i : std_logic_vector(WIDTH1 - 1 downto 0);

begin

num_of_pix_i <= config4(29 downto 12);

registers: process(clk_i) 
begin
    
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            i_reg <= (others => '0');
            j_reg <= (others => '0');
        else
            i_reg <= i_next;
            j_reg <= j_next;
        end if;
    end if;

end process;

add1 <= std_logic_vector(unsigned(signed(i_reg) + to_signed(-1, WIDTH1)));
add2 <= std_logic_vector(unsigned(j_reg) + to_unsigned(1, WIDTH2));

j_reg_comp <= '1' when j_reg = std_logic_vector(to_unsigned(window_size_dec, j_reg'length)) else 
              '0';

i_next <= i_reg when (current_state = init or current_state = processing or current_state = delay1 or current_state = delay2) else
          num_of_pix_i when current_state = idle else
          add1;
          
j_next <= j_reg when (current_state = idle or current_state = newPix or current_state = delay1 or current_state = delay2) else
          (others => '0') when current_state = init else
          add2;
          
i_comp <= '1' when (i_next /= std_logic_vector(to_unsigned(0, WIDTH1))) else
          '0';
          
j_comp <= '1' when (j_next = window_size) else
          '0';
          
weight_addr_o <= j_next(ADDR_WIDTH - 1 downto 0) when j_reg_comp = '0' and (current_state = init or current_state = processing) else
                 (others => '0');
          
fsm_memory: process(clk_i) 
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            current_state <= idle;
        else
            current_state <= next_state;
        end if;
    end if;
end process;

fsm_comb: process(current_state, w_valid_i, d_valid_i, start_i, i_comp, j_comp)
begin
    ready_o <= '0';
    --new_package_o <= '0';
    done_o <= '0';
    en_o <= '0';
    req_o <= '0';
    zero_o <= '0';
    
    case current_state is
        when idle => 
            ready_o <= '1';
            
            if(start_i = '1') then
                next_state <= init;
            else
                next_state <= idle;
            end if;
        when init =>
            req_o <= '1';
            zero_o <= '1';   -- dodato naknadno!
            
            if(w_valid_i = '0' or d_valid_i = '0') then
                next_state <= init;
            else
                next_state <= processing;
            end if;
        when processing =>
            en_o <= '1';
            if(j_comp = '1') then
                next_state <= newPix;
                --new_package_o <= '1';
            else
                next_state <= processing;
            end if;
        when newPix =>
            en_o <= '1';
            if(i_comp = '1') then
                next_state <= delay1;
            else
                next_state <= delay2;
            end if;
        when delay1 =>
            --en_o <= '1';
            done_o <= '1';
            next_state <= init;
        
        when delay2 =>
            --en_o <= '1';
            done_o <= '1';
            next_state <= idle;
        
    end case;
    
end process;

end Behavioral;
