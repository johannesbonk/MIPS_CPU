LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL;

entity tb_dcache is
end tb_dcache;

architecture tb of tb_dcache is
    constant c_DELTA_TIME : time := 1 ns;
    
    signal w_clk : std_logic; 
    signal w_rst : std_logic; 
    
    signal w_dcache_ready : std_logic; 
    signal w_dcache_data_mem : reglen_t; 
    signal w_dcache_data_core : reglen_t; 
    signal w_dcache_req : std_logic; 
    signal w_dcache_adr : reglen_t; 
    signal w_dcache_write : std_logic; 
    signal w_core_adr : reglen_t; 
    signal w_core_req : std_logic;
    signal w_core_write : std_logic;
    signal w_core_data : reglen_t;
    signal w_mem_data : reglen_t; 
    signal w_mem_ready : std_logic; 

    begin
        DCACHE : entity work.dcache(RTL)
        port map(in_clk => w_clk, 
                in_rst => w_rst, 
                core_to_dcache.adr => w_core_adr, 
                core_to_dcache.req => w_core_req,
                core_to_dcache.write => w_core_write,
                core_to_dcache.data => w_core_data,
                dcache_to_core.data  => w_dcache_data_core,
                dcache_to_core.ready => w_dcache_ready, 
                dcache_to_mem.adr => w_dcache_adr, 
                dcache_to_mem.req => w_dcache_req, 
                dcache_to_mem.write => w_dcache_write, 
                dcache_to_mem.data => w_dcache_data_mem, 
                mem_to_dcache.ready => w_mem_ready,
                mem_to_dcache.data => w_mem_data); 

    p_SIMULATION : process
    begin
        w_clk <= '0';
        w_rst <= '1'; 
        w_core_adr <= (others => '0'); 
        w_core_req <= '0'; 
        w_core_data <= (others => '1'); 
        w_mem_ready <= '0'; 
        w_mem_data <= (others => '0');
        
        
        -- cache first address

        wait for c_DELTA_TIME; 
        w_clk <= '1'; 
        w_rst <= '0'; 

        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        w_core_adr <= x"00_00_01_00"; 
        w_core_req <= '1'; 

        wait for c_DELTA_TIME; 
        w_clk <= '1'; 


        for i in 0 to 3 loop
            wait for c_DELTA_TIME; 
            w_clk <= '0'; 

            w_mem_ready <= '0'; 
            w_mem_data <= (others => '-'); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 

            wait for c_DELTA_TIME; 
            w_clk <= '0'; 
            w_mem_ready <= '1'; 
            w_mem_data <= std_logic_vector(to_unsigned(i, w_mem_data'length)); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
            wait for c_DELTA_TIME; 
            w_clk <= '0';     
            w_mem_ready <= '0';         
            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
        end loop; 
 
        -- write to it      
        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        wait for c_DELTA_TIME; 
        w_clk <= '1';        
        wait for c_DELTA_TIME; 
        w_clk <= '0';
        w_core_write <= '1';   
        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        wait for c_DELTA_TIME; 
        w_clk <= '1';        
        wait for c_DELTA_TIME; 
        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        wait for c_DELTA_TIME; 
        w_clk <= '1';        
        wait for c_DELTA_TIME; 
        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        wait for c_DELTA_TIME; 

        -- read new block 
        w_core_write <= '0'; 
        w_core_adr <= x"00_00_00_00"; 
        w_core_req <= '1'; 

        wait for c_DELTA_TIME; 
        w_clk <= '1'; 


        for i in 0 to 3 loop
            wait for c_DELTA_TIME; 
            w_clk <= '0'; 

            w_mem_ready <= '0'; 
            w_mem_data <= (others => '-'); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 

            wait for c_DELTA_TIME; 
            w_clk <= '0'; 
            w_mem_ready <= '1'; 
            w_mem_data <= std_logic_vector(to_unsigned(i, w_mem_data'length)); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
            wait for c_DELTA_TIME; 
            w_clk <= '0';     
            w_mem_ready <= '0';         
            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
        end loop; 

        wait; --make process wait for an infinite timespan
    end process;
end architecture tb;