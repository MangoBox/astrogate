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
         vga_vsync : out std_logic;
         -- Camera SCCB
         sccb_clk_out : out std_logic
       );
end astrogate_top;

architecture rtl of astrogate_top is
begin
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

  e_camera_sccb : entity work.camera_sccb
    port map (
      clk_in => clk,
      sccb_clk_out => sccb_clk_out
     );
end rtl;
