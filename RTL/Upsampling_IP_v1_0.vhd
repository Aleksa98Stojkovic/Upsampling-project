library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Upsampling_IP_v1_0 is
	generic (
		-- Users to add parameters here

        -------------------------- WMEM module -------------------------- 
        DATA_WIDTH       : integer := 64; 
        READ_MEM_ADDR    : integer := 32;
        BRAM_ADDR_OFFSET : integer := 512;
        BRAM_count       : natural := 16;  
        wmem_size        : natural := 9*64;
        
        -------------------------- PB module -------------------------- 
        WIDTH           : natural := 10;
        ADDR_WIDTH      : natural := 10;
        WIDTH_Data      : natural := 16;
        SIGNED_UNSIGNED : string  := "signed";
        MAC_width       : natural := 32;
        bias_base_addr_width : natural := 12; 
        bias_size       : natural := 64*38;
        
        -------------------------- Cache module --------------------------
        col_width        : natural := 9;
        i_width          : natural := 10;
        cache_addr_width : natural := 8;
        cache_line_count : natural := 15;
        kernel_size      : natural := 9;
        RF_addr_width    : natural := 4;
        size             : natural := 240;

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXI
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5;

		-- Parameters of Axi Master Bus Interface M_AXI
		--C_M_AXI_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
		C_M_AXI_BURST_LEN	: integer	:= 64;
		C_M_AXI_ID_WIDTH	: integer	:= 1;
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 64;
		C_M_AXI_AWUSER_WIDTH	: integer	:= 0;
		C_M_AXI_ARUSER_WIDTH	: integer	:= 0;
		C_M_AXI_WUSER_WIDTH	: integer	:= 0;
		C_M_AXI_RUSER_WIDTH	: integer	:= 0;
		C_M_AXI_BUSER_WIDTH	: integer	:= 0
	);
	port (
		-- Users to add ports here

--        -- ILA signals
--		ila_stick_in : out std_logic_vector(WIDTH_Data - 1 downto 0);
--		ila_weight_in : out std_logic_vector(WIDTH_Data - 1 downto 0);
--		ila_mult_acc : out std_logic_vector(MAC_width - 1 downto 0);
--		ila_mac_en : out std_logic;
--		ila_mac_done : out std_logic;

        --debug_diode : out std_logic;

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S_AXI
		s_axi_aclk	: in std_logic;
		s_axi_aresetn	: in std_logic;
		s_axi_awaddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_awprot	: in std_logic_vector(2 downto 0);
		s_axi_awvalid	: in std_logic;
		s_axi_awready	: out std_logic;
		s_axi_wdata	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_wstrb	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		s_axi_wvalid	: in std_logic;
		s_axi_wready	: out std_logic;
		s_axi_bresp	: out std_logic_vector(1 downto 0);
		s_axi_bvalid	: out std_logic;
		s_axi_bready	: in std_logic;
		s_axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_arprot	: in std_logic_vector(2 downto 0);
		s_axi_arvalid	: in std_logic;
		s_axi_arready	: out std_logic;
		s_axi_rdata	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_rresp	: out std_logic_vector(1 downto 0);
		s_axi_rvalid	: out std_logic;
		s_axi_rready	: in std_logic;

		-- Ports of Axi Master Bus Interface M_AXI
		--m_axi_init_axi_txn	: in std_logic;
		--m_axi_txn_done	: out std_logic;
		--m_axi_error	: out std_logic;
		m_axi_aclk	: in std_logic;
		m_axi_aresetn	: in std_logic;
		m_axi_awid	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m_axi_awaddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_awlen	: out std_logic_vector(7 downto 0);
		m_axi_awsize	: out std_logic_vector(2 downto 0);
		m_axi_awburst	: out std_logic_vector(1 downto 0);
		m_axi_awlock	: out std_logic;
		m_axi_awcache	: out std_logic_vector(3 downto 0);
		m_axi_awprot	: out std_logic_vector(2 downto 0);
		m_axi_awqos	: out std_logic_vector(3 downto 0);
		m_axi_awuser	: out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);
		m_axi_awvalid	: out std_logic;
		m_axi_awready	: in std_logic;
		m_axi_wdata	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_wstrb	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		m_axi_wlast	: out std_logic;
		m_axi_wuser	: out std_logic_vector(C_M_AXI_WUSER_WIDTH-1 downto 0);
		m_axi_wvalid	: out std_logic;
		m_axi_wready	: in std_logic;
		m_axi_bid	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m_axi_bresp	: in std_logic_vector(1 downto 0);
		m_axi_buser	: in std_logic_vector(C_M_AXI_BUSER_WIDTH-1 downto 0);
		m_axi_bvalid	: in std_logic;
		m_axi_bready	: out std_logic;
		m_axi_arid	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m_axi_araddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_arlen	: out std_logic_vector(7 downto 0);
		m_axi_arsize	: out std_logic_vector(2 downto 0);
		m_axi_arburst	: out std_logic_vector(1 downto 0);
		m_axi_arlock	: out std_logic;
		m_axi_arcache	: out std_logic_vector(3 downto 0);
		m_axi_arprot	: out std_logic_vector(2 downto 0);
		m_axi_arqos	: out std_logic_vector(3 downto 0);
		m_axi_aruser	: out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);
		m_axi_arvalid	: out std_logic;
		m_axi_arready	: in std_logic;
		m_axi_rid	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m_axi_rdata	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_rresp	: in std_logic_vector(1 downto 0);
		m_axi_rlast	: in std_logic;
		m_axi_ruser	: in std_logic_vector(C_M_AXI_RUSER_WIDTH-1 downto 0);
		m_axi_rvalid	: in std_logic;
		m_axi_rready	: out std_logic
	);
