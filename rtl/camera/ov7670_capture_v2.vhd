library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ov7670_capture_v2 is
    generic (
      VGA_HEIGHT : integer := 640;
      VGA_WIDTH : integer := 480;
      RAM_ADDRESS_WIDTH : integer := 20
    );
    port (
        -- Camera interface
        cam_pclk  : in  std_logic;              -- Pixel clock from camera
        cam_vsync : in  std_logic;              -- Frame sync
        cam_href  : in  std_logic;              -- Line valid
        cam_data  : in  std_logic_vector(7 downto 0);  -- 8-bit pixel data

        -- Output pixel stream
        pixel_clk   : out std_logic;            -- Same as cam_pclk (for FIFO)
        pixel_valid : out std_logic;            -- High for one clock when pixel_data is valid
        pixel_data  : out std_logic_vector(15 downto 0); -- RGB565 pixel
        frame_valid : out std_logic;            -- High during active frame (vsync low)
        line_valid  : out std_logic;             -- High during active line (href high)

        -- Positional data
        ram_addr : out std_logic_vector(RAM_ADDRESS_WIDTH - 1 downto 0);
        x_count : out integer := 0;
        y_count : out integer := 0
    );
end entity ov7670_capture_v2;

architecture rtl of ov7670_capture_v2 is
    signal byte_toggle : std_logic := '0';          -- toggles each byte
    signal pixel_buf   : std_logic_vector(15 downto 0) := (others => '0');
    signal pixel_valid_int : std_logic := '0';
    signal frame_valid_int : std_logic := '0';
    signal line_valid_int  : std_logic := '0';
    signal x_count_int : integer := 0;
    signal y_count_int : integer := 0;
    --
    signal write_addr : unsigned(RAM_ADDRESS_WIDTH - 1 downto 0);
begin

    -------------------------------------------------------------------
    -- Camera capture process (PCLK domain)
    -------------------------------------------------------------------
    process(cam_pclk)
    begin
        if rising_edge(cam_pclk) then

            -- VSYNC is active high on OV7670 (new frame)
            if cam_vsync = '1' then
                frame_valid_int <= '0';    -- no valid pixels during vsync
                byte_toggle <= '0';
                pixel_valid_int <= '0';

            else
                frame_valid_int <= '1';

                if cam_href = '1' then     -- active line
                    line_valid_int <= '1';

                    if byte_toggle = '0' then
                        -- First byte (high)
                        pixel_buf(15 downto 8) <= cam_data;
                        byte_toggle <= '1';
                        pixel_valid_int <= '0';
                    else
                        -- Second byte (low), full pixel ready
                        pixel_buf(7 downto 0) <= cam_data;
                        byte_toggle <= '0';
                        pixel_valid_int <= '1';
                    end if;

                else
                    line_valid_int <= '0';
                    byte_toggle <= '0';
                    pixel_valid_int <= '0';
                end if;
            end if;
        end if;
    end process;

    process(cam_pclk)
    begin
        if rising_edge(cam_pclk) then
          if cam_vsync = '1' then
              y_count_int <= 0;
              x_count_int <= 0;
          elsif cam_href = '1' then
              if pixel_valid_int = '1' then
                  x_count_int <= x_count_int + 1;
                  -- Do we need this?
                  -- Shouldn't Vsync auto reset?
                  if x_count_int = VGA_WIDTH-1 then
                      x_count_int <= 0;
                      y_count_int <= y_count_int + 1;
                  end if;
              end if;
          end if;
        end if;
    end process;

    -- Packing RAM address
    -- write_addr <= x_count_int + (VGA_WIDTH * y_count_int);
    write_addr <= shift_right(to_unsigned(x_count_int + (VGA_WIDTH * y_count_int), RAM_ADDRESS_WIDTH),2);
    ram_addr <= std_logic_vector(write_addr);

    -------------------------------------------------------------------
    -- Output assignments
    -------------------------------------------------------------------
    pixel_data  <= pixel_buf;
    pixel_valid <= pixel_valid_int;
    frame_valid <= frame_valid_int;
    line_valid  <= line_valid_int;
    pixel_clk   <= cam_pclk;  -- pass through for FIFO write domain
    y_count <= y_count_int;
    x_count <= x_count_int;

end architecture rtl;
