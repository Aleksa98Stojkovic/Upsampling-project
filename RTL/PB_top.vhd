----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.07.2021 13:29:14
-- Design Name: 
-- Module Name: PB_top - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PB_top is
    generic(
        --fsm
        WIDTH1 : natural := 18;
        WIDTH2 : natural := 10;
        ADDR_WIDTH : natural := 10;
        
        --pb unit
        -- WIDTH_Weight: natural := 16;
        -- WIDTH_Stick:  natural := 16;
        WIDTH_Data:   natural := 16;
        SIGNED_UNSIGNED: string := "signed";
        
        --write controller
        MAC_width  : natural := 32;
        MAC_count  : natural := 64;
        bias_base_addr_width : natural := 12; 
        size       : natural := 64*38
    );
    Port (
        clk_i   : in std_logic;
        rst_i   : in std_logic;
        start_i : in std_logic;
        
        -- FSM inputs
        w_valid_i    : in std_logic;
        d_valid_i    : in std_logic;
        --num_of_pix_i : in std_logic_vector(WIDTH1 - 1 downto 0);
        
        -- FSM outputs
        req_o : out std_logic; 
        ready_o : out std_logic;
        weight_addr_o : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        
        -- PB group inputs
        data_in : in std_logic_vector(WIDTH_Data-1 downto 0);
        weight_in : in std_logic_vector(MAC_count * WIDTH_Data - 1 downto 0);
        
        ------------------- Config registers -------------------
        config2 : in std_logic_vector(31 downto 0);
        config3 : in std_logic_vector(31 downto 0);
        config4 : in std_logic_vector(31 downto 0);
        --config6 : out std_logic_vector(31 downto 0);
        done_o : out std_logic;
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o : out std_logic_vector(31 downto 0);
		axi_write_init_o	 : out std_logic;       									
		axi_write_data_o	 : out std_logic_vector(63 downto 0);								
		axi_write_next_i    : in std_logic;                                
		axi_write_done_i    : in std_logic
		 
		------------------ Result Write controller -----------------
		--write_base_addr_i : in std_logic_vector(31 downto 0);
		--bias_base_addr_i : in std_logic_vector(bias_base_addr_width - 1 downto 0);
		--done_processing_o : out std_logic
        
     );
end PB_top;

architecture Behavioral of PB_top is

--------------------- PB unit declaration ---------------------
component PB_group
    generic(
        WIDTH_Weight: natural := 16;
        WIDTH_Stick:  natural := 16;
        WIDTH_Data:   natural := 16;
        SIGNED_UNSIGNED: string := "signed"
    );
    port(
        en_in:        in std_logic;
        clk:          in std_logic;
        rst_i:       in std_logic;
        weight_in:    in std_logic_vector(4 * WIDTH_Weight-1 downto 0); --One group consists of 4 MAC units, therefore we need 4 weights as an input
        data_in:      in std_logic_vector(WIDTH_Data-1 downto 0);
            
        data_out:     out std_logic_vector(4*(WIDTH_Weight+WIDTH_Data) -1 downto 0)
        
    );
    
end component;

--------------------- PB fsm declaration ---------------------
component FSM_PB
    generic(
        WIDTH1 : natural;
        WIDTH2 : natural; 
        ADDR_WIDTH : natural 
            );
    port(
        --------------- Clocking and reset interface ---------------
        clk_i : in std_logic;
        rst_i : in std_logic;
        ------------------- Input data interface -------------------
        w_valid_i    : in std_logic;
        d_valid_i    : in std_logic;
        start_i      : in std_logic;
        --num_of_pix_i : in std_logic_vector(WIDTH1 - 1 downto 0);
        config4 : in std_logic_vector(31 downto 0);
        ------------------- Output data interface -------------------
        --new_package_o : out std_logic; -- Ovo je mozda visak
        ready_o       : out std_logic;  
        done_o        : out std_logic;
        zero_o        : out std_logic;
        en_o          : out std_logic; 
        req_o         : out std_logic;
        weight_addr_o : out std_logic_vector(ADDR_WIDTH - 1 downto 0)
        );

end component;

--------------------- Result Write Controller declaration ---------------------
component result_write
    Generic(
        MAC_width  : natural;
        MAC_count  : natural;
        -- width      : natural := 24;
        addr_width : natural;
        size       : natural
    );
    Port (
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         start_i : in std_logic;
         ------------------- PB interface -------------------
         PB_data_i : in std_logic_vector(MAC_count * MAC_width - 1 downto 0);
         PB_done_i : in std_logic;
         PB_ready_i : in std_logic; -- kad PB zavrsi
         ------------------- AXI Write interface -------------------
         axi_write_address_o : out std_logic_vector(31 downto 0);
		 axi_write_init_o	 : out std_logic;       									
		 axi_write_data_o	 : out std_logic_vector(63 downto 0);								
		 axi_write_next_i    : in std_logic;                                
		 axi_write_done_i    : in std_logic;
		 ------------------- Configuration Registers Interface -------------------
		 config2 : in std_logic_vector(31 downto 0); 
		 config3 : in std_logic_vector(31 downto 0);
		 config4 : in std_logic_vector(31 downto 0);
		 --config6 : out std_logic_vector(31 downto 0)
		 done_o : out std_logic
		 --write_base_addr_i : in std_logic_vector(31 downto 0);           -- bazna adresa za upis rezultata
		 --bias_base_addr_i : in std_logic_vector(addr_width - 1 downto 0); -- bazna adresa za bias u ovom sloju
		 --done_processing_o : out std_logic
    );
    
