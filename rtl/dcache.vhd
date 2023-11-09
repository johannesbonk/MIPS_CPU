LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

USE work.dcache_pkg.ALL; 

entity dcache is
    port(in_clk, in_rst : in std_logic; -- clock and reset
         core_to_dcache : in core_to_dcache_t; 
         dcache_to_core : out dcache_to_core_t; 
         mem_to_dcache  : in mem_to_dcache_t; 
         dcache_to_mem  : out dcache_to_mem_t); 
end dcache;

--byte 0 - 1 
-- word 2-3
-- set 4 - 7 
-- tag 8 - 31 

architecture RTL of dcache is
    -- cache constants
    constant cache_line_size : natural := 128; -- fixed cache line size in bits

    -- array declarations
    type valid_t is array (0 to 15) of std_logic; 
    type dirty_t is array (0 to 15) of std_logic; 
    type tag_t is array (0 to 15) of std_logic_vector(23 downto 0); 

    -- state machine 
    signal r_cache_state : dcache_state_t; 
    signal w_new_cache_state : dcache_state_t; 

    signal tag : std_logic_vector(23 downto 0); 
    signal set : std_logic_vector(3 downto 0); 
    signal word : std_logic_vector(1 downto 0); 

    -- cache memory output signals and write enable 

    signal r_valid : valid_t := (others => '0'); 
    signal r_dirty : dirty_t := (others => '0'); 


    signal w_write_tag : std_logic; 
    signal w_tag_read : std_logic_vector(23 downto 0); 

    type write_data_t is array (0 to 3) of std_logic;  
    signal w_write_data : write_data_t;   
    signal w_data_to_write : std_logic_vector(31 downto 0); 
    type data_t is array (0 to 3) of std_logic_vector(31 downto 0);  
    signal w_data_read : data_t; 

    
    constant words_read_nbits  : natural := 2;
    signal r_sequencer : integer range 0 to 3 := 0; 
    signal w_sequencer_inc : std_logic;
    
    signal w_wb_adr : std_logic_vector(31 downto 0); 
