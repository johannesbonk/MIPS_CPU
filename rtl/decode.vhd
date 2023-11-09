LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity decode is 
    port(in_clk, in_rst : in std_logic;
        -- from fetch 
         in_pc_fe      : in reglen_t; 
         in_pc4_fe     : in reglen_t; 
         -- from execute
         in_equal_ex : in std_logic;
         in_branch_ex : in std_logic; 
         in_reg_rd_ex : in regadr_t; 
         in_reg_we_ex : in std_logic; 
         in_mem2reg_sel_ex : in std_logic; 
         in_alu_res_ex : in reglen_t; 
         -- from memory 
         in_reg_rd_mem : in regadr_t; 
         in_reg_we_mem : in std_logic; 
         in_mem2reg_sel_mem : in std_logic; 
         in_alu_res_mem : in reglen_t; 
         in_mem_res_mem : in reglen_t; 
         in_dcache_ready : in std_logic; 
         -- from writeback
         in_reg_rd_wb : in regadr_t; 
         in_reg_we_wb : in std_logic;
         in_reg_data_wb : in reglen_t;
         -- to fetch
         out_pc_sel : out pcsel_t;
         out_pc_load : out std_logic; 
         out_branchadr : out reglen_t; 
         out_missadr : out reglen_t; 
         -- to execute
         out_rs0    : out reglen_t;
         out_rs1    : out reglen_t; 
         out_imm    : out reglen_t; 
         out_imm_sel    : out std_logic;
         out_mem2reg_sel : out std_logic;
         out_alu_cntrl   : out alucntrl_t; 
         out_dmem_we   : out std_logic;
         out_reg_we : out std_logic; 
         out_reg_rd : out regadr_t; 
         out_branch : out std_logic;
         out_load : out std_logic
         );
end entity decode; 

architecture RTL of decode is 
    -- pipeline registers 
    signal r_pc4 : reglen_t; 
    signal r_reg_we : std_logic; 
    signal r_reg_data : reglen_t;
    -- stall logic
    signal w_stall_fe_de : std_logic; 
    signal w_control_hazard : std_logic; 
    --instruction fields
    signal w_opcode : std_logic_vector(5 downto 0); 
    signal w_func : std_logic_vector(5 downto 0); 
    signal w_rs : std_logic_vector(4 downto 0); 
    signal w_rd : std_logic_vector(4 downto 0); 
    signal w_rt : std_logic_vector(4 downto 0); 
    signal w_imm : std_logic_vector(15 downto 0); 
    signal w_addr : std_logic_vector(25 downto 0); 

    --internal control signals 
    signal w_imem_en : std_logic; 
    signal w_sext : std_logic; -- is sign extended 
    signal w_rt_sel : std_logic; -- write to rt 
    signal w_rs_used : std_logic; -- instruction uses the rs register
    signal w_rt_used : std_logic; -- instruction uses the rt register
    signal w_branch : std_logic; -- current instruction is branch
    --internal dataflow
    signal w_instr : reglen_t; -- imem data output
    signal w_reg_rd : std_logic_vector(4 downto 0);  
    signal w_imm_ext : reglen_t; 
    signal w_rs0_reg : reglen_t; -- rs0 readout of register 
    signal w_rs1_reg : reglen_t; -- rs1 readout of register
    --intermediate values 
    signal w_s16 : std_logic_vector(15 downto 0); -- 16 bit sign extension 

    -- static prediction miss 
    signal w_rs0_reg_intermediate : reglen_t; 
    signal w_rs1_reg_intermediate : reglen_t; 

    function and_reduce(vector : std_logic_vector) return std_logic is
        variable res : std_logic := '1';
        begin
        for i in vector'range loop
          res := res and vector(i);
        end loop;
        return res;
      end function;


          -- cache signals 
    signal w_icache_ready : std_logic;  
    signal w_icache_req : std_logic; 
    signal w_icache_adr : reglen_t; 
    signal w_mem_data : reglen_t; 
    signal w_mem_ready : std_logic; 

    signal r_last_i_was_branch : std_logic := '0'; 
    signal r_branchadr : reglen_t; 


