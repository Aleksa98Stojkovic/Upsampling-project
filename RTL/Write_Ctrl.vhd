----------------------------------------------------------------------------------
-- Company: FTN
-- Engineer: 
-- 
-- Create Date: 07/24/2021 07:06:37 PM
-- Design Name: 
-- Module Name: Write_Ctrl - Behavioral
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

entity Write_Ctrl is
    generic(
            data_width : natural := 64;
            RF_addr_width : natural := 4;
            cache_addr_width : natural := 8;
            dim_width : natural := 9;
            total_dim_width : natural := 18;
            
            -- ADDER
            g_WIDTH : natural := 32
            );
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         
         --------------- AXI master read interface ---------------
        axi_read_address_o : out std_logic_vector(31 downto 0);  
		axi_read_init_o	: out std_logic;                         
		axi_read_data_i	: in std_logic_vector(data_width - 1 downto 0);    
		axi_read_next_i : in std_logic; -- Umesto next dodati valid
		axi_read_last_i : in std_logic;                        
		axi_read_rdy_o: out std_logic;
        
        --------------- Register File interface ---------------
        en_o : out std_logic;
        write_o : out std_logic;
        wdata_o : out std_logic;
        rdata_i : in std_logic;
        wcounter_i : in std_logic_vector(RF_addr_width - 1 downto 0);
        
        --------------- Cache Memory interface ---------------		
		cache_addr_o : out std_logic_vector(cache_addr_width - 1 downto 0);
		cache_data_o : out std_logic_vector(data_width - 1 downto 0);
		cache_write_o : out std_logic;
		
		--------------- Configuration Registers interface ---------------
        config3 : in std_logic_vector(31 downto 0);
--        start_i : in std_logic;
--        height_i : in std_logic_vector(dim_width - 1 downto 0);
--        total_i : in std_logic_vector(total_dim_width - 1 downto 0); -- visina x sirina = ukupno piksela
        
        --------------- Write interface of the Register File ---------------
        write_RF_o : out std_logic;
        waddress_RF_o : out std_logic_vector(RF_addr_width - 1 downto 0);
        wdata_RF_o : out std_logic_vector(1 downto 0);
        
        --------------- Output signal ---------------
        start_processing_o : out std_logic 
         
         );
end Write_Ctrl;

architecture Behavioral of Write_Ctrl is

-- config signals
signal start_i : std_logic;
signal height_i : std_logic_vector(dim_width - 1 downto 0);
signal total_i : std_logic_vector(total_dim_width - 1 downto 0); -- visina x sirina = ukupno piksela

