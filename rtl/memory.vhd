LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity memory is 
    port(in_clk, in_rst : in std_logic; 
         in_alu_res     : in reglen_t;
         in_rs1         : in reglen_t; 
         in_mem2reg_sel : in std_logic; 
         in_dmem_we     : in std_logic;
         in_reg_we      : in std_logic; 
         in_reg_rd      : in regadr_t; 
         in_load        : in std_logic; 
         out_reg_we     : out std_logic;
         out_reg_rd     : out regadr_t;  
         out_mem2reg_sel : out std_logic; 
         out_mem_res    : out reglen_t; 
         out_alu_res    : out reglen_t; 
         out_dcache_ready : out std_logic
         );
end entity memory; 

architecture RTL of memory is
    signal r_alu_res : reglen_t; 
    signal r_mem2reg_sel : std_logic;
    signal r_reg_we : std_logic; 
    signal r_dmem_we : std_logic := '0'; 
    signal r_reg_rd : regadr_t; 
    signal r_load : std_logic := '0'; 
    signal r_rs1 : reglen_t; 

    -- cache signals 
    signal w_dcache_ready : std_logic;  
    signal w_dcache_req : std_logic; 
    signal w_dcache_adr : reglen_t; 
    signal w_dcache_write : std_logic; 
    signal w_dcache_data : reglen_t; 
    signal w_mem_data : reglen_t; 
    signal w_mem_ready : std_logic; 

    signal w_req : std_logic; 
begin 

    p_PIPELINE_REGISTER : process(in_clk)
    begin
        if(rising_edge(in_clk)) then 
            if(w_dcache_ready = '1' or (not (r_load or r_dmem_we)) = '1') then 
                r_alu_res <= in_alu_res; 
                r_mem2reg_sel <= in_mem2reg_sel; 
                r_reg_we <= in_reg_we; 
                r_reg_rd <= in_reg_rd; 
                r_load <= in_load; 
                r_dmem_we <= in_dmem_we; 
                r_rs1 <= in_rs1; 
            else 
                r_alu_res <= r_alu_res; 
                r_mem2reg_sel <= r_mem2reg_sel; 
                r_reg_we <= r_reg_we; 
                r_reg_rd <= r_reg_rd; 
                r_load <= r_load; 
                r_dmem_we <= r_dmem_we; 
                r_rs1 <= r_rs1; 
            end if; 
        end if;
    end process; 

    DATA_MEM : entity work.data_mem(behavioral)
        generic map(ADDRESS_WIDTH => 7,
                    DATA_WIDTH => 32)
        port map    (in_clk => in_clk, 
                    in_en_p0 => '1', 
                    in_en_p1  => '0', 
                    in_we_p0  => w_dcache_req, 
                    in_we_p1  => '0', 
                    in_addr_p0 => w_dcache_adr(8 downto 2), 
                    in_addr_p1 => (others => '-'), 
                    in_d_p0  => w_dcache_data,  
                    in_d_p1 => (others => '-'), 
                    out_d_p0 => w_mem_data, 
                    out_d_p1 => open,
                    out_ready => w_mem_ready); 
    
    w_req <= in_load or in_dmem_we;
    
    DCACHE : entity work.dcache(RTL)
        port map(in_clk => in_clk, 
                in_rst => in_rst, 
                core_to_dcache.adr => r_alu_res, 
                core_to_dcache.req => w_req,
                core_to_dcache.write => in_dmem_we,
                core_to_dcache.data => r_rs1,
                dcache_to_core.data  => out_mem_res,
                dcache_to_core.ready => w_dcache_ready, 
                dcache_to_mem.adr => w_dcache_adr, 
                dcache_to_mem.req => w_dcache_req, 
                dcache_to_mem.write => w_dcache_write, 
                dcache_to_mem.data => w_dcache_data, 
                mem_to_dcache.ready => w_mem_ready,
                mem_to_dcache.data => w_mem_data); 

    out_dcache_ready <= w_dcache_ready or (not (r_load or r_dmem_we)); 

    -- signal passthrough 
    out_reg_we <= r_reg_we; 
    out_reg_rd <= r_reg_rd; 
    out_mem2reg_sel <= r_mem2reg_sel; 
    out_alu_res <= r_alu_res; 


end architecture RTL; 
