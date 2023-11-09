LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity cpu is 
    port(in_clk, in_rst : in std_logic; 
         LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0 : out std_logic);
end entity cpu; 

architecture top of cpu is 
    signal r_buf_adr : reglen_t := (others => '0'); 
    signal r_buf_we : std_logic := '0'; 
    signal r_buf_rs1 : reglen_t := (others => '0'); 
    signal r_led : reglen_t := (others => '0'); 
    -- convention: [w]_[signal]_[output_unit]
    -- from fetch 
    signal w_pc_fe : reglen_t; 
    signal w_pc4_fe : reglen_t; 
    -- from decode
    signal w_pc_sel_de : pcsel_t; 
    signal w_pc_load_de : std_logic; 
    signal w_branchadr_de : reglen_t; 
    signal w_missadr_de : reglen_t; 
    signal w_rs0_de : reglen_t; 
    signal w_rs1_de : reglen_t; 
    signal w_imm_de : reglen_t; 
    signal w_imm_sel_de : std_logic; 
    signal w_mem2reg_sel_de : std_logic; 
    signal w_alu_cntrl_de : alucntrl_t; 
    signal w_dmem_we_de : std_logic; 
    signal w_reg_we_de : std_logic; 
    signal w_reg_rd_de : regadr_t; 
    signal w_branch_de : std_logic; 
    signal w_load_de   : std_logic; 
    -- from execute
    signal w_equal_ex : std_logic; 
    signal w_alu_res_ex : reglen_t; 
    signal w_rs1_ex : reglen_t; 
    signal w_mem2reg_sel_ex : std_logic; 
    signal w_dmem_we_ex : std_logic; 
    signal w_reg_we_ex : std_logic; 
    signal w_reg_rd_ex : regadr_t; 
    signal w_branch_ex : std_logic; 
    signal w_load_ex   : std_logic; 
    -- from memory 
    signal w_reg_we_mem : std_logic; 
    signal w_reg_rd_mem : regadr_t; 
    signal w_mem2reg_sel_mem : std_logic; 
    signal w_mem_res_mem : reglen_t; 
    signal w_alu_res_mem : reglen_t;
    signal w_dcache_ready_mem : std_logic; 
    -- from writeback 
    signal w_reg_data_wb : reglen_t; 
    signal w_reg_we_wb : std_logic; 
    signal w_reg_rd_wb : regadr_t; 
