library ieee;
use ieee.std_logic_1164.all;

entity test_3 is
  port (
         input_1    : in  std_logic;
         input_2    : in  std_logic;
         and_result : out std_logic
       );
end test_3;

architecture rtl of test_3 is
    signal button_a : std_logic;
    signal button_b : std_logic;
    signal led_sig  : std_logic;
begin
  button_a <= not input_1;
  button_b <= not input_2;

  e_and_gate : entity work.and_gate 
  port map (
             in_a => button_a,
             in_b => button_b,
             result => led_sig
           );
  -- Output LED as active low
  and_result <= not led_sig;
end rtl;
