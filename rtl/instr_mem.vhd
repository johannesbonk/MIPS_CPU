-- 
--
--
-- INFO : 
--
-- hat selbe entity wie dual port block ram

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity instr_mem is
  generic(ADDRESS_WIDTH : integer := 28; 
          DATA_WIDTH : integer := 32);
  --
  port (in_clk      : in std_logic; -- clock input
        in_en_p0    : in std_logic; -- enable port 0 
        in_en_p1    : in std_logic; -- enable port 1 
        in_we_p0    : in std_logic; -- write enable port 0
        in_we_p1    : in std_logic; -- write enable port 1 
        in_addr_p0  : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0); -- address port 0 
        in_addr_p1  : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0); -- address port 1 
        in_d_p0     : in std_logic_vector(DATA_WIDTH - 1 downto 0);   -- data in port 0 
        in_d_p1     : in std_logic_vector(DATA_WIDTH - 1 downto 0); -- data in port 1 
        out_d_p0    : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- data out port 0
        out_d_p1    : out std_logic_vector(DATA_WIDTH - 1 downto 0); 
        out_load    : out std_logic); -- data out port 1 
end instr_mem;

architecture behavioral of instr_mem is
  type bram_t is array (0 to (2**ADDRESS_WIDTH) - 1) of std_logic_vector (DATA_WIDTH - 1 downto 0);
  shared variable v_bram : bram_t := (x"20080008", -- addi $t0, $0, 8 
                                      x"20090001", -- addi $t1, $0, 1
                                      x"0000502a", -- slt $t2, $0, $0
                                      x"0000582a", -- slt $t3, $0, $0
                                      x"0000602a", -- slt $t4, $0, $0
                                      -- fib:
                                      x"218c0001", -- addi $t4, $t4, 1
                                      x"11880005", -- beq $t4, $t0, wait_forever
                                      x"000a5820", -- add $t3, $0, $t2
                                      x"00095020", -- add $t2, $0, $t1
                                      x"014b4820", -- add $t1, $t2, $t3
                                      x"1000fffa", -- beq $0, $0, fib
                                      x"ac092000", -- sw $t1, 0x2000
                                      x"ac090000", -- sw $t1, 0x0 -> test sw
                                      -- wait_forever
                                      x"8c0c0000", -- lw $t4, 0x0 -> test lw
                                      x"1000ffff", -- beq $0, $0, wait_forever
                                      others => (others=>'0'));

  signal r_rdata_p0 : std_logic_vector(DATA_WIDTH - 1 downto 0); 
  signal r_rdata_p1 : std_logic_vector(DATA_WIDTH - 1 downto 0);   

  signal r_load : std_logic := '0'; 
begin
  LOAD: process (in_clk)
    variable v_rdata : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0'); 
  begin
    if (rising_edge(in_clk)) then
      r_load <= in_en_p0; 
    end if; 
  end process;

  PORT_0: process (in_clk)
    variable v_rdata : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0'); 
  begin
    if (rising_edge(in_clk)) then
      if (in_en_p0 = '1') then
        v_rdata := v_bram(to_integer(unsigned(in_addr_p0))); 
        if(in_we_p0 = '1') then 
          v_bram(to_integer(unsigned(in_addr_p0))) := in_d_p0; 
        end if; 
      end if;
    end if;
    r_rdata_p0 <= v_rdata; 
  end process;

  PORT_1: process (in_clk)
    variable v_rdata : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    if (rising_edge(in_clk)) then
      if (in_en_p1 = '1') then
        v_rdata := v_bram(to_integer(unsigned(in_addr_p1))); 
        if(in_we_p1 = '1') then 
          v_bram(to_integer(unsigned(in_addr_p1))) := in_d_p1; 
        end if; 
      end if;
    end if;
    r_rdata_p1 <= v_rdata; 
  end process;

  out_d_p0 <= r_rdata_p0; 
  out_d_p1 <= r_rdata_p1; 
  out_load <= r_load; 

end behavioral;


architecture test of instr_mem is
  type bram_t is array (0 to (2**ADDRESS_WIDTH) - 1) of std_logic_vector (DATA_WIDTH - 1 downto 0);
  shared variable v_bram : bram_t := (x"20080008", -- addi $t0, $0, 8 
                                      x"20090001", -- addi $t1, $0, 1
                                      x"0000502a", -- slt $t2, $0, $0
                                      x"0000582a", -- slt $t3, $0, $0
                                      x"0000602a", -- slt $t4, $0, $0
                                      x"3c010098", -- lui $t5, $0 
                                      -- fib:
                                      x"ac0d2004", -- sw $t5, 0x2004
                                      x"21adffff", -- addi $t5, $t5, -1
                                      x"01a0702a", -- slt $t6, $t5, $0
                                      x"11c0fffd", -- beq $t6, $0, fib
                                      x"00000020", -- add $0, $0, $0 
                                      x"8c0d2004", -- lw $t5, 0x2004

                                      x"218c0001", -- addi $t4, $t4, 1
                                      x"11880005", -- beq $t4, $t0, wait_forever
                                      x"000a5820", -- add $t3, $0, $t2
                                      x"00095020", -- add $t2, $0, $t1
                                      x"014b4820", -- add $t1, $t2, $t3
                                      x"1000fff5", -- beq $0, $0, fib
                                      x"ac092000", -- sw $t1, 0x2000
                                      -- wait_forever
                                      x"1000ffff", -- beq $0, $0, wait_forever
                                      others => (others=>'0'));

  signal r_rdata_p0 : std_logic_vector(DATA_WIDTH - 1 downto 0); 
  signal r_rdata_p1 : std_logic_vector(DATA_WIDTH - 1 downto 0);   
begin

  PORT_0: process (in_clk)
    variable v_rdata : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0'); 
  begin
    if (rising_edge(in_clk)) then
      if (in_en_p0 = '1') then
        v_rdata := v_bram(to_integer(unsigned(in_addr_p0))); 
        if(in_we_p0 = '1') then 
          v_bram(to_integer(unsigned(in_addr_p0))) := in_d_p0; 
        end if; 
      end if;
    end if;
    r_rdata_p0 <= v_rdata; 
  end process;

  PORT_1: process (in_clk)
    variable v_rdata : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    if (rising_edge(in_clk)) then
      if (in_en_p1 = '1') then
        v_rdata := v_bram(to_integer(unsigned(in_addr_p1))); 
        if(in_we_p1 = '1') then 
          v_bram(to_integer(unsigned(in_addr_p1))) := in_d_p1; 
        end if; 
      end if;
    end if;
    r_rdata_p1 <= v_rdata; 
  end process;

  out_d_p0 <= r_rdata_p0; 
  out_d_p1 <= r_rdata_p1; 

end test;