end Upsampling_IP_v1_0;

architecture arch_imp of Upsampling_IP_v1_0 is

    -- user component
    component IP_with_router_top is
    generic(
        -------------------------- WMEM module -------------------------- 
        DATA_WIDTH       : integer := 64; 
        READ_MEM_ADDR    : integer := 32;
        BRAM_ADDR_OFFSET : integer := 512;
        BRAM_count       : natural := 16;  
        wmem_size        : natural := 9*64;
        
        -------------------------- PB module -------------------------- 
        WIDTH           : natural := 10;
        ADDR_WIDTH      : natural := 10;
        WIDTH_Data      : natural := 16;
        SIGNED_UNSIGNED : string  := "signed";
        MAC_width       : natural := 32;
        bias_base_addr_width : natural := 12; 
        bias_size       : natural := 64*38;
        
        -------------------------- Cache module --------------------------
        col_width        : natural := 9;
        i_width          : natural := 10;
        cache_addr_width : natural := 8;
        cache_line_count : natural := 15;
        kernel_size      : natural := 9;
        RF_addr_width    : natural := 4;
        size             : natural := 240
            );
    Port(
        ------------------- Clock and Reset interface -------------------
        clk_i : in std_logic;
        rst_i : in std_logic;    
    
		------------------- Configuration interface -------------------
		config1 : in std_logic_vector(31 downto 0);
		config2 : in std_logic_vector(31 downto 0);
		config3 : in std_logic_vector(31 downto 0);
		config4 : in std_logic_vector(31 downto 0);
		config5 : in std_logic_vector(31 downto 0);
		config6 : out std_logic_vector(31 downto 0);
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o  : out std_logic_vector(READ_MEM_ADDR - 1 downto 0);
		axi_write_init_o	 : out std_logic;       									
		axi_write_data_o	 : out std_logic_vector(DATA_WIDTH - 1 downto 0);								
		axi_write_next_i     : in std_logic;                                
		axi_write_done_i     : in std_logic;
            
        ------------------- AXI Read interface -------------------
        axi_read_init_o        : out std_logic;
        axi_read_data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axi_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi_read_last_i        : in std_logic;  
        axi_read_valid_i       : in std_logic;  
        axi_read_ready_o       : out std_logic
        
--        -- ILA signals
--		ila_stick_in : out std_logic_vector(WIDTH_Data - 1 downto 0);
--		ila_weight_in : out std_logic_vector(WIDTH_Data - 1 downto 0);
--		ila_mult_acc : out std_logic_vector(MAC_width - 1 downto 0);
--		ila_mac_en : out std_logic;
--		ila_mac_done : out std_logic
        
        --debugDiode : out std_logic
        
        );
        
