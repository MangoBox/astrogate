library ieee;
use ieee.std_logic_1164.all;

entity astrogate_top is
  port (
         -- Global Clock
         clk  : in std_logic;
         -- Global Reset
         rst  : in std_logic;

         -- HDMI Signals
         hdmi_clk_p : out std_logic;
         -- TMDS Signals
         hdmi_data_p : out std_logic_vector(2 downto 0)
       );
end astrogate_top;

architecture rtl of astrogate_top is
begin
  g_hdmi_out : entity work.hdmi_out
   generic map (
     RESOLUTION => "VGA",
     GEN_PATTERN => true
   )
   port map (
     clk => clk,
     rst => rst,
     -- HDMI Diff Signals
     clk_p => hdmi_clk_p,
     data_p => hdmi_data_p
   );
end rtl;