begin 
    -- split read address
    -- VHDL 2008
    -- (tag, set, word) <= core_to_dcache.adr(31 downto 2);
    word <= core_to_dcache.adr(3 downto 2); 
    set <= core_to_dcache.adr(7 downto 4); 
    tag <= core_to_dcache.adr(31 downto 8);

    TAG_MEM: entity work.sp_ram 
    generic map(ADDRESS_WIDTH => 4, 
                CELL_WIDTH => 24) 
    port map(in_clk => in_clk,
             in_we => w_write_tag,
             in_raddr => set, 
             in_waddr => set,
             in_d => tag,
             out_d => w_tag_read); 

    DATA_MEM_GEN: for I in 0 to 3 generate
        DATA: entity work.sp_ram
        generic map(ADDRESS_WIDTH => 4, 
                    CELL_WIDTH => 32)
        port map(in_clk => in_clk,
                 in_we => w_write_data(I),
                 in_raddr => set, 
                 in_waddr => set,
                 in_d => w_data_to_write,
                 out_d => w_data_read(I)); 
    end generate DATA_MEM_GEN;
        
    w_data_to_write <= core_to_dcache.data when r_cache_state = WRITE else 
                       mem_to_dcache.data; 

    CACHE_UPDATE : process(in_clk) is
    begin 
        if(rising_edge(in_clk)) then 
            r_cache_state <= w_new_cache_state; 

            -- update valid and dirty bit 
            if(r_cache_state = MEM_READ) then 
                r_valid(to_integer(unsigned(set))) <= '1'; 
                r_dirty(to_integer(unsigned(set))) <= '0'; 
            elsif(r_cache_state = WRITE) then 
                r_dirty(to_integer(unsigned(set))) <= '1'; 
            elsif(r_cache_state = MEM_WB) then 
                r_valid(to_integer(unsigned(set))) <= '0'; 
                r_dirty(to_integer(unsigned(set))) <= '0'; 
            end if; 

            -- update sequencer 
            if(w_sequencer_inc = '1') then 
                r_sequencer <= r_sequencer + 1; 
            end if; 

            if(r_cache_state = IDLE or r_cache_state = READ or r_cache_state = WRITE) then 
                r_sequencer <= 0; 
            end if; 

        end if; 
    end process; 

    CACHE_STATE : process(r_cache_state, mem_to_dcache, core_to_dcache, w_tag_read, set, tag, word, r_sequencer) is
    begin 
        -- default values 
        w_new_cache_state <= IDLE; 
        dcache_to_core.ready <= '0'; 
        dcache_to_mem.req <= '0'; 
        dcache_to_mem.write <= '0'; 
        w_write_tag <= '0'; 
        for i in w_write_data'range loop
            w_write_data(i) <= '0'; 
        end loop; 
        w_sequencer_inc <= '0'; 

        case r_cache_state is 
            when IDLE => 
                if(core_to_dcache.req = '1') then 
                    if(core_to_dcache.write = '1') then 
                        w_new_cache_state <= WRITE; 
                    else 
                        w_new_cache_state <= READ; 
                    end if; 
                else 
                    w_new_cache_state <= IDLE; 
                end if; 
            when READ => 
                if(r_valid(to_integer(unsigned(set))) = '1' and w_tag_read = tag) then 
                    dcache_to_core.ready <= '1'; 
                    w_new_cache_state <= IDLE; 
                elsif(r_dirty(to_integer(unsigned(set))) = '1') then 
                    w_new_cache_state <= MEM_WB; 
                else 
                    w_write_tag <= '1'; 
                    w_new_cache_state <= MEM_READ; 
                end if; 
            when WRITE => 
                if(r_valid(to_integer(unsigned(set))) = '1' and w_tag_read = tag) then 
                    dcache_to_core.ready <= '1';
                    w_write_data(to_integer(unsigned(word))) <= '1'; 
                    w_new_cache_state <= IDLE; 
                elsif(r_dirty(to_integer(unsigned(set))) = '1') then 
                    w_new_cache_state <= MEM_WB; 
                else 
                    w_write_tag <= '1'; 
                    w_new_cache_state <= MEM_READ; 
                end if; 
            when MEM_WB => 
                if(mem_to_dcache.ready = '0') then 
                    dcache_to_mem.req <= '1'; 
                    dcache_to_mem.write <= '1'; 
                    w_new_cache_state <= MEM_WB;
                else
                    if(r_sequencer /= 3) then
                        w_sequencer_inc <= '1';
                        w_new_cache_state <= MEM_WB;
                    else 
                        if(core_to_dcache.write = '1') then 
                            w_new_cache_state <= WRITE; 
                        else 
                            w_new_cache_state <= READ; 
                        end if; 
                    end if; 
                end if; 
            when MEM_READ => 
                dcache_to_mem.req <= '1'; 
                if(mem_to_dcache.ready = '0') then 
                    w_new_cache_state <= MEM_READ;
                else
                    w_write_data(r_sequencer) <= '1'; 
                    w_new_cache_state <= MEM_READ_INC; 
                end if; 
            when MEM_READ_INC => 
                    if(r_sequencer < 3) then
                        w_sequencer_inc <= '1';
                        w_new_cache_state <= MEM_READ;
                    else 
                        if(core_to_dcache.write = '1') then 
                            w_new_cache_state <= WRITE; 
                        else 
                            w_new_cache_state <= READ; 
                        end if; 
                    end if; 
            when others =>
                w_new_cache_state <= IDLE; 
            end case; 
    end process; 

    -- data to cpu 
    dcache_to_core.data <= w_data_read(to_integer(unsigned(word))); 
    -- data to memory 
    dcache_to_mem.data <= w_data_read(r_sequencer); 
    -- pass through of adr to mem 
    w_wb_adr <= w_tag_read & set & "0000";
    dcache_to_mem.adr <=  std_logic_vector(unsigned(w_wb_adr) + to_unsigned(r_sequencer, words_read_nbits)) when r_cache_state = MEM_WB else 
                          std_logic_vector(unsigned(core_to_dcache.adr) + to_unsigned(r_sequencer, words_read_nbits));
                         

end architecture RTL; 