end component;


	-- component declaration
	component Upsampling_IP_v1_0_S_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		config_reg1 : out std_logic_vector(31 downto 0);
        config_reg2 : out std_logic_vector(31 downto 0);
        config_reg3 : out std_logic_vector(31 downto 0);
        config_reg4 : out std_logic_vector(31 downto 0);
        config_reg5 : out std_logic_vector(31 downto 0);
        config_reg6 : in std_logic_vector(31 downto 0);
        config_reg7 : out std_logic_vector(31 downto 0);
		
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component Upsampling_IP_v1_0_S_AXI;

	component Upsampling_IP_v1_0_M_AXI is
		generic (
		--C_M_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
		C_M_AXI_BURST_LEN	: integer	:= 64;
		C_M_AXI_ID_WIDTH	: integer	:= 1;
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 64;
		C_M_AXI_AWUSER_WIDTH	: integer	:= 0;
		C_M_AXI_ARUSER_WIDTH	: integer	:= 0;
		C_M_AXI_WUSER_WIDTH	: integer	:= 0;
		C_M_AXI_RUSER_WIDTH	: integer	:= 0;
		C_M_AXI_BUSER_WIDTH	: integer	:= 0
		);
		port (
		-- Users to add ports here
		axi_base_address_i : in std_logic_vector(31 downto 0);  -- Bazna Adresa 
		
		--  WRITE CHANNEL
		axi_write_address_i : in std_logic_vector(31 downto 0); -- Adresa koja se dodaje na baznu adresu, tu se upisuju podaci u DDR-u
		
		axi_write_init_i	: in std_logic;                     -- Port preko koga se kaže AXI kontroleru da krene sa upisom, dovede se puls u trajanju od jednog takta.
		                                                        -- Nakon toga kre?e prenos sve dok se ne pošalje C_M_AXI_BURST_LEN podataka. Ukoliko je C_M_AXI_BURST_LEN = 8,
																-- posla?e se 8 32-bitnih podataka.
																
		axi_write_data_i	: in std_logic_vector(63 downto 0); -- Magistrala preko koje se dovode podaci, svaki put kada je axi_write_next_o = 1
									    -- u narednom taktu se mora postaviti naredni podatak koji treba upisati.
																
		axi_write_next_o : out std_logic;                       -- Naznaka da je postavljeni podatak preuzet, u narednom taktu obavezno postaviti slede?i podatak koji treba
		                                                        -- upisati.
		axi_write_done_o : out std_logic;                       -- Naznaka da je upis podataka gotov
		
		-- READ CHANNEL
		axi_read_address_i : in std_logic_vector(31 downto 0);  -- Adresa koja se dodaje na baznu adresu, odatle se ?itaju podaci iz DDR-a
		axi_read_init_i	: in std_logic;                         -- Port preko koga se kaže AXI kontroleru da krene sa ?itanjem, dovede se puls u trajanju od jednog takta.
		axi_read_data_o	: out std_logic_vector(63 downto 0);    -- Magistrala preko koje pristižu podaci
		axi_read_valid_o : out std_logic;                        -- Naznaka da je pristigli podatak validan
		axi_read_ready_i: in std_logic;  -- ovo smo naknadno dodali
		axi_read_last_o : out std_logic;
		-- User ports ends
		
		--INIT_AXI_TXN	: in std_logic;
		--TXN_DONE	: out std_logic;
		--ERROR	: out std_logic;
		M_AXI_ACLK	: in std_logic;
		M_AXI_ARESETN	: in std_logic;
		M_AXI_AWID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
		M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
		M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
		M_AXI_AWLOCK	: out std_logic;
		M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
		M_AXI_AWUSER	: out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);
		M_AXI_AWVALID	: out std_logic;
		M_AXI_AWREADY	: in std_logic;
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		M_AXI_WLAST	: out std_logic;
		M_AXI_WUSER	: out std_logic_vector(C_M_AXI_WUSER_WIDTH-1 downto 0);
		M_AXI_WVALID	: out std_logic;
		M_AXI_WREADY	: in std_logic;
		M_AXI_BID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		M_AXI_BUSER	: in std_logic_vector(C_M_AXI_BUSER_WIDTH-1 downto 0);
		M_AXI_BVALID	: in std_logic;
		M_AXI_BREADY	: out std_logic;
		M_AXI_ARID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
		M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
		M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
		M_AXI_ARLOCK	: out std_logic;
		M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
		M_AXI_ARUSER	: out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);
		M_AXI_ARVALID	: out std_logic;
		M_AXI_ARREADY	: in std_logic;
		M_AXI_RID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		M_AXI_RLAST	: in std_logic;
		M_AXI_RUSER	: in std_logic_vector(C_M_AXI_RUSER_WIDTH-1 downto 0);
		M_AXI_RVALID	: in std_logic;
		M_AXI_RREADY	: out std_logic
		);
	end component Upsampling_IP_v1_0_M_AXI;
	
	-- AXI Signals --
    -- Write
    signal axi_write_address_s : std_logic_vector(31 downto 0);
	signal axi_write_init_s : std_logic;
	signal axi_write_data_s : std_logic_vector(63 downto 0);
	signal axi_write_next_s : std_logic;
	signal axi_write_done_s : std_logic;
	-- Read
	signal axi_read_init_s : std_logic;
    signal axi_read_data_s : std_logic_vector(63 downto 0);
    signal axi_read_addr_s : std_logic_vector(31 downto 0);
    signal axi_read_last_s : std_logic;
    signal axi_read_valid_s : std_logic;
    signal axi_read_ready_s : std_logic;

    -- Config signals
    signal config1_s : std_logic_vector(31 downto 0);
	signal config2_s : std_logic_vector(31 downto 0);
	signal config3_s : std_logic_vector(31 downto 0);
	signal config4_s : std_logic_vector(31 downto 0);
	signal config5_s : std_logic_vector(31 downto 0);
	signal config6_s : std_logic_vector(31 downto 0);
	signal config7_s : std_logic_vector(31 downto 0);
    
    -- Reset signal
    signal rst_s : std_logic;

