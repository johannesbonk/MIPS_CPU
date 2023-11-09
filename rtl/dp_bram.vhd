LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity dp_bram is
  generic(ADDRESS_WIDTH : integer := 5; -- equals rows
          DATA_WIDTH : integer := 512); --equals columns
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
        out_d_p1    : out std_logic_vector(DATA_WIDTH - 1 downto 0)); -- data out port 1 
end dp_bram;

architecture behavioral of dp_bram is
  type bram_t is array (0 to (2**ADDRESS_WIDTH) - 1) of std_logic_vector (DATA_WIDTH - 1 downto 0);
  shared variable v_bram : bram_t := (others => '0');

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

end behavioral;