-- Constants --
constant depth : std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(64, 7));
constant zeros_1 : std_logic_vector(cache_addr_o'length - wcounter_i'length - 1 downto 0) := (others => '0');
constant zeros_2 : std_logic_vector(cache_addr_o'length - 5 downto 0) := (others => '0');
constant zeros_3 : std_logic_vector(axi_read_address_o'length - height_i'length - 1 downto 0) := (others => '0');
constant zeros_4 : std_logic_vector(axi_read_address_o'length - total_i'length - 1 downto 0) := (others => '0');
-- constant help : std_logic_vector(31 downto 0) := std_logic_vector(shift_left(unsigned(zeros_3 & height_i), 4)); 

-- Registers --
signal col_reg, col_next, row_reg, row_next : std_logic_vector(31 downto 0);
signal DDR_addr_reg, DDR_addr_next : std_logic_vector(31 downto 0);
-- signal cache_addr_reg, cache_addr_next : std_logic_vector(cache_addr_width - 1 downto 0);

-- Counters --
signal counter_16 : std_logic_vector(3 downto 0);
signal counter_4 : std_logic_vector(1 downto 0);
signal en_16, en_4 : std_logic;

-- FSM --
type state is (idle, trans_init, cache_write, prep_trans, next_read);
signal current_state, next_state : state;

-- Signals --
signal add : std_logic_vector(31 downto 0);
signal start_ff, start_ff2, start_pulse : std_logic;
signal flag_reg, flag_next : std_logic;

-- Comparators --
signal comp1, comp2, comp3, comp4 : std_logic;

-- Test --
signal valid : std_logic;

begin


-- Assigments --
axi_read_address_o <= DDR_addr_reg;
cache_addr_o <= std_logic_vector((shift_left(unsigned(zeros_1 & wcounter_i), 4)) + unsigned(zeros_2 & counter_16));
cache_data_o <= axi_read_data_i;
add <= std_logic_vector(unsigned(col_reg) + shift_left(unsigned(zeros_3 & height_i), 4));
wdata_o <= '1';
waddress_RF_o <= wcounter_i;
valid <= axi_read_next_i;


start_i <= config3(4);
height_i <= config3(13 downto 5);
total_i <= config3(31 downto 14);


start_pulse <= start_ff and (not start_ff2);

--creating start pulse
strat_gen: process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        start_ff <= start_i;
        start_ff2 <= start_ff;
    end if;

end process;


Registers : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
        
            col_reg <= (others => '0');
            row_reg <= (others => '0');
            DDR_addr_reg <= (others => '0');
            flag_reg <= '1';
            
        else
        
            col_reg <= col_next;
            row_reg <= row_next;
            DDR_addr_reg <= DDR_addr_next;
            flag_reg <= flag_next;

        end if;
    end if;
end process;

-- Comparators --

comp1 <= '1' when col_reg <= (col_reg'range => '0') else
         '0';

comp2 <= '1' when col_next = std_logic_vector(shift_left(unsigned(zeros_4 & total_i), 4) - shift_left(unsigned(zeros_3 & height_i), 4)) else
         '0';
         
comp3 <= '1' when col_reg = std_logic_vector(shift_left(unsigned(zeros_3 & height_i), 4)) else
         '0';

comp4 <= '1' when col_next = std_logic_vector(shift_left(unsigned(zeros_4 & total_i), 4) - shift_left(unsigned(zeros_3 & height_i), 5)) else   -- umesto 4 promenjeno na 5
         '0';

-----------------

Amount_hash : process(comp1, comp2, comp3, comp4) is
begin
    
    
    if(comp1 = '1' or comp2 = '1') then
    
        wdata_RF_o <= std_logic_vector(to_unsigned(1, wdata_RF_o'length));
        
    elsif(comp3 = '1' or comp4 = '1') then
    
        wdata_RF_o <= std_logic_vector(to_unsigned(2, wdata_RF_o'length));
    
    else
        
        wdata_RF_o <= std_logic_vector(to_unsigned(3, wdata_RF_o'length));
    
    end if;    

end process;

Count_16 : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            counter_16 <= (others => '0');
        else
            counter_16 <= counter_16;
            if(en_16 = '1') then
                counter_16 <= std_logic_vector(unsigned(counter_16) + to_unsigned(1, counter_16'length));
            end if;
        end if;
    end if;
end process;    

Count_4 : process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            counter_4 <= (others => '0');
        else
            counter_4 <= counter_4;
            if(en_4 = '1') then
                counter_4 <= std_logic_vector(unsigned(counter_4) + to_unsigned(1, counter_4'length));
            end if;
        end if;
    end if;
end process;    

------------------------------- FSM -------------------------------

FSM_mem : process(clk_i) is
begin

    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            current_state <= idle;
        else
            current_state <= next_state;
        end if;
    end if;

end process;



FSM_comb : process(current_state, start_pulse, col_reg, row_reg, DDR_addr_reg, valid, flag_reg,
                   rdata_i, axi_read_last_i, col_next, add, wcounter_i, counter_4, counter_16, total_i, height_i) is
begin

    -- AXI --
    axi_read_init_o <= '0';
    axi_read_rdy_o <= '0';
    
    -- RF --
    en_o <= '0';
    write_o <= '0';
    
    -- Cache --
	cache_write_o <= '0';
	
	-- Output --
	start_processing_o <= '0';
	
	-- Counter enable signals --
	en_16 <= '0';
	en_4 <= '0';
	
    --------------- Write interface of the Register File ---------------
    write_RF_o <= '0';
    
    flag_next <= flag_reg;
    
    
    case current_state is
        -- Starting state
        when idle =>
            
            col_next <= (others => '0');
            row_next <= (others => '0');
            DDR_addr_next <= (others => '0');
            -- cache_addr_next <= cache_addr_reg;
            
            if(start_pulse = '1') then
                next_state <= trans_init;
            else
                next_state <= idle;
            end if;
            
--        ----------------------------------
--        -- Initializing columns counter    
--        when col_init =>
            
--            col_next <= (others => '0');
--            row_next <= row_reg;
--            DDR_addr_next <= (others => '0');
--            cache_addr_next <= cache_addr_reg;      
            
        ----------------------------------    
        -- Read transaction is issued
        -- In this state DDR address is stable and valid
        when trans_init => 
            
            col_next <= col_reg;
            row_next <= row_reg;
            DDR_addr_next <= DDR_addr_reg;
            -- First address of a cache line
            -- cache_addr_next <= std_logic_vector(shift_left(unsigned(zeros_1 & wcounter_i), 4)); -- wcounter_i = cache line
            
            axi_read_init_o <= '1';
            
            next_state <= cache_write;
            
            
        ----------------------------------
        -- Ctrl is writing to specific parts of cache memory according to info that has gathered for RF and AXI
        when cache_write =>
            
            col_next <= col_reg;
            row_next <= row_reg;
            DDR_addr_next <= DDR_addr_reg; 
            -- cache_addr_next <= cache_addr_reg;
            
            next_state <= cache_write;
            
           ------------------------- NEW DESIGN -------------------------- 
            
            if(counter_4 = "11") then
            
                axi_read_rdy_o <= '1';
                
                if(axi_read_last_i = '1') then
                    
                    -- Increment counter_4 because you want it to be 00 for next read transaction
                    en_4 <= '1';
                    
                    -- This means that we have gone trough all cache lines
                    if(wcounter_i = std_logic_vector(to_unsigned(0, wcounter_i'length)) and flag_reg = '1') then
                        start_processing_o <= '1';
                        flag_next <= '0';
                    end if;
                    
                    -- Decide what is going to be our next state
                    next_state <= prep_trans;
                end if;
            
            else
            
                if(rdata_i = '0') then
                    axi_read_rdy_o <= '1';
                       
                    if(valid = '1') then
                        
                        en_16 <= '1';
                        
                        cache_write_o <= '1';
                        
                        if(counter_16 = "1111") then
                            
                            -- Determine the right amount of lives
                            write_RF_o <= '1';
                            -- Incrementing couter_4
                            en_4 <= '1';
                            -- We should inform RF, by writing '1', that we have stored new data on that particular cache line
                            en_o <= '1';
                            write_o <= '1';
                            
                        end if;
                        
                    end if;
                    
                end if;
            
            end if;
            
            --------------------------------------------------
            
            
--            if(valid = '1') then
                    
--                if(counter_4 = "11") then
                
--                    axi_read_rdy_o <= '1';
                  
--                    if(axi_read_last_i = '1') then
                        
--                        -- Increment counter_4 because you want it to be 00 for next read transaction
--                        en_4 <= '1';
                        
--                        -- This means that we have gone trough all cache lines
--                        if(wcounter_i = std_logic_vector(to_unsigned(0, wcounter_i'length)) and flag_reg = '1') then
--                            start_processing_o <= '1';
--                            flag_next <= '0';
--                        end if;
                        
--                        -- Decide what is going to be our next state
--                        next_state <= prep_trans;
--                    end if;
                    
--                else
                    
--                    if(rdata_i = '0') then
                        
--                        en_16 <= '1';
--                        axi_read_rdy_o <= '1';
                        
--                        -- Signaling to cache that recived data can be written into the memory  
--                        -- cache_addr_next <= std_logic_vector((shift_left(unsigned(zeros_1 & wcounter_i), 4)) + unsigned(zeros_2 & counter_16));
--                        cache_write_o <= '1';
                        
--                        if(counter_16 = "1111") then
                            
--                            -- Determine the right amount of lives
--                            write_RF_o <= '1';
                            
                            
--                            en_4 <= '1';
                            
--                            -- We should inform RF, by writing '1', that we have stored new data on that particular cache line
--                            en_o <= '1';
--                            write_o <= '1'; -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! --
                            
--                        end if;
                        
--                    end if;
                    
--                end if;
                
--            end if;
                       
        ----------------------------------
        -- Incrementing olumns counter    
        when prep_trans =>
           
            col_next <= add;
            row_next <= row_reg;
            DDR_addr_next <= add; 
            -- cache_addr_next <= cache_addr_reg;
            
            next_state <= next_read;
            
            if(add = std_logic_vector(shift_left(unsigned(zeros_4 & total_i), 4))) then
            
                col_next <= (others => '0');
                DDR_addr_next <= (others => '0');
                
                row_next <= std_logic_vector(unsigned(row_reg) + to_unsigned(16, row_reg'length));
            end if;
            
        ----------------------------------    
        -- Checking where should we go next and preparing next DDR address 
        when next_read =>
            
            
            col_next <= col_reg;
            DDR_addr_next <= std_logic_vector(shift_left(unsigned(DDR_addr_reg) + unsigned(row_reg), 3));
            row_next <= row_reg; 
            --cache_addr_next <= cache_addr_reg;
            
            if(row_reg = std_logic_vector(unsigned(zeros_3 & height_i) - to_unsigned(2, 32))) then
                next_state <= idle;
            else
                next_state <= trans_init;
            end if;                
            
        
    end case;

end process;

end Behavioral;
