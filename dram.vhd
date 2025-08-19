library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dram is
  generic(
    DATA_WIDTH : natural := 4;
    ADDR_WIDTH : natural := 12;
    BANKS_WIDTH : natural := 2
     );
  port(
      -- Chip connections
      i_clk:    in std_logic;
      o_clk:    out std_logic;
      o_cs:     out std_logic;
      o_cke:    out std_logic;
      o_we:     out std_logic;
      o_cas:    out std_logic;
      o_ras:    out std_logic;
      o_ba:     out std_logic_vector(BANKS_WIDTH - 1 downto 0);
      o_addr:   out std_logic_vector(ADDR_WIDTH - 1 downto 0);
      io_data:  inout std_logic_vector(DATA_WIDTH - 1 downto 0);
      o_dqm:    out std_logic
     );
end dram;

architecture rtl of dram is
begin

  -- Always chip select low enable
  o_cs <= '1';

  -- Bind output clock
  o_clk <= i_clk;

  


end rtl;
