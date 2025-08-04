library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity and_gate is
  port (
         in_a : in std_logic;
         in_b : in std_logic;
         result : out std_logic
       );
end entity;

architecture rtl of and_gate is
begin
  result <= in_a and in_b;
end architecture;