end component;


------------------- Signals ------------------- 
-- clk
signal clk_s : std_logic;

-- signals for fsm
signal rst_s, w_valid_s, d_valid_s, start_s : std_logic;
signal num_of_pix_s : std_logic_vector(WIDTH1 - 1 downto 0);
signal new_package_s, ready_s, done_s, en_s, req_s : std_logic;
signal weight_addr_s : std_logic_vector(ADDR_WIDTH - 1 downto 0);

-- signals for pb units
signal data_in_s : std_logic_vector(WIDTH_Data-1 downto 0);
signal data_out_s : std_logic_vector(MAC_count * (WIDTH_Data+WIDTH_Data) -1 downto 0);
signal weight_in_s : std_logic_vector(MAC_count * WIDTH_Data - 1 downto 0);
signal zero_s : std_logic;

-- axi signals
signal axi_write_address_s : std_logic_vector(31 downto 0);
signal axi_write_init_s : std_logic;
signal axi_write_data_s : std_logic_vector(63 downto 0);
signal axi_write_next_s : std_logic;
signal axi_write_done_s : std_logic;

-- configuration signals
--signal write_base_addr_s : std_logic_vector(31 downto 0); 
--signal bias_base_addr_s : std_logic_vector(bias_base_addr_width - 1 downto 0);

begin

------------------------ FSM instantiation ------------------------ 
pb_fsm : FSM_PB
    generic map(
        WIDTH1 => WIDTH1,
        WIDTH2 => WIDTH2,
        ADDR_WIDTH => ADDR_WIDTH
    )
    port map(
        clk_i => clk_s,
        rst_i => rst_s,
        
        w_valid_i    => w_valid_s,
        d_valid_i    => d_valid_s,
        start_i      => start_s,
        --num_of_pix_i => num_of_pix_s,
        config4 => config4,
        
        --new_package_o => new_package_s,
        ready_o       => ready_s, 
        done_o        => done_s,
        zero_o        => zero_s,
        en_o          => en_s,
        req_o         => req_s,
        weight_addr_o => weight_addr_s
    );


------------------------  Generate 16 PB sub-units ------------------------ 
pb_gen : for i in 1 to 16 generate
    
        PBx : PB_Group 
        generic map(
            WIDTH_Weight => WIDTH_Data,
            WIDTH_Stick => WIDTH_Data,
            WIDTH_Data => WIDTH_Data,
            SIGNED_UNSIGNED => SIGNED_UNSIGNED
        )
        port map
        (
            en_in     => en_s,
            clk       => clk_s,
            rst_i     => zero_s,
            weight_in => weight_in_s(i * 4 * WIDTH_Data - 1 downto (i - 1) * 4 * WIDTH_Data),
            data_in   => data_in_s,
            data_out  => data_out_s(i * 4 * (WIDTH_Data + WIDTH_Data) - 1 downto (i - 1) * 4 * (WIDTH_Data + WIDTH_Data)) 
        );
    
    end generate;


------------------------ Write Controller instantiation ------------------------
write_ctrl: result_write
    generic map(
        MAC_width  => MAC_width,
        MAC_count  => MAC_count,
        -- width      : natural := 24;
        addr_width => bias_base_addr_width,
        size       => size
    )
    port map(
        clk_i => clk_s,
        rst_i => rst_s,
        start_i => start_s,
        
        PB_data_i => data_out_s,    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        PB_done_i => done_s,
        PB_ready_i => ready_s,
        
        axi_write_address_o => axi_write_address_s,
		axi_write_init_o	=> axi_write_init_s,    									
		axi_write_data_o	=> axi_write_data_s, 						
		axi_write_next_i    => axi_write_next_s,                               
		axi_write_done_i    => axi_write_done_s,
		
		config2 => config2,
		config3 => config3,
		config4 => config4,
		--config6 => config6
		done_o => done_o
		--write_base_addr_i => write_base_addr_s,
		--bias_base_addr_i => bias_base_addr_s,
		--done_processing_o => done_processing_o
    );


------------------------  connecting signals to top-level ports ------------------------ 
clk_s <= clk_i;

-- fsm
rst_s <= rst_i;
w_valid_s <= w_valid_i;
d_valid_s <= d_valid_i;
start_s <= start_i;
--num_of_pix_s <= num_of_pix_i;
req_o <= req_s;
ready_o <= ready_s;
weight_addr_o <= weight_addr_s;

-- pb group
data_in_s <= data_in;
weight_in_s <= weight_in;

-- AXI 
axi_write_address_o <= axi_write_address_s;
axi_write_init_o	<= axi_write_init_s;    									
axi_write_data_o	<= axi_write_data_s; 						
axi_write_next_s    <= axi_write_next_i;                               
axi_write_done_s    <= axi_write_done_i;

-- write ctrl
--write_base_addr_s <= write_base_addr_i;
--bias_base_addr_s <= bias_base_addr_i;


end Behavioral;