begin 
    
    p_PIPELINE_REGISTER : process(in_clk)
    begin 
        if(rising_edge(in_clk)) then 
            r_pc4 <= in_pc4_fe; 
        end if; 
    end process; 


    BRAM : entity work.instr_mem(behavioral)
    generic map(ADDRESS_WIDTH => 9,
                DATA_WIDTH => 32)
    port map    (in_clk => in_clk, 
                 in_en_p0 => w_icache_req, 
                 in_en_p1  => '0', 
                 in_we_p0  => '0', -- no write to imem  
                 in_we_p1  => '0', 
                 in_addr_p0 => w_icache_adr(10 downto 2), 
                 in_addr_p1 => (others => '-'), 
                 in_d_p0  => (others => '-'),  
                 in_d_p1 => (others => '-'), 
                 out_d_p0 => w_mem_data, 
                 out_d_p1 => open,
                 out_load => w_mem_ready); 
    
    ICACHE : entity work.icache(RTL)
        port map(in_clk => in_clk, 
                in_rst => in_rst, 
                core_to_icache.f_adr => in_pc_fe, 
                core_to_icache.req => w_imem_en,
                icache_to_core.instr  => w_instr,
                icache_to_core.ready => w_icache_ready, 
                icache_to_mem.adr => w_icache_adr, 
                icache_to_mem.req => w_icache_req, 
                mem_to_icache.ready => w_mem_ready,
                mem_to_icache.data => w_mem_data); 

    w_opcode <= w_instr(31 downto 26); 
    w_func <= w_instr(5 downto 0); 
    w_rs <= w_instr(25 downto 21);
    w_rt <= w_instr(20 downto 16); 
    w_rd <= w_instr(15 downto 11); 
    w_imm <= w_instr(15 downto 0); 
    w_addr <= w_instr(25 downto 0); 

    w_s16 <= (others => (w_sext and w_instr(15)));

    REGFILE : entity work.regfile(RTL)
        port map(in_clk => in_clk,
                 in_rst => in_rst, 
                 in_rs0adr => w_rs,
                 in_rs1adr => w_rt,
                 in_we => in_reg_we_wb, 
                 in_rd => in_reg_rd_wb, 
                 in_data => in_reg_data_wb, 
                 out_rs0 => w_rs0_reg, 
                 out_rs1 => w_rs1_reg);

    p_STALL : process(in_reg_we_ex, in_mem2reg_sel_ex, in_reg_rd_ex, w_rs_used, w_rs, w_rt_used, w_rt, in_dcache_ready) 
    begin 
        if(in_reg_we_ex = '1' and in_mem2reg_sel_ex = '1' and (in_reg_rd_ex /= "00000") and ((w_rs_used = '1' and (in_reg_rd_ex = w_rs)) or (w_rt_used = '1' and (in_reg_rd_ex = w_rt)))) then 
            w_stall_fe_de <= '1'; -- instruction uses result of lw instruction in ex stage 
        elsif(in_dcache_ready = '0') then 
            w_stall_fe_de <= '1'; 
        else
            w_stall_fe_de <= '0'; 
        end if; 
    end process; 

    p_CONTROL_HAZARD : process(w_icache_ready, r_last_i_was_branch)
    begin 
        if(w_icache_ready = '1' and r_last_i_was_branch = '1') then 
            out_pc_sel <= c_PC_BRANCH; 
        else 
            out_pc_sel <= c_PC_PC4; 
        end if; 
    end process; 


    p_DELAY_SLOT : process(in_clk, in_branch_ex, in_equal_ex, w_icache_ready)
    begin 
        if(rising_edge(in_clk)) then 
            if(w_icache_ready = '1') then 
                if(in_branch_ex = '1' and in_equal_ex = '1') then 
                    r_last_i_was_branch <= '1'; 
                    r_branchadr <= std_logic_vector(unsigned(r_pc4) + unsigned(w_s16(13 downto 0) & w_imm & "00"));
                else 
                    r_last_i_was_branch <= '0'; 
                end if; 
            end if; 
        end if; 
    end process; 

    p_DECODE : process(w_opcode, w_func, w_stall_fe_de, w_icache_ready)
        variable v_reg_we : std_logic := '0';
        variable v_dmem_we : std_logic := '0';  
    begin 
        -- default values 
        -- implicit 1 
        out_alu_cntrl <= c_ALU_ADD; 
        -- implicit 0
        out_imm_sel <= '0'; 
        out_mem2reg_sel <= '0'; 
        out_load <= '0'; 
        w_sext <= '0'; -- for addi | lw | sw | beq 
        w_rt_sel <= '0'; -- for addi | andi | ori | xori | lw | lui 
        w_rs_used <= '0'; -- for add |sub | and | or | xor | nor | slt | addi | lw | sw | beq
        w_rt_used <= '0'; -- for add |sub | and | or | xor | slt | sw | beq
        w_branch <= '0'; 
        v_dmem_we := '0'; 
        v_reg_we := '0'; 

        case(w_opcode) is 
            when "000000" => 
                    case(w_func) is 
                        when "100100" => -- AND
                            out_alu_cntrl <= c_ALU_AND; 
                        when "100000" => -- OR
                            out_alu_cntrl <= c_ALU_OR; 
                        when "100110" => -- XOR
                            out_alu_cntrl <= c_ALU_XOR; 
                        when "100010" => -- SUB
                            out_alu_cntrl <= c_ALU_SUB;  
                        when "101010" => -- SLT
                            out_alu_cntrl <= c_ALU_SLT;  
                        when "100111" => -- NOR
                            out_alu_cntrl <= c_ALU_NOR; 
                        when others => 
                            out_alu_cntrl <= (others => '-'); 
                    end case;  
                out_alu_cntrl <= c_ALU_ADD; 
                v_reg_we := '1';
                out_mem2reg_sel <= '0';  
                w_rs_used <= '1'; 
                w_rt_used <= '1'; 
            when "001111" => -- LUI 
                out_alu_cntrl <= c_ALU_LUI; 
                v_reg_we := '1'; 
                out_imm_sel <= '1';  
                w_rt_sel <= '1'; 
            when "001000" => -- ADDI 
                out_alu_cntrl <= c_ALU_ADD; 
                v_reg_we := '1'; 
                out_imm_sel <= '1'; 
                w_sext <= '1'; 
                w_rt_sel <= '1';
                w_rs_used <= '1'; 
            when "000100" => -- BEQ
                out_alu_cntrl <= c_ALU_SUB;
                w_sext <= '1'; 
                w_rs_used <= '1'; 
                w_rt_used <= '1'; 
                w_branch <= '1'; 
            when "100011" => -- LW 
                    out_imm_sel <= '1'; 
                    out_alu_cntrl <= c_ALU_ADD; 
                    w_sext <= '1'; 
                    out_reg_we <= '1';  
                    out_mem2reg_sel <= '1';
                    w_rt_sel <= '1';  
                    w_rs_used <= '1'; 
                    out_load <= '1'; 
            when "101011" => -- SW 
                out_alu_cntrl <= c_ALU_ADD; 
                v_dmem_we := '1'; 
                out_imm_sel <= '1'; 
                w_sext <= '1'; 
                w_rs_used <= '1'; 
                w_rt_used <= '1'; 
            when others => 
        end case; 

        -- disable memory writes if stall is detected 
        -- prevents instruction from executing twice
        out_pc_load <= not w_stall_fe_de and w_icache_ready; 
        w_imem_en <= not w_stall_fe_de;
        out_reg_we <= v_reg_we and (not w_stall_fe_de) and w_icache_ready; 
        out_dmem_we <= v_dmem_we and (not w_stall_fe_de) and w_icache_ready; 
    end process; 

    -- forwarding

    p_FORWARD_RS0 : process(w_rs0_reg, in_reg_we_ex, in_reg_we_mem, in_reg_rd_ex, in_reg_rd_mem, w_rs, in_mem2reg_sel_ex, in_mem2reg_sel_mem, in_alu_res_ex, in_alu_res_mem, in_mem_res_mem)
    begin 
        w_rs0_reg_intermediate <= w_rs0_reg; -- select register read -> no hazards 
        if(in_reg_we_ex = '1' and (in_reg_rd_ex /= "00000") and (in_reg_rd_ex = w_rs) and (not in_mem2reg_sel_ex) = '1') then 
             w_rs0_reg_intermediate <= in_alu_res_ex; -- select exec stage alu result
        else 
            if(in_reg_we_mem = '1' and (in_reg_rd_mem /= "00000") and (in_reg_rd_mem = w_rs) and (not in_mem2reg_sel_mem) = '1') then 
                w_rs0_reg_intermediate <= in_alu_res_mem; -- select mem stage alu result
            elsif(in_reg_we_mem = '1' and (in_reg_rd_mem /= "00000") and (in_reg_rd_mem = w_rs) and in_mem2reg_sel_mem = '1') then 
                w_rs0_reg_intermediate <= in_mem_res_mem; -- select mem stage lw result
            end if; 
        end if; 
    end process; 
    out_rs0 <= w_rs0_reg_intermediate;
    
    p_FORWARD_RS1 : process(w_rs1_reg, in_reg_we_ex, in_reg_we_mem, in_reg_rd_ex, in_reg_rd_mem, w_rt, in_mem2reg_sel_ex, in_mem2reg_sel_mem, in_alu_res_ex, in_alu_res_mem, in_mem_res_mem)
    begin 
        w_rs1_reg_intermediate <= w_rs1_reg; -- select register read -> no hazards 
        if(in_reg_we_ex = '1' and (in_reg_rd_ex /= "00000") and (in_reg_rd_ex = w_rt) and (not in_mem2reg_sel_ex) = '1') then 
            w_rs1_reg_intermediate <= in_alu_res_ex; -- select exec stage alu result
        else 
            if(in_reg_we_mem = '1' and (in_reg_rd_mem /= "00000") and (in_reg_rd_mem = w_rt) and (not in_mem2reg_sel_mem) = '1') then 
                w_rs1_reg_intermediate <= in_alu_res_mem; -- select mem stage alu result
            elsif(in_reg_we_mem = '1'and (in_reg_rd_mem /= "00000") and (in_reg_rd_mem = w_rt) and in_mem2reg_sel_mem = '1') then 
                w_rs1_reg_intermediate <= in_mem_res_mem; -- select mem stage lw result
            end if; 
        end if; 
    end process; 
    out_rs1 <= w_rs1_reg_intermediate; 


    out_reg_rd <= w_rt when w_rt_sel = '1' else 
                  w_rd; 

    w_imm_ext <= w_s16 & w_imm;
    out_imm <= w_imm_ext;

    out_branch <= w_branch; 
     
    -- out_jmpadr <= r_pc4(31 downto 28) & w_addr & "00"; 
    out_branchadr <= r_branchadr;

end architecture RTL; 