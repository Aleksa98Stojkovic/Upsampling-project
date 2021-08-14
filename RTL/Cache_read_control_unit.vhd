----------------------------------------------------------------------------------
-- Company: FTN
-- Engineer: 
-- 
-- Create Date: 07/10/2021 10:25:14 PM
-- Design Name: 
-- Module Name: Cache_read_control_unit - Behavioral
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

entity Cache_read_control_unit is
    generic(
            col_width : natural := 9;
            i_width : natural := 10;
            addr_width : natural := 8;
            cache_line_count : natural := 15;
            kernel_size : natural := 9;
            RF_addr_width : natural := 4;
            cache_width : natural := 64;
            data_width : natural := 12
            );
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         
         --------------- Input interface ---------------
         req_i : in std_logic;
         end_i : in std_logic;
         start_i : in std_logic;
         --output_width_i : in std_logic_vector(col_width - 1 downto 0);
         
         --------------- Config registers --------------- 
         config5 : in std_logic_vector(31 downto 0);
         
         --------------- Write interface of the Register File ---------------
         write_RF_i : in std_logic;
         waddress_RF_i : in std_logic_vector(RF_addr_width - 1 downto 0);
         wdata_RF_i : in std_logic_vector(1 downto 0);
         
         --------------- Input from Cache Memory ---------------
         cache_data_i : in std_logic_vector(cache_width - 1 downto 0);
         
         --------------- Output interface ---------------
         empty_line_o : out std_logic;
         -- load_num_o : out std_logic_vector(1 downto 0);
         d_valid_o : out std_logic;
         -- cache_line_o : out std_logic_vector(addr_width - 1 downto 0);
         
         --------------- Address for Cache Memory ---------------
         raddress_cache_o : out std_logic_vector(addr_width - 1 downto 0);
         
         --------------- Data output ---------------
         cache_data_o : out std_logic_vector(data_width - 1 downto 0)
         );
end Cache_read_control_unit;

architecture Behavioral of Cache_read_control_unit is

-- Constants --
constant i_comp1 : natural := 9;
constant i_comp2 : natural := 3;  
constant window_size : natural := 64 * 9;
constant i_bits : natural := 6;
constant input_depth : natural := 64;
constant compressed_width : natural := 16;

-- Function --
function assign_value(data : in std_logic_vector(cache_line_count * addr_width - 1 downto 0)) 
                      return std_logic_vector is

