library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stacking_core is
    generic(
        SCREEN_WIDTH  : integer := 640;
        SCREEN_HEIGHT : integer := 480;
        CELL_SIZE     : integer := 2; -- n x n
        PIXEL_WIDTH   : integer := 9
    );
    port(
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_pixel     : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
        i_valid     : in  std_logic;

        o_cell_addr : out unsigned(15 downto 0);
        o_cell_data : out std_logic_vector(PIXEL_WIDTH-1 downto 0);
        o_cell_we   : out std_logic
    );
end stacking_core;

architecture Behavioral of stacking_core is

    constant CELLS_X     : integer := SCREEN_WIDTH / CELL_SIZE;
    constant CELL_PIXELS : integer := CELL_SIZE * CELL_SIZE;
    
    -- log2 of CELL_PIXELS for shift division
    function log2(n : integer) return integer is
        variable res : integer := 0;
        variable v   : integer := n;
    begin
        while v > 1 loop
            v := v / 2;
            res := res + 1;
        end loop;
        return res;
    end function;
    constant SHIFT_BITS : integer := log2(CELL_PIXELS);
    function clog2(x : integer) return integer is
        variable res : integer := 0;
        variable tmp : integer := x-1;
    begin
        while tmp > 0 loop
            tmp := tmp / 2;
            res := res + 1;
        end loop;
        return res;
    end function;

    constant ACC_WIDTH : integer := PIXEL_WIDTH + clog2(CELL_PIXELS*CELL_PIXELS);
    type accum_array_t is array (0 to SCREEN_WIDTH/CELL_SIZE-1) of unsigned(ACC_WIDTH-1 downto 0);

    -- accumulator per cell in current row
    signal accum_row   : accum_array_t := (others => (others => '0'));

    signal cell_pixel_x : integer range 0 to CELL_SIZE-1 := 0;
    signal cell_pixel_y : integer range 0 to CELL_SIZE-1 := 0;
    signal cell_x       : integer range 0 to CELLS_X-1 := 0;

    -- output registers
    signal o_data_reg   : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    signal o_addr_reg   : unsigned(15 downto 0) := (others => '0');
    signal o_we_reg     : std_logic := '0';

begin

    -- combinatorial output
    o_cell_data <= o_data_reg;
    o_cell_addr <= o_addr_reg;
    o_cell_we   <= o_we_reg;

    -- main sequential process
    process(i_clk)
        variable avg : unsigned(ACC_WIDTH-1 downto 0);
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                accum_row     <= (others => (others => '0'));
                cell_pixel_x  <= 0;
                cell_pixel_y  <= 0;
                cell_x        <= 0;
                o_data_reg    <= (others => '0');
                o_addr_reg    <= (others => '0');
                o_we_reg      <= '0';
            elsif i_valid = '1' then
                -- accumulate pixel into current cell
                accum_row(cell_x) <= accum_row(cell_x) + unsigned(i_pixel);

                -- move within cell horizontally
                if cell_pixel_x = CELL_SIZE-1 then
                    cell_pixel_x <= 0;
                    -- move within cell vertically
                    if cell_pixel_y = CELL_SIZE-1 then
                        cell_pixel_y <= 0;
                        -- cell complete: compute average and output
                        avg := accum_row(cell_x) srl SHIFT_BITS;
                        o_data_reg <= std_logic_vector(avg(PIXEL_WIDTH-1 downto 0));
                        o_addr_reg <= to_unsigned(cell_x,16);
                        o_we_reg   <= '1';

                        -- reset accumulator for next use
                        accum_row(cell_x) <= (others => '0');

                        -- move to next cell in the row
                        if cell_x = CELLS_X-1 then
                            cell_x <= 0;
                        else
                            cell_x <= cell_x + 1;
                        end if;

                    else
                        cell_pixel_y <= cell_pixel_y + 1;
                        o_we_reg <= '0';
                    end if;
                else
                    cell_pixel_x <= cell_pixel_x + 1;
                    o_we_reg <= '0';
                end if;
            else
                o_we_reg <= '0';
            end if;
        end if;
    end process;

end Behavioral;

