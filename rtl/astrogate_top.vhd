library ieee;
use ieee.std_logic_1164.all;

entity astrogate_top is
  generic (
    FRAME_BUFFER_BIT_DEPTH_G : integer := 16;
    VGA_OUTPUT_DEPTH_G : integer := 3
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
         --sw : in std_logic_vector(3 downto 0);
         ov7670_pwdn : out std_logic;
         ov7670_reset : out std_logic;
         btn_n : in std_logic_vector(3 downto 0);
         leds_n : out std_logic_vector(3 downto 0)
       );
end astrogate_top;

architecture rtl of astrogate_top is
  constant VGA_TOTAL_DEPTH_C : integer := VGA_OUTPUT_DEPTH_G * 3;

  signal rst : std_logic := '0';
  signal uart_byte_tx : std_logic_vector(7 downto 0) := (others => '0');

  signal config_finished : std_logic := '0';

  -- signal buf1_vsync, buf2_vsync, buf1_href, buf2_href : std_logic := '0';
  -- signal buf1_pclk, buf2_pclk : std_logic := '0';
  -- signal buf1_data, buf2_data : std_logic_vector(7 downto 0) := (others => '0');
  signal xclk_vsync, xclk_href : std_logic := '0';
  signal xclk_data : std_logic_vector(7 downto 0);

  signal vga_clk : std_logic := '0';
  signal xclk_ov7670 : std_logic := '0';

  signal pixel_data : std_logic_vector(15 downto 0) := (others => '0');
  -- signal pixel_data_byte : std_logic_vector(7 downto 0) := (others => '0');
  signal wea : std_logic_vector(0 downto 0) := (others => '0');
  signal addra : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0) := (others => '0');
  signal dina : std_logic_vector(VGA_TOTAL_DEPTH_C - 1 downto 0) := (others => '1');
  signal addrb : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0) := (others => '0');
  signal doutb : std_logic_vector(VGA_TOTAL_DEPTH_C - 1 downto 0) := (others => '0');

  signal edge : std_logic_vector(3 downto 0) := (others => '0');
  signal btn : std_logic_vector(3 downto 0) := (others => '0');
  signal leds : std_logic_vector(3 downto 0) := (others => '0');

  signal frame_finished : std_logic := '0';

  -- FIFO split in/out signals
  signal ov7670_fifo_in : std_logic_vector(9 downto 0);
  signal ov7670_fifo_reg : std_logic_vector(9 downto 0);
  signal ov7670_fifo_out : std_logic_vector(9 downto 0);
begin
  
  leds_n <= not leds;
  btn <= not btn_n;
  leds <= pixel_data(3 downto 0);

  -- Fanning into the FIFO input port
  ov7670_fifo_in(7 downto 0) <= ov7670_data(7 downto 0);
  ov7670_fifo_in(8) <= ov7670_href;
  ov7670_fifo_in(9) <= ov7670_vsync;

  -- Fanning out from the FIFO output port
  xclk_data <= ov7670_fifo_out(7 downto 0); 
  xclk_href <= ov7670_fifo_out(8); 
  xclk_vsync <= ov7670_fifo_out(9);

  ov7670_fifo_inst : work.ov7670_fifo PORT MAP (
    --- Ingress Domain
		wrclk	 => ov7670_pclk,
		wrreq	 => '1',
		data	 => ov7670_fifo_in,
		wrfull	 => open, -- Don't care about FIFO state
    --- Egress Domain
		rdclk	 => xclk_ov7670,
		rdreq	 => '1',
		q	 => ov7670_fifo_reg,
		rdempty	=> open -- Don't care about FIFO state
	);

  -- Reg for output after FIFO
  process(xclk_ov7670)
  begin
    if rising_edge(xclk_ov7670) then
      ov7670_fifo_out <= ov7670_fifo_reg;
    end if;
  end process;


  ov7670_pwdn <= '0'; -- Power device up
  rst <= not rst_n; -- Active low reset for Cyclone IV board

  ov7670_xclk <= xclk_ov7670;

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

  edge_detect : entity work.debounce(behavioral) port map(
    clk => clk,
    btn => btn,
    edge => edge
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
      VGA_OUTPUT_DEPTH_G => VGA_OUTPUT_DEPTH_G,
      FRAME_BUFFER_BIT_DEPTH_G => FRAME_BUFFER_BIT_DEPTH_G
    ) 
    port map (
      i_clk25 => vga_clk,
      o_red => vga_red,
      o_green => vga_green,
      o_blue => vga_blue,
      o_hs => vga_hsync,
      o_vs => vga_vsync,
      i_doutb => doutb,
      o_addrb => addrb
   );

   ov7670_configuration : entity work.ov7670_configuration(behavioral)
    port map(
        clk => clk,
        rst => rst,
        sda => sda,
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
      FRAME_BUFFER_BIT_DEPTH_G =>  16,
      VGA_OUTPUT_DEPTH_G => 9
    )
    port map(
      clk => clk,
      rst => rst,
      config_finished => '1',
      -- Note: We are using our internally-generated XCLK
      ov7670_vsync => xclk_vsync,
      ov7670_href => xclk_href,
      ov7670_pclk => xclk_ov7670,
      ov7670_data => xclk_data,
      frame_finished_o => frame_finished,
      pixel_data => pixel_data,
      start => '1',

      --frame_buffer signals
      wea => wea,
      dina => dina,
      addra => addra
    );

end rtl;
