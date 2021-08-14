----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.08.2021 19:30:53
-- Design Name: 
-- Module Name: IP_with_router_tb - Behavioral
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
use std.textio.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IP_with_router_tb is
--  Port ( );
end IP_with_router_tb;

architecture Behavioral of IP_with_router_tb is

-- Constants
constant dram_depth : natural := 14912;
constant r_dim : natural := 8*8*64;
constant r_start : natural := (10*10*16 + 3*3*64*16);

signal clk_s, rst_s : std_logic;
signal config1_s, config2_s, config3_s, config4_s, config5_s, config6_s : std_logic_vector(31 downto 0);
signal axi_write_init_s, axi_write_next_s, axi_write_done_s : std_logic;
signal axi_write_address_s, axi_read_addr_s : std_logic_vector(31 downto 0);
signal axi_write_data_s, axi_read_data_s : std_logic_vector(63 downto 0);
signal axi_read_init_s, axi_read_last_s, axi_read_valid_s, axi_read_ready_s : std_logic;

-- AXI READ FSM
type read_state is (wait_init, delay, data);
signal read_current_state, read_next_state : read_state;

-- AXI READ COUNTERS
signal read_counter_32 : std_logic_vector(4 downto 0);
signal read_counter_64 : std_logic_vector(5 downto 0);
signal read_en_32, read_en_64 : std_logic;

-- AXI WRITE FSM
type write_state is (wait_init, delay, data, done);
signal write_current_state, write_next_state : write_state;

-- AXI WRITE COUNTERS
signal write_counter_32 : std_logic_vector(4 downto 0);
signal write_counter_64 : std_logic_vector(5 downto 0);
signal write_en_32, write_en_64 : std_logic;

-- REGISTERS
signal raddr_next, raddr_reg : std_logic_vector(31 downto 0);
signal waddr_next, waddr_reg : std_logic_vector(31 downto 0);

-- DDR
type ddr_type is array(0 to dram_depth - 1) of std_logic_vector(63 downto 0);


-- Function

---------------------------------------------------------------------------------
impure function init_dram return ddr_type is

  file text_file : text open read_mode is "C:\Users\alexs\OneDrive\Desktop\SR - project\python kodovi\dram_data.txt";
  variable text_line : line;
  variable dram_content : ddr_type;
  variable c : character;
  variable bit_val : std_logic;
  
begin

  for i in 0 to dram_depth - 1 loop
    readline(text_file, text_line);
	
	for j in 63 downto 0 loop
		
		read(text_line, c);
		
		if(c = '1') then
			bit_val := '1';
		else
			bit_val := '0';
		end if;
		
		dram_content(i)(j) := bit_val;
		
	end loop;
  end loop;
  
  return dram_content;
  
end function;

---------------------------------------------------------------------------------

procedure write_result(dram : in ddr_type; result_dim : in natural; result_start : in natural) is

	file text_file : text open write_mode is "C:\Users\alexs\OneDrive\Desktop\SR - project\python kodovi\result_rtl.txt";
	variable text_line : line;
	variable c : character;

begin

	for i in 0 to result_dim - 1 loop
		for j in 63 downto 0 loop
			
			if(dram(result_start + i)(j) = '1') then
				c := '1';
			else
				c := '0';
			end if;
			
			write(text_line, c);
			
		end loop;
		
		writeline(text_file, text_line);
		
	end loop;

end procedure; 

---------------------------------------------------------------------------------

function gen_ddr return ddr_type is
    variable data : std_logic_vector(15 downto 0) := (others => '0');
    variable data1 : std_logic_vector(63 downto 0);
    variable index : integer := 0;
    variable ddr : ddr_type := (others => (others => '0'));
    -------------------------------------------------------------
    variable weight : std_logic_vector(15 downto 0) := (others => '0');
    variable w_index : integer := 0;
    
begin

    for y in 0 to 9 loop
    
        for x in 0 to 9 loop
    
            for z in 0 to 15 loop
    
                for offs in 0 to 3 loop
    
                    data1((offs + 1) * 16 - 1 downto offs * 16) := data;
                    data := std_logic_vector(unsigned(data) + to_unsigned(1, 16));
    
                end loop;
    
                ddr(index) := data1;
                index := index + 1;
    
            end loop;
    
        end loop;
    
    end loop;
    
    -------------------------------------------------------------------------------

    for kn in 0 to 15 loop
    
        for offs in 0 to 3 loop
    
            w_index := 0;
    
            for h in 0 to 2 loop
    
                for w in 0 to 2 loop

                    for d in 0 to 63 loop
                    
                        ddr(kn * 9 * 64 + index + w_index)((offs + 1) * 16 - 1 downto offs * 16) := weight; -- prva tezina ce ostati nula
                        weight := std_logic_vector(to_unsigned(1, 16)); -- zasad nek su jedinice za tezine, inace smo parne brojeve: std_logic_vector(unsigned(weight) + to_unsigned(2, 16));
                        w_index := w_index + 1;
                        
                    end loop;

                end loop;

            end loop;
    
        end loop;
    
    end loop;

    return ddr;

