-- author: Furkan Cayci, 2018
-- description: generate 1x pixel and 5x serial clocks from the input clock
--   default to 125 Mhz input clock
--               25 and 125 Mhz output clocks

library ieee;
use ieee.std_logic_1164.all;

entity clock_gen is
    port(
        clk_i  : in  std_logic; --  input clock
        clk0_o : out std_logic; -- serial clock
        clk1_o : out std_logic;  --  pixel clock
        -- Rst
        a_rst : in std_logic
    );
end clock_gen;

architecture rtl of clock_gen is
    signal clkfbout : std_logic;

begin
  -- Should add in generic PLL parameters for resolution?
  hdmi_pll_inst : work.hdmi_pll PORT MAP (
      areset	 => a_rst,
      inclk0	 => clk_i,
      c0	 => clk0_o,
      c1	 => clk1_o
      -- locked signal?
      -- locked 
    );
end rtl;