begin 

    FETCH: entity work.fetch(RTL)
        port map(in_clk => in_clk, 
                 in_rst => in_rst,
                 in_pc_sel => w_pc_sel_de,
                 in_pc_load => w_pc_load_de,
                 in_branchadr => w_branchadr_de, 
                 in_missadr => w_missadr_de, 
                 out_pc => w_pc_fe, 
                 out_pc4 => w_pc4_fe); 
    
    DECODE: entity work.decode(RTL)
        port map(in_clk => in_clk, 
                 in_rst => in_rst,
                 in_pc_fe => w_pc_fe,
                 in_pc4_fe => w_pc4_fe,
                 in_equal_ex => w_equal_ex,
                 in_branch_ex => w_branch_ex,
                 in_reg_we_ex => w_reg_we_ex,
                 in_reg_rd_ex => w_reg_rd_ex,
                 in_mem2reg_sel_ex => w_mem2reg_sel_ex, 
                 in_alu_res_ex => w_alu_res_ex, 
                 in_reg_rd_mem => w_reg_rd_mem,
                 in_reg_we_mem => w_reg_we_mem,
                 in_mem2reg_sel_mem => w_mem2reg_sel_mem,
                 in_alu_res_mem => w_alu_res_mem, 
                 in_mem_res_mem => w_mem_res_mem,
                 in_reg_rd_wb => w_reg_rd_wb,
                 in_reg_we_wb => w_reg_we_wb,
                 in_reg_data_wb => w_reg_data_wb,
                 in_dcache_ready => w_dcache_ready_mem,
                 out_pc_sel => w_pc_sel_de,
                 out_pc_load => w_pc_load_de,
                 out_branchadr => w_branchadr_de,
                 out_missadr => w_missadr_de,
                 out_rs0 => w_rs0_de, 
                 out_rs1 => w_rs1_de,
                 out_imm => w_imm_de,
                 out_imm_sel => w_imm_sel_de,
                 out_mem2reg_sel => w_mem2reg_sel_de,
                 out_alu_cntrl => w_alu_cntrl_de,
                 out_dmem_we => w_dmem_we_de,
                 out_reg_we => w_reg_we_de,
                 out_reg_rd => w_reg_rd_de, 
                 out_branch => w_branch_de,
                 out_load => w_load_de); 

    EXECUTE: entity work.execute(RTL)
        port map(in_clk => in_clk,
                 in_rst => in_rst,
                 in_rs0 => w_rs0_de,
                 in_rs1 => w_rs1_de,
                 in_imm => w_imm_de,
                 in_imm_sel => w_imm_sel_de,
                 in_reg_we => w_reg_we_de,
                 in_reg_rd => w_reg_rd_de, 
                 in_branch => w_branch_de,
                 in_mem2reg_sel => w_mem2reg_sel_de,
                 in_alu_cntrl => w_alu_cntrl_de,
                 in_dmem_we => w_dmem_we_de,
                 in_load => w_load_de,
                 in_dcache_ready => w_dcache_ready_mem,
                 out_equal => w_equal_ex,
                 out_alu_res => w_alu_res_ex,
                 out_rs1 => w_rs1_ex,
                 out_mem2reg_sel => w_mem2reg_sel_ex,
                 out_dmem_we => w_dmem_we_ex,
                 out_reg_we => w_reg_we_ex,
                 out_reg_rd => w_reg_rd_ex, 
                 out_branch => w_branch_ex,
                 out_load => w_load_ex); 

    MEMORY: entity work.memory(RTL)
        port map(in_clk => in_clk,
                 in_rst => in_rst,
                 in_alu_res => w_alu_res_ex,
                 in_rs1 => w_rs1_ex,
                 in_mem2reg_sel => w_mem2reg_sel_ex,
                 in_dmem_we => w_dmem_we_ex,  
                 in_reg_we => w_reg_we_ex,
                 in_reg_rd => w_reg_rd_ex, 
                 in_load => w_load_ex,
                 out_reg_we => w_reg_we_mem,
                 out_reg_rd => w_reg_rd_mem,
                 out_mem2reg_sel => w_mem2reg_sel_mem,
                 out_mem_res => w_mem_res_mem,
                 out_alu_res => w_alu_res_mem,
                 out_dcache_ready => w_dcache_ready_mem); 
    
    WRITEBACK: entity work.writeback(RTL)
        port map(in_clk => in_clk,
                 in_rst => in_rst,
                 in_reg_we => w_reg_we_mem,
                 in_reg_rd => w_reg_rd_mem, 
                 in_mem2reg_sel => w_mem2reg_sel_mem,
                 in_mem_res => w_mem_res_mem,
                 in_alu_res => w_alu_res_mem,
                 out_reg_data => w_reg_data_wb,
                 out_reg_we => w_reg_we_wb,
                 out_reg_rd => w_reg_rd_wb); 

    p_LED : process(in_clk)
    begin 
        if(rising_edge(in_clk)) then
            if(r_buf_adr = x"00002000" and r_buf_we = '1') then 
                r_led <= r_buf_rs1; 
            end if; 
            r_buf_adr <= w_alu_res_ex; 
            r_buf_we <= w_dmem_we_ex; 
            r_buf_rs1 <= w_rs1_ex; 
        end if; 
    end process; 

    (LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0) <= r_led(7 downto 0); 
end architecture top; 
