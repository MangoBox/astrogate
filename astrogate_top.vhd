library ieee;
use ieee.std_logic_1164.all;

entity astrogate_top is
  generic (
    VGA_OUTPUT_DEPTH_G : integer := 4
  );
  port (
         -- Global Clock
         clk  : in std_logic;
         -- Global Reset
         rst  : in std_logic;
         -- VGA signals
         vga_red   : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
         vga_green : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
         vga_blue  : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
         vga_hsync : out std_logic;
         vga_vsync : out std_logic;
         -- Camera Control
         uart_txd_in : in std_logic;
         scl : inout std_logic;
         sda : inout std_logic;
         ov7670_vsync : in std_logic;
         ov7670_href : in std_logic;
         ov7670_pclk : in std_logic;
         ov7670_xclk : out std_logic;
         ov7670_data : in std_logic_vector(7 downto 0);
         uart_rxd_out : out std_logic;
         btn : in std_logic_vector(3 downto 0);
         sw : in std_logic_vector(3 downto 0);
         ov7670_pwdn : out std_logic;
         ov7670_reset : out std_logic
       );
end astrogate_top;

architecture rtl of astrogate_top is
begin
  -- Instantiate VGA output
  e_vga_output : entity work.VGA
    generic map (
      VGA_OUTPUT_DEPTH_G => VGA_OUTPUT_DEPTH_G
    ) 
    port map (
      i_clk50 => clk,
      o_red => vga_red,
      o_green => vga_green,
      o_blue => vga_blue,
      o_hs => vga_hsync,
      o_vs => vga_vsync
   );

   ov7670_configuration : ENTITY work.ov7670_configuration(Behavioral)
    PORT MAP(
        clk => clk,
        rst => rst,
        sda => sda,
        edge => edge,
        scl => scl,
        ov7670_reset => ov7670_reset,
        start => edge(0),
        ack_err => OPEN,
        done => uart_start,
        config_finished => config_finished,
        reg_value => uart_byte_tx
    );


   ov7670_capture : ENTITY work.ov7670_capture(rtl) PORT MAP(
    clk => clk,
    rst => rst,
    config_finished => config_finished,
    ov7670_vsync => buf2_vsync,
    ov7670_href => buf2_href,
    ov7670_pclk => buf2_pclk,
    ov7670_data => buf2_data,
    frame_finished_o => frame_finished,
    pixel_data => pixel_data,
    start => edge(3),

    --frame_buffer signals
    wea => wea,
    dina => dina,
    addra => addra
    );

end rtl;
