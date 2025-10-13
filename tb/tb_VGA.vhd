library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_VGA is
end entity tb_VGA;

architecture test of tb_VGA is
  signal clock  : std_logic := '0';
  signal reset  : std_logic := '1';
begin
  -- Reset and clock
  clock <= not clock after 20 ns;
  reset <= '1', '0' after 5 ns;
  
  -- Instantiate the design under test
  dut: entity work.VGA
    port map (
      i_clk50   => clock
    );
    
  -- Generate the test stimulus
  stimulus:
  process begin
    -- Wait for the Reset to be released before 
    wait for 50 ms;
  end process stimulus;
  
end architecture test;
