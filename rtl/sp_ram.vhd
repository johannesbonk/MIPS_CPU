LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

entity sp_ram is
   generic(ADDRESS_WIDTH : integer := 5; 
           CELL_WIDTH : integer := 64); 
   port( in_clk : in std_logic;
         in_we : in std_logic; 
         in_waddr : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
         in_raddr : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
         in_d : in std_logic_vector (CELL_WIDTH - 1 downto 0);
         out_d : out  std_logic_vector (CELL_WIDTH - 1 downto 0));
end sp_ram;

architecture RTL of sp_ram is
   type mem is array(0 to 2**ADDRESS_WIDTH - 1) of std_logic_vector(CELL_WIDTH -1 downto 0);
   signal ram_block : mem;
begin
   process (in_clk)
   begin
      if(rising_edge(in_clk)) then
         if(in_we = '1') then
            ram_block(to_integer(unsigned(in_waddr))) <= in_d;
         end if;
         out_d <= ram_block(to_integer(unsigned(in_waddr)));
      end if;
   end process;
end RTL;