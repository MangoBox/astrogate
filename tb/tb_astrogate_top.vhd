library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_astrogate_top is
end tb_astrogate_top;

architecture tb of tb_astrogate_top is

    -- Signals for connecting to UUT
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';

begin
  dut : entity work.astrogate_top
      port map (
          clk     => clk,
          rst_n   => reset,
          ov7670_vsync => '0',
          ov7670_href => '0',
          ov7670_pclk => '0',
          ov7670_data => (others => '0'),
          sw => (others => '0')
      );

    clk_process : process
    begin
        while true loop
            clk <= '1';
            wait for 10 ns;
            clk <= '0';
            wait for 10 ns;
        end loop;
    end process;

    rst_process : process
    begin
      reset <= '0';
      wait for 1 us;
      reset <= '1';
    end process;

end tb;