variable temp : std_logic_vector(data'range);
begin

    for i in cache_line_count downto 1 loop
        temp(i * addr_width - 1 downto (i - 1) * addr_width) := std_logic_vector(to_unsigned(compressed_width * (cache_line_count - i), addr_width));
    end loop;
    
    return temp;
    
end; 

-- Custom type --
type state is (idle, request, init, read);

-- FSM signals --
signal current_state, next_state : state;

-- Signals --
signal shift_up, shift_down, write_en_up, write_en_down, RF_write : std_logic;
signal data : std_logic_vector(cache_line_count * addr_width - 1 downto 0);
signal cache_line : std_logic_vector(addr_width - 1 downto 0);
signal amount_hash, RF_wdata : std_logic_vector(1 downto 0);
signal RF_read_addr, RF_write_addr : std_logic_vector(RF_addr_width - 1 downto 0);

-- config signal
signal output_width_i : std_logic_vector(col_width - 1 downto 0);

-- Registers --
signal col_num_reg, col_num_next : std_logic_vector(col_width - 1 downto 0);
signal i_reg, i_next : std_logic_vector(i_width - 1 downto 0);
signal d_valid_reg, d_valid_next : std_logic;
-- signal load_num : std_logic_vector(1 downto 0);

-- Comparators --
signal comp1, comp2, comp3, comp4, comp5, comp6 : std_logic;
signal temp : std_logic_vector(1 downto 0);

begin

output_width_i <= config5(8 downto 0);


-- Additional components --
Dual_reg : entity work.Cache_line_register(Behavioral)
generic map(           
            DATA_WIDTH => addr_width,
            N_in_up => cache_line_count,
            N_in_down => kernel_size)
port map(
        clk_i => clk_i,
        rst_i => rst_i,
        shift_up_i => shift_up,
        shift_down_i => shift_down,
        write_en_up_i => write_en_up,
        write_en_down_i => write_en_down,
        data_i => data,
        data_s_o => cache_line);
        
RF : entity work.Register_bank_sync(Behavioral)
generic map(            
            width => 2,
            reg_num => cache_line_count,
            addr_width => RF_addr_width)
port map(        
         clk_i => clk_i,
         rst_i => rst_i,
         
         rdata => amount_hash,
         raddress => RF_read_addr,
         
         wdata1 => wdata_RF_i,
         waddress1 => waddress_RF_i,
         write1 => write_RF_i,
         
         wdata2 => RF_wdata,
         waddress2 => RF_write_addr,
         write2 => RF_write);

-- Defining parallel input into dual register --
data <= assign_value(data);
d_valid_o <= d_valid_reg;

-- Registers --
reg : process(clk_i) is
begin

    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
        
            col_num_reg <= (others => '0');
            i_reg <= (others => '0');
            d_valid_reg <= '0';
            -- load_num_reg <= (others => '0');
            
        else
        
            col_num_reg <= col_num_next;
            i_reg <= i_next;
            d_valid_reg <= d_valid_next;
            -- load_num_reg <= load_num_next;
            
        end if;
    end if;
    
end process;

-- Comparators --
comp1 <= '1' when col_num_reg = output_width_i else
         '0';
comp2 <= '1' when i_reg < std_logic_vector(to_unsigned(i_comp1, i_width)) else
         '0';
comp3 <= '1' when i_reg < std_logic_vector(to_unsigned(i_comp2, i_width)) else
         '0';
comp4 <= '1' when i_next(i_bits - 1 downto 0) = std_logic_vector(to_unsigned(input_depth - 1, i_bits)) else
         '0';
comp5 <= '1' when i_next = std_logic_vector(to_unsigned(window_size, i_width)) else
         '0';
comp6 <= '1' when temp = std_logic_vector(to_unsigned(0, 2)) else
         '0';


-- Address for Cache memory --
raddress_cache_o <= std_logic_vector(unsigned(cache_line) + unsigned(i_next(5 downto 2)));

-- Cominational cicruit for amount_hash --
-- Ciklus pre poslednjeg podatka sa date linije kesa se smanjuje broj zivota --
-- Tada se i generise signal za write, pa na to treba paziti -- 


--Comb1 : process(current_state, comp4) is
--begin
    
--    RF_wdata <= amount_hash;
--    if(current_state = read) then
--        if(comp4 = '1') then
--            RF_wdata <= std_logic_vector(unsigned(amount_hash) - to_unsigned(1, 2));
--        end if;
--    end if;

--end process;

Comb1:
RF_wdata <= std_logic_vector(unsigned(amount_hash) - to_unsigned(1, 2)) when comp4 = '1' and current_state = read else
            amount_hash;

RF_read_addr <= cache_line(3 + RF_addr_width downto 4);
RF_write_addr <= cache_line(3 + RF_addr_width downto 4);
temp <= RF_wdata;

-- Combinational circuit for assigning new values to registers --
Comb2 : process(current_state, comp1, i_reg, col_num_reg, comp5) is
begin

    -- col_num_next <= col_num_reg;
    -- i_next <= i_reg;
    -- load_num <= (others => '0');
    
    case current_state is
    
        when idle =>
            
            col_num_next <= (others => '0');
            i_next <= i_reg;
            -- load_num_next <= load_num_reg;
       
        when request =>
            
            col_num_next <= col_num_reg;
            i_next <= i_reg;
            -- load_num_next <= load_num_reg;
            
        when init =>
            
            col_num_next <= std_logic_vector(unsigned(col_num_reg) + to_unsigned(1, col_num_reg'length));
            i_next <= (others => '0');
            -- load_num_next <= load_num_reg;
        
        when read =>
            
            if(comp1 = '1' and comp5 = '1') then
                col_num_next <= (others => '0');
                
                -- load_num <= std_logic_vector(to_unsigned(3, load_num'length));
            else
                col_num_next <= col_num_reg;
                -- load_num <= std_logic_vector(to_unsigned(1, load_num'length));
            end if; 
            
            i_next <= std_logic_vector(unsigned(i_reg) + to_unsigned(1, i_reg'length));
            
    
    end case;

end process;

-- Output mux --
cache_data_o <= cache_data_i(data_width - 1 downto 0) when i_reg(1 downto 0) = "00" else
                cache_data_i(2 * data_width - 1 downto data_width) when i_reg(1 downto 0) = "01" else
                cache_data_i(3 * data_width - 1 downto 2 * data_width) when i_reg(1 downto 0) = "10" else
                cache_data_i(4 * data_width - 1 downto 3 * data_width);
                
-- Connecting internal signals to output signals --
-- cache_line_o <= cache_line;
-- load_num_o <= load_num;

-- FSM --
FSM_memory : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            current_state <= idle;
        else
            current_state <= next_state;
        end if;
    end if;
    
end process;

FSM_comb : process(current_state, req_i, end_i, start_i, comp1, comp2, comp3, comp4, comp5, comp6) is
begin
    
    d_valid_next <= '0';
    empty_line_o <= '0';
    shift_up <= '0';
    shift_down <= '0';
    write_en_up <= '0';
    write_en_down <= '0';
    RF_write <= '0';
     
    case current_state is
    
        when idle =>
            
            write_en_up <= '1';
            
            if(start_i = '1') then
                next_state <= request; 
            else
                next_state <= idle;
            end if;
            
        when request =>
        
            if(req_i = '1') then
                write_en_down <= '1';
                d_valid_next <= '1';
                next_state <= init;
            else    
                if(end_i = '1') then
                    next_state <= idle;
                else
                    next_state <= request;
                end if; 
            end if;
        
        when init =>
        
            -- d_valid_o <= '1';
            next_state <= read;
            
        when read =>
            
            RF_write <= '1';
            
            if(comp1 = '1') then
                if(comp2 = '1') then -- 9 --
                    shift_up <= '1';
                end if;
            else
                if(comp3 = '1') then -- 3 --
                    shift_up <= '1';
                end if;                
            end if;
            
            if(comp4 = '1') then
                shift_down <= '1';
                if(comp6 = '1') then
                    empty_line_o <= '1';
                end if; 
            end if;
            
            if(comp5 = '1') then
                next_state <= request;
            else
                next_state <= read;
            end if;
        
    end case;
    
end process;

end Behavioral;
