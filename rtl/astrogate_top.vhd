library ieee;
use ieee.std_logic_1164.all;

entity astrogate_top is
  port (
         -- Global Clock
         clk  : in std_logic;
         -- Global Reset
         rst  : in std_logic;
         -- Camera SCCB
         sccb_clk_out : out std_logic
       );
end astrogate_top;

architecture rtl of astrogate_top is
begin
  g_hdmi_out : entity work.hdmi_out
   generic map (
    RESOLUTION <= "VGA",
    GEN_PATTERN <= true
   )
   port map (
     clk <= clk,
     rst <= rst
   );

  e_camera_sccb : entity work.camera_sccb
    port map (
      clk_in => clk,
      sccb_clk_out => sccb_clk_out
     );
end rtl;
