library ieee;
use ieee.std_logic_1164.all;

entity astrogate_top is
  generic (
    VGA_OUTPUT_DEPTH_G : integer := 4;
    FRAME_BUFFER_BIT_DEPTH_G : integer := 16
  );
  port (
         -- Global Clock
         clk  : in std_logic;
         -- Global Reset
         -- Inverted thanks to active low
         rst_n  : in std_logic;
         -- VGA signals
         vga_red   : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
         vga_green : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
         vga_blue  : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
         vga_hsync : out std_logic;
         vga_vsync : out std_logic;
         -- Camera Control
         scl : inout std_logic;
         sda : inout std_logic;
         ov7670_vsync : in std_logic;
         ov7670_href : in std_logic;
         ov7670_pclk : in std_logic;
         ov7670_xclk : out std_logic;
         ov7670_data : in std_logic_vector(7 downto 0);
         sw : in std_logic_vector(3 downto 0);
         ov7670_pwdn : out std_logic;
         ov7670_reset : out std_logic
       );
end astrogate_top;

architecture rtl of astrogate_top is
  signal rst : std_logic := '0';
  signal uart_byte_tx : std_logic_vector(7 downto 0) := (others => '0');
  signal edge : std_logic_vector(3 downto 0) := (others => '0');

  signal config_finished : std_logic := '0';

  signal buf1_vsync, buf2_vsync, buf1_href, buf2_href : std_logic := '0';
  signal buf1_pclk, buf2_pclk : std_logic := '0';
  signal buf1_data, buf2_data : std_logic_vector(7 downto 0) := (others => '0');

  signal vga_clk : std_logic := '0';
  signal xclk_ov7670 : std_logic := '0';

  signal pixel_data : std_logic_vector(15 downto 0) := (others => '0');
  signal pixel_data_byte : std_logic_vector(7 downto 0) := (others => '0');
  signal wea : std_logic_vector(0 downto 0) := (others => '0');
  signal addra : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0) := (others => '0');
  signal dina : std_logic_vector(11 downto 0) := (others => '0');
  signal addrb : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0) := (others => '0');
  signal doutb : std_logic_vector(11 downto 0) := (others => '0');

  signal frame_finished : std_logic := '0';
begin


  process (clk)
    begin
      if rising_edge(clk) then
          buf1_vsync <= ov7670_vsync;
          buf2_vsync <= buf1_vsync;

          buf1_href <= ov7670_href;
          buf2_href <= buf1_href;

          buf1_pclk <= ov7670_pclk;
          buf2_pclk <= buf1_pclk;

          buf1_data <= ov7670_data;
          buf2_data <= buf1_data;
      end if;
  end process;

  ov7670_pwdn <= '0'; -- Power device up
  rst <= not rst_n; -- Active low reset for Cyclone IV board

  ov7670_xclk <= xclk_ov7670;

  pixel_data_byte <= pixel_data(15 DOWNTO 8) WHEN sw(0) = '0' ELSE
      pixel_data(7 DOWNTO 0);

  -- Generates the xclk nessecary for the OV7670's xclk pin
  ov7670_pll_inst : work.ov7670_pll port map (
		inclk0	 => clk,
		c0	 => xclk_ov7670,
		locked	 => open
	);

  -- Generates a PLL nessecary for VGA output @ 25MHz.
  vga_pll : work.vga_pll port map (
    inclk0 => clk,
    c0 => vga_clk,
    locked => open,
    areset => '0' -- Don't ever reset PLL
  );

  framebuffer_inst : work.framebuffer PORT MAP (
    -- Write clock domain (FPGA @ 50MHz)
		wraddress	 => addra,
		wrclock	 => clk,
		wren	 => '1',
		data	 => dina,
    -- Read clock domain (VGA @ 25MHz)
		rdaddress	 => addrb,
		rdclock	 => vga_clk,
		q	 => doutb
	);
  -- Instantiate VGA output
  e_vga_output : entity work.VGA
    generic map (
      VGA_OUTPUT_DEPTH_G => VGA_OUTPUT_DEPTH_G
    ) 
    port map (
      i_clk25 => vga_clk,
      o_red => vga_red,
      o_green => vga_green,
      o_blue => vga_blue,
      o_hs => vga_hsync,
      o_vs => vga_vsync
   );

   ov7670_configuration : entity work.ov7670_configuration(behavioral)
    port map(
        clk => clk,
        rst => rst,
        sda => sda,
        edge => edge,
        scl => scl,
        ov7670_reset => ov7670_reset,
        start => edge(0),
        ack_err => open,
        done => open,
        config_finished => config_finished,
        reg_value => uart_byte_tx
    );


   ov7670_capture : entity work.ov7670_capture(rtl) 
    generic map(
      FRAME_BUFFER_BIT_DEPTH_G =>  16
    )
    port map(
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