begin

-- Instantiation of Upsampling Design
Upsampling_Design: IP_with_router_top
    generic map(
        -------------------------- WMEM module -------------------------- 
        DATA_WIDTH       => DATA_WIDTH,
        READ_MEM_ADDR    => READ_MEM_ADDR,
        BRAM_ADDR_OFFSET => BRAM_ADDR_OFFSET,
        BRAM_count       => BRAM_count,
        wmem_size        => wmem_size,
        
        -------------------------- PB module -------------------------- 
        WIDTH           => WIDTH,
        ADDR_WIDTH      => ADDR_WIDTH,
        WIDTH_Data      => WIDTH_Data,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED,
        MAC_width       => MAC_width,
        bias_base_addr_width => bias_base_addr_width,
        bias_size       => bias_size,
        
        -------------------------- Cache module --------------------------
        col_width        => col_width,
        i_width          => i_width,
        cache_addr_width => cache_addr_width,
        cache_line_count => cache_line_count,
        kernel_size      => kernel_size,
        RF_addr_width    => RF_addr_width,
        size             => size
    )
    port map(
        ------------------- Clock and Reset interface -------------------
        clk_i => m_axi_aclk,
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
		axi_write_data_o	 => axi_write_data_s,
		axi_write_next_i     => axi_write_next_s,
		axi_write_done_i     => axi_write_done_s,
            
        ------------------- AXI Read interface -------------------
        axi_read_init_o        => axi_read_init_s,
        axi_read_data_i        => axi_read_data_s,
        axi_read_addr_o        => axi_read_addr_s,
        axi_read_last_i        => axi_read_last_s,
        axi_read_valid_i       => axi_read_valid_s,
        axi_read_ready_o       => axi_read_ready_s
        
--        -- ILA signals
--		ila_stick_in => ila_stick_in,
--		ila_weight_in => ila_weight_in,
--		ila_mult_acc => ila_mult_acc,
--		ila_mac_en => ila_mac_en,
--		ila_mac_done => ila_mac_done
        
        --debugDiode => debug_diode      
    );

-- Instantiation of Axi Bus Interface S_AXI
Upsampling_IP_v2_v1_0_S_AXI_inst : Upsampling_IP_v1_0_S_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
	    config_reg1 => config1_s,
	    config_reg2 => config2_s,
	    config_reg3 => config3_s,
	    config_reg4 => config4_s,
	    config_reg5 => config5_s,
	    config_reg6 => config6_s,
	    config_reg7 => config7_s,
	
		S_AXI_ACLK	=> s_axi_aclk,
		S_AXI_ARESETN	=> s_axi_aresetn,
		S_AXI_AWADDR	=> s_axi_awaddr,
		S_AXI_AWPROT	=> s_axi_awprot,
		S_AXI_AWVALID	=> s_axi_awvalid,
		S_AXI_AWREADY	=> s_axi_awready,
		S_AXI_WDATA	=> s_axi_wdata,
		S_AXI_WSTRB	=> s_axi_wstrb,
		S_AXI_WVALID	=> s_axi_wvalid,
		S_AXI_WREADY	=> s_axi_wready,
		S_AXI_BRESP	=> s_axi_bresp,
		S_AXI_BVALID	=> s_axi_bvalid,
		S_AXI_BREADY	=> s_axi_bready,
		S_AXI_ARADDR	=> s_axi_araddr,
		S_AXI_ARPROT	=> s_axi_arprot,
		S_AXI_ARVALID	=> s_axi_arvalid,
		S_AXI_ARREADY	=> s_axi_arready,
		S_AXI_RDATA	=> s_axi_rdata,
		S_AXI_RRESP	=> s_axi_rresp,
		S_AXI_RVALID	=> s_axi_rvalid,
		S_AXI_RREADY	=> s_axi_rready
	);

