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
		clk : in std_logic;
		btn : in std_logic_vector(3 downto 0);
		edge : out std_logic_vector(3 downto 0));
end debounce;

architecture behavioral of debounce is
	signal c0, c1, c2 : std_logic_vector(3 downto 0) := (others => '0');
begin

	-- synchronisation
	process (clk)
	begin
		if rising_edge(clk) then
			c0 <= btn;
			c1 <= c0;
			c2 <= c1;
		end if;
	end process;

	-- erkennung der fallenden flanke (tastendruck)
	edge <= c2 and not c1;

end behavioral;
