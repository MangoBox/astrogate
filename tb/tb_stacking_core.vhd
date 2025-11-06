library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_stacking_core is
    -- Expose all key signals as ports so they are never optimized out
    port(
        o_tb_clk       : out std_logic;
        o_tb_rst       : out std_logic;
        o_tb_pixel     : out std_logic_vector(8 downto 0);
        o_tb_valid     : out std_logic;
        o_tb_cell_addr : out unsigned(15 downto 0);
        o_tb_cell_data : out std_logic_vector(8 downto 0);
        o_tb_cell_we   : out std_logic
    );
end tb_stacking_core;

architecture Behavioral of tb_stacking_core is

    constant CLK_PERIOD     : time := 10 ns;
    constant SCREEN_WIDTH   : integer := 32;
    constant SCREEN_HEIGHT  : integer := 16;
    constant CELL_SIZE      : integer := 2;
    constant PIXEL_WIDTH    : integer := 9;

    signal i_clk       : std_logic := '0';
    signal i_rst       : std_logic := '1';
    signal i_pixel     : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    signal i_valid     : std_logic := '0';

    signal o_cell_addr : unsigned(15 downto 0);
    signal o_cell_data : std_logic_vector(PIXEL_WIDTH-1 downto 0);
    signal o_cell_we   : std_logic;

begin

    -- Connect testbench signals to top-level ports
    o_tb_clk       <= i_clk;
    o_tb_rst       <= i_rst;
    o_tb_pixel     <= i_pixel;
    o_tb_valid     <= i_valid;
    o_tb_cell_addr <= o_cell_addr;
    o_tb_cell_data <= o_cell_data;
    o_tb_cell_we   <= o_cell_we;

    -- Clock generation
    clk_process : process
    begin
        while true loop
            i_clk <= '0';
            wait for CLK_PERIOD/2;
            i_clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- Instantiate the stacking core
    uut: entity work.stacking_core
        generic map(
            SCREEN_WIDTH  => SCREEN_WIDTH,
            SCREEN_HEIGHT => SCREEN_HEIGHT,
            CELL_SIZE     => CELL_SIZE,
            PIXEL_WIDTH   => PIXEL_WIDTH
        )
        port map(
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_pixel     => i_pixel,
            i_valid     => i_valid,
            o_cell_addr => o_cell_addr,
            o_cell_data => o_cell_data,
            o_cell_we   => o_cell_we
        );

    -- Stimulus process
    stimulus : process
        variable pixel_val : integer := 0;
    begin
        -- Reset
        i_rst <= '1';
        wait for 2*CLK_PERIOD;
        i_rst <= '0';
        wait for CLK_PERIOD;

        -- Feed pixels row by row
        for row in 0 to SCREEN_HEIGHT-1 loop
            for col in 0 to SCREEN_WIDTH-1 loop
                i_pixel <= std_logic_vector(to_unsigned(pixel_val mod 512, PIXEL_WIDTH));
                i_valid <= '1';
                wait for CLK_PERIOD;
                pixel_val := pixel_val + 1;
            end loop;
        end loop;

        -- Stop feeding pixels
        i_valid <= '0';
        wait for 10*CLK_PERIOD;

        -- Finish simulation
        wait;
    end process;

end Behavioral;
