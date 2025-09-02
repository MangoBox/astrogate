library ieee;
use ieee.std_logic_1164.all;

entity camera_sccb is
  port (
      -- Global Clock
      clk_in  : in std_logic;
      -- Camera clock outputs
      sccb_clk_out : out std_logic;
      sccb_data    : inout std_logic
       );
end camera_sccb;

architecture rtl of camera_sccb is
  signal b_clk_out : std_logic;
begin
  sccb_clk_out <= b_clk_out;
  -- generate a 25Mhz clock
  process (clk_in)
  begin
    if rising_edge(clk_in) then
      if (b_clk_out = '0') then              
        b_clk_out <= '1';
      else
        b_clk_out <= '0';
      end if;
    end if;
  end process;
end rtl;
