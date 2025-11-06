library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_VGA is
end entity;

architecture sim of tb_VGA is
  -- Constants
  constant CLK_PERIOD : time := 40 ns;  -- 25 MHz clock

  -- DUT generics (use defaults or override here)
  constant VGA_OUTPUT_DEPTH_G      : integer := 3;
  constant VGA_TOTAL_DEPTH_C       : integer := 9;
  constant FRAME_BUFFER_BIT_DEPTH_G: integer := 16;

  -- DUT I/O
  signal i_clk25 : std_logic := '0';
  signal o_red   : std_logic_vector(VGA_OUTPUT_DEPTH_G-1 downto 0);
  signal o_green : std_logic_vector(VGA_OUTPUT_DEPTH_G-1 downto 0);
  signal o_blue  : std_logic_vector(VGA_OUTPUT_DEPTH_G-1 downto 0);
  signal o_hs, o_vs : std_logic;
  signal o_addrb : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G-1 downto 0);
  signal i_doutb : std_logic_vector(VGA_TOTAL_DEPTH_C-1 downto 0);

  -- Simulation control
  signal done : boolean := false;

begin

  -------------------------------------------------------------------------
  -- Clock generator
  -------------------------------------------------------------------------
  clk_gen : process
  begin
    while not done loop
      i_clk25 <= '0';
      wait for CLK_PERIOD/2;
      i_clk25 <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- Drive simple color pattern on i_doutb
  -------------------------------------------------------------------------
  stim_proc : process
  begin
    -- Initialize
    i_doutb <= (others => '0');
    wait for 100 ns;

    -- Provide a simple pattern: red, green, blue cycling
    while now < 100 ms loop
      i_doutb <= "111000000"; wait for CLK_PERIOD*10;  -- red
      i_doutb <= "000111000"; wait for CLK_PERIOD*10;  -- green
      i_doutb <= "000000111"; wait for CLK_PERIOD*10;  -- blue
    end loop;

    done <= true;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- Instantiate the Device Under Test (DUT)
  -------------------------------------------------------------------------
  DUT : entity work.VGA
    generic map (
      sync_polarity           => '1',
      VGA_OUTPUT_DEPTH_G      => VGA_OUTPUT_DEPTH_G,
      VGA_TOTAL_DEPTH_C       => VGA_TOTAL_DEPTH_C,
      FRAME_BUFFER_BIT_DEPTH_G=> FRAME_BUFFER_BIT_DEPTH_G
    )
    port map (
      i_clk25 => i_clk25,
      o_red   => o_red,
      o_green => o_green,
      o_blue  => o_blue,
      o_hs    => o_hs,
      o_vs    => o_vs,
      o_addrb => o_addrb,
      i_doutb => i_doutb
    );

  -------------------------------------------------------------------------
  -- Simple monitors (text output)
  -------------------------------------------------------------------------
  monitor_proc : process(i_clk25)
  begin
    if rising_edge(i_clk25) then
      if o_hs = '0' then
        report "HSYNC pulse detected at time " & time'image(now);
      end if;
      if o_vs = '0' then
        report "VSYNC pulse detected at time " & time'image(now);
      end if;
    end if;
  end process;

end architecture;