end;

signal dram : ddr_type := init_dram; 

-- Format function
type format_type is array(0 to 3) of std_logic_vector(15 downto 0);
signal my_axi_read_data, my_axi_write_data : format_type;

function format(data: std_logic_vector) return format_type is

    variable var : format_type;

begin

    for i in 0 to 3 loop
    
        var(i) := data((i + 1) * 16 - 1 downto i * 16);
    
    end loop;

    return var;

end;




begin

-- Assigments
my_axi_read_data <= format(axi_read_data_s);
my_axi_write_data <= format(axi_write_data_s);


IP: entity work.IP_with_router_top(Behavioral)
    generic map(
        -------------------------- WMEM module -------------------------- 
        DATA_WIDTH       => 64,
        READ_MEM_ADDR    => 32,
        BRAM_ADDR_OFFSET => 512,
        BRAM_count       => 16,  
        wmem_size        => 9*64,
        
        -------------------------- PB module -------------------------- 
        WIDTH           => 10,
        ADDR_WIDTH      => 10,
        WIDTH_Data      => 16,
        SIGNED_UNSIGNED => "signed",
        MAC_width       => 32,
        bias_base_addr_width => 12, 
        bias_size       => 64*38,
        
        -------------------------- Cache module --------------------------
        col_width        => 9,
        i_width          => 10,
        cache_addr_width => 8,
        cache_line_count => 15,
        kernel_size      => 9,
        RF_addr_width    => 4,
        size             => 240
    )
    Port map(
        ------------------- Clock and Reset interface -------------------
        clk_i => clk_s,
        rst_i => rst_s,   
    
		------------------- Configuration interface -------------------
		config1 => config1_s,
		config2 => config2_s,
		config3 => config3_s,
		config4 => config4_s,
		config5 => config5_s,
		config6 => config6_s,
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o  => axi_write_address_s,
		axi_write_init_o	 => axi_write_init_s,
		axi_write_data_o	 =>	axi_write_data_s,							
		axi_write_next_i     => axi_write_next_s,
		axi_write_done_i     => axi_write_done_s,
            
        ------------------- AXI Read interface -------------------
        axi_read_init_o        => axi_read_init_s,
        axi_read_data_i        => axi_read_data_s,
        axi_read_addr_o        => axi_read_addr_s,
        axi_read_last_i        => axi_read_last_s,
        axi_read_valid_i       => axi_read_valid_s,
        axi_read_ready_o       => axi_read_ready_s
        
    );
    
clk_gen: process
begin
     clk_s <= '0', '1' after 100 ns;
     wait for 200 ns;
end process;

--------------------- Registers --------------------- 
process(clk_s) is
begin
    if(rising_edge(clk_s)) then
    
        if(rst_s = '1') then
            raddr_reg <= (others => '0');
            waddr_reg <= (others => '0');
        else
            raddr_reg <= raddr_next;
            waddr_reg <= waddr_next;
        end if;
    
    end if;

end process; 


----------------------- AXI READ --------------------------
r_counter_32: process(clk_s) is 
begin
    
    if(rising_edge(clk_s)) then
        
        if(rst_s = '1') then
            read_counter_32 <= (others => '0');
        else
            read_counter_32 <= read_counter_32;
            
            if(read_en_32 = '1') then
                read_counter_32 <= std_logic_vector(unsigned(read_counter_32) + to_unsigned(1, 5));
            end if;
        
        end if;
        
    end if;

end process;

r_counter_64: process(clk_s) is 
begin
    
    if(rising_edge(clk_s)) then
        
        if(rst_s = '1') then
            read_counter_64 <= (others => '0');
        else
            read_counter_64 <= read_counter_64;
            
            if(read_en_64 = '1') then
                read_counter_64 <= std_logic_vector(unsigned(read_counter_64) + to_unsigned(1, 6));
            end if;
        
        end if;
        
    end if;

end process;


axi_read_mem: process(clk_s)
begin
    if(rising_edge(clk_s)) then
        if(rst_s = '1') then
            read_current_state <= wait_init;
        else
            read_current_state <= read_next_state;
        end if;
    end if;
    
end process;

