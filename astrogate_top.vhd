library ieee;
use ieee.std_logic_1164.all;

entity astrogate_top is
  port (
         -- Global Clock
         clk  : in std_logic;
         -- Global Reset
         rst  : in std_logic;
         -- VGA signals
         vga_red   : out std_logic;
         vga_green : out std_logic;
         vga_blue  : out std_logic;
         vga_hsync : out std_logic;
         vga_vsync : out std_logic
       );
end astrogate_top;

architecture rtl of astrogate_top is
begin
  -- p_clock_proc: process(clk)
  -- begin
  --   if rising_edge(clk) then
  --     if rst = '1' then
  --       -- Global Reset 
  --       red <= clk;
  --     else
  --       
  --     end if;
  --   end if;
  -- end process p_clock_proc;


-- Instantiate VGA output
  e_vga_output : entity work.VGA
    port map (
      i_clk50 => clk,
      o_red => vga_red,
      o_green => vga_green,
      o_blue => vga_blue,
      o_hs => vga_hsync,
      o_vs => vga_vsync
   );
end rtl;
