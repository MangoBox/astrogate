library ieee;
use ieee.std_logic_1164.all;

entity tb_astrogate_top is
end tb_astrogate_top;

architecture behavior of tb_astrogate_top is
    -- Clock and reset signals
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
begin

    -- Clock generation process: 50 MHz = 20 ns period
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Reset generation process
    reset_process : process
    begin
        reset <= '1';       -- Assert reset
        wait for 1 us;
        reset <= '0';       -- Deassert reset
        wait until false;
    end process;

    -- DUT instantiation (direct entity instantiation)
    dut_inst : entity work.astrogate_top
        port map (
            clk   => clk,
            rst   => reset
        );

end behavior;