axi_read_comb: process(read_current_state, axi_read_init_s, axi_read_addr_s, axi_read_ready_s, raddr_reg, read_counter_32, read_counter_64)
begin
    
    axi_read_data_s <= (others => '0');
    axi_read_last_s <= '0';
    axi_read_valid_s <= '0';
    
    read_en_32 <= '0';
    read_en_64 <= '0';
    
    raddr_next <= raddr_reg; 
    
    case read_current_state is
    
        when wait_init =>
                
            if(axi_read_init_s = '1') then
                read_next_state <= delay;
                raddr_next <= axi_read_addr_s;
            else
                read_next_state <= wait_init;
            end if;
        
        when delay =>
        
            read_en_32 <= '1';
            
            if(read_counter_32 = "11111") then
                read_next_state <= data;
            else
                read_next_state <= delay;
            end if;
        
        when data => 
            
            axi_read_valid_s <= '1';
            axi_read_data_s <= dram(to_integer(unsigned(raddr_reg)) / 8 + to_integer(unsigned(read_counter_64)));
          
            read_next_state <= data; 
          
            if(read_counter_64 = "111111") then
                axi_read_last_s <= '1';
            end if;
            
            if(axi_read_ready_s = '1') then
                read_en_64 <= '1';
                   
                if(read_counter_64 = "111111") then
                    read_next_state <= wait_init;
                end if;
                
            end if;
          
          
    end case;
    
end process;


----------------------- AXI WRITE --------------------------
w_counter_32: process(clk_s) is 
begin
    
    if(rising_edge(clk_s)) then
        
        if(rst_s = '1') then
            write_counter_32 <= (others => '0');
        else
            write_counter_32 <= write_counter_32;
            
            if(write_en_32 = '1') then
                write_counter_32 <= std_logic_vector(unsigned(write_counter_32) + to_unsigned(1, 5));
            end if;
        
        end if;
        
    end if;

end process;

w_counter_64: process(clk_s) is 
begin
    
    if(rising_edge(clk_s)) then
        
        if(rst_s = '1') then
            write_counter_64 <= (others => '0');
        else
            write_counter_64 <= write_counter_64;
            
            if(write_en_64 = '1') then
                write_counter_64 <= std_logic_vector(unsigned(write_counter_64) + to_unsigned(1, 6));
            end if;
        
        end if;
        
    end if;

end process;


axi_write_mem: process(clk_s)
begin
    if(rising_edge(clk_s)) then
        if(rst_s = '1') then
            write_current_state <= wait_init;
        else
            write_current_state <= write_next_state;
        end if;
    end if;
    
end process;

axi_write_comb: process(write_current_state, waddr_reg, write_counter_32, write_counter_64, axi_write_address_s, axi_write_init_s, axi_write_data_s)
begin
    
    axi_write_next_s <= '0';
    axi_write_done_s <= '0';
    
    write_en_32 <= '0';
    write_en_64 <= '0';
    
    waddr_next <= waddr_reg; 
    
    case write_current_state is
    
        when wait_init =>
                
            if(axi_write_init_s = '1') then
                write_next_state <= delay;
                waddr_next <= axi_write_address_s;
            else
                write_next_state <= wait_init;
            end if;
        
        when delay =>
        
            write_en_32 <= '1';
            
            if(write_counter_32 = "11111") then
                write_next_state <= data;
            else
                write_next_state <= delay;
            end if;
        
        when data => 
            
            write_en_64 <= '1';
            axi_write_next_s <= '1';
            dram(to_integer(unsigned(waddr_reg)) / 8 + to_integer(unsigned(write_counter_64))) <= axi_write_data_s;
          
            write_next_state <= data; 
            
            if(write_counter_64 = "111111") then
                write_next_state <= done; 
            end if;
            
        when done =>
        
            axi_write_done_s <= '1';
            write_next_state <= wait_init;
          
          
    end case;
    
end process;

----------------------- Configs ----------------------- 

config: process 
begin
    
    rst_s <= '1';
    config1_s <= (others => '0');
    config2_s <= (others => '0');
    config3_s <= (others => '0');
    config4_s <= (others => '0');
    config5_s <= (others => '0');
    wait for 350ns;
    rst_s <= '0';
    
    config1_s <= std_logic_vector(to_unsigned(1600 * 8, 32));
    config2_s <= std_logic_vector(to_unsigned(10816 * 8, 32));
    
    config3_s <= std_logic_vector(to_unsigned(0, 32));
    config3_s(1) <= '1';
    config3_s(3) <= '1';
    config3_s(13 downto 5) <= std_logic_vector(to_unsigned(10, 9));
    config3_s(31 downto 14) <= std_logic_vector(to_unsigned(100, 18));
    
    config4_s <= std_logic_vector(to_unsigned(0, 32));
    config4_s(29 downto 12) <= std_logic_vector(to_unsigned(64, 18));
    
    config5_s <= std_logic_vector(to_unsigned(8, 32));
    
    wait until rising_edge(config6_s(0));
    wait for 3000ns; -- simuliramo kasnjenje hardversko-softverskog interfejsa
    
    config3_s(0) <= '1';
    config3_s(3) <= '0';
    config3_s(4) <= '1';
    

    wait;
end process;


write_file: process(config6_s) is
begin
    
    if(rising_edge(config6_s(1))) then
        write_result(dram, r_dim, r_start);
    end if;
    

end process;



end Behavioral;