-- Instantiation of Axi Bus Interface M_AXI
Upsampling_IP_v2_v1_0_M_AXI_inst : Upsampling_IP_v1_0_M_AXI
	generic map (
		--C_M_TARGET_SLAVE_BASE_ADDR	=> C_M_AXI_TARGET_SLAVE_BASE_ADDR,
		C_M_AXI_BURST_LEN	=> C_M_AXI_BURST_LEN,
		C_M_AXI_ID_WIDTH	=> C_M_AXI_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_M_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_M_AXI_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_M_AXI_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_M_AXI_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_M_AXI_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_M_AXI_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_M_AXI_BUSER_WIDTH
	)
	port map (
		-- Users to add ports here
		axi_base_address_i => config7_s,
		
		--  WRITE CHANNEL
		axi_write_address_i => axi_write_address_s,	
		axi_write_init_i =>	axi_write_init_s,									
		axi_write_data_i =>	axi_write_data_s,								
		axi_write_next_o => axi_write_next_s,
		axi_write_done_o => axi_write_done_s,
		
		-- READ CHANNEL
		axi_read_address_i => axi_read_addr_s,
		axi_read_init_i	=> axi_read_init_s,
		axi_read_data_o	=> axi_read_data_s,
		axi_read_valid_o => axi_read_valid_s,
		axi_read_ready_i => axi_read_ready_s,
		axi_read_last_o => axi_read_last_s,
		-- User ports ends
	
		--INIT_AXI_TXN	=> m_axi_init_axi_txn,
		--TXN_DONE	=> m_axi_txn_done,
		--ERROR	=> m_axi_error,
		M_AXI_ACLK	=> m_axi_aclk,
		M_AXI_ARESETN	=> m_axi_aresetn,
		M_AXI_AWID	=> m_axi_awid,
		M_AXI_AWADDR	=> m_axi_awaddr,
		M_AXI_AWLEN	=> m_axi_awlen,
		M_AXI_AWSIZE	=> m_axi_awsize,
		M_AXI_AWBURST	=> m_axi_awburst,
		M_AXI_AWLOCK	=> m_axi_awlock,
		M_AXI_AWCACHE	=> m_axi_awcache,
		M_AXI_AWPROT	=> m_axi_awprot,
		M_AXI_AWQOS	=> m_axi_awqos,
		M_AXI_AWUSER	=> m_axi_awuser,
		M_AXI_AWVALID	=> m_axi_awvalid,
		M_AXI_AWREADY	=> m_axi_awready,
		M_AXI_WDATA	=> m_axi_wdata,
		M_AXI_WSTRB	=> m_axi_wstrb,
		M_AXI_WLAST	=> m_axi_wlast,
		M_AXI_WUSER	=> m_axi_wuser,
		M_AXI_WVALID	=> m_axi_wvalid,
		M_AXI_WREADY	=> m_axi_wready,
		M_AXI_BID	=> m_axi_bid,
		M_AXI_BRESP	=> m_axi_bresp,
		M_AXI_BUSER	=> m_axi_buser,
		M_AXI_BVALID	=> m_axi_bvalid,
		M_AXI_BREADY	=> m_axi_bready,
		M_AXI_ARID	=> m_axi_arid,
		M_AXI_ARADDR	=> m_axi_araddr,
		M_AXI_ARLEN	=> m_axi_arlen,
		M_AXI_ARSIZE	=> m_axi_arsize,
		M_AXI_ARBURST	=> m_axi_arburst,
		M_AXI_ARLOCK	=> m_axi_arlock,
		M_AXI_ARCACHE	=> m_axi_arcache,
		M_AXI_ARPROT	=> m_axi_arprot,
		M_AXI_ARQOS	=> m_axi_arqos,
		M_AXI_ARUSER	=> m_axi_aruser,
		M_AXI_ARVALID	=> m_axi_arvalid,
		M_AXI_ARREADY	=> m_axi_arready,
		M_AXI_RID	=> m_axi_rid,
		M_AXI_RDATA	=> m_axi_rdata,
		M_AXI_RRESP	=> m_axi_rresp,
		M_AXI_RLAST	=> m_axi_rlast,
		M_AXI_RUSER	=> m_axi_ruser,
		M_AXI_RVALID	=> m_axi_rvalid,
		M_AXI_RREADY	=> m_axi_rready
	);

	-- Add user logic here

    rst_s <= not m_axi_aresetn;

	-- User logic ends

end arch_imp;
