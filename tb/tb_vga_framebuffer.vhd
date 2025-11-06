library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_vga_framebuffer is
  port (
    o_red    : out std_logic_vector(2 downto 0);
    o_green  : out std_logic_vector(2 downto 0);
    o_blue   : out std_logic_vector(2 downto 0);
    o_hs     : out std_logic;
    o_vs     : out std_logic
  );
end tb_vga_framebuffer;

architecture Behavioral of tb_vga_framebuffer is

    -- Constants
    constant VGA_OUTPUT_DEPTH_G : integer := 3;
    constant FRAME_BUFFER_BIT_DEPTH_G : integer := 15;
    constant FRAME_WIDTH : integer := 640;
    constant FRAME_HEIGHT : integer := 480;

    -- Signals for clocks
    signal ov7670_pclk : std_logic := '0';  -- 24 MHz write clock
    signal vga_clk     : std_logic := '0';  -- 25 MHz read clock

    -- Signals for framebuffer
    signal addra : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G-1 downto 0) := (others => '0');
    signal addrb : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G-1 downto 0) := (others => '0');
    signal addra_div : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G-1 downto 0) := (others => '0');
    signal addrb_div : std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G-1 downto 0) := (others => '0');
    signal wea   : std_logic_vector(0 downto 0) := (others => '0');
    signal dina  : std_logic_vector(8 downto 0) := (others => '0');  -- Assuming 24-bit input data
    signal doutb : std_logic_vector(8 downto 0);  -- Adjust width to VGA_TOTAL_DEPTH_C if needed

begin
    addra_div <= "00" & addra(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 2);
    addrb_div <= "00" & addrb(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 2);
    -------------------------------------------------------------------
    -- Clock generation
    -------------------------------------------------------------------
    clk_24mhz : process
    begin
        ov7670_pclk <= '0';
        wait for 20.833 ns; -- 24 MHz period / 2
        ov7670_pclk <= '1';
        wait for 20.833 ns;
    end process;

    clk_25mhz : process
    begin
        vga_clk <= '0';
        wait for 20 ns; -- 25 MHz period / 2
        vga_clk <= '1';
        wait for 20 ns;
    end process;

    -------------------------------------------------------------------
    -- Framebuffer write stimulus
    -------------------------------------------------------------------
    stimulus : process
    begin
        -- Wait some time for reset
        wait for 100 ns;

        -- Write a pattern to framebuffer
        for i in 0 to 1023 loop
            dina  <= std_logic_vector(to_unsigned(i mod 256, 9));  -- example pattern
            addra <= std_logic_vector(to_unsigned(i, FRAME_BUFFER_BIT_DEPTH_G));
            wea(0) <= '1';
            wait until rising_edge(ov7670_pclk);
        end loop;
        wea(0) <= '0';

        -- Stop simulation after some time
        wait for 100 ms;
        assert false report "End of simulation" severity failure;
    end process;

    -------------------------------------------------------------------
    -- Instantiate framebuffer
    -------------------------------------------------------------------
    framebuffer_inst : entity work.framebuffer
        port map (
            wraddress => addra_div,
            wrclock   => ov7670_pclk,
            wren      => wea(0),
            data      => dina,
            rdaddress => addrb_div,
            rdclock   => vga_clk,
            q         => doutb
        );

    -------------------------------------------------------------------
    -- Instantiate VGA output
    -------------------------------------------------------------------
    e_vga_output : entity work.VGA
        generic map (
            VGA_OUTPUT_DEPTH_G => VGA_OUTPUT_DEPTH_G,
            FRAME_BUFFER_BIT_DEPTH_G => FRAME_BUFFER_BIT_DEPTH_G
        )
        port map (
            i_clk25 => vga_clk,
            o_red   => o_red,
            o_green => o_green,
            o_blue  => o_blue,
            o_hs    => o_hs,
            o_vs    => o_vs,
            i_doutb => doutb,
            o_addrb => addrb
        );

end Behavioral;

