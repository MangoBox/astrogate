library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debounce is
	port (
		clk : in std_logic_vector(3 downto 0);
		btn : in std_logic_vector(3 downto 0);
		edge : out std_logic_vector(3 downto 0));
end debounce;

architecture behavioral of debounce is
	signal c0, c1, c2 : std_logic_vector(3 downto 0) := (others => '0');
begin

    gen_buttons : for i in 0 to 4-1 generate
    process(clk(i))
    begin
      if rising_edge(clk(i)) then
        c0(i) <= btn(i);
        c1(i) <= c0(i);
        c2(i) <= c1(i);
      end if;
    end process;

    -- simple rising-edge detection
    edge(i) <= c2(i) and not c1(i);
  end generate gen_buttons;

end behavioral;
