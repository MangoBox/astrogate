library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ov7670_capture is
    generic (
      FRAME_BUFFER_BIT_DEPTH_G : integer := 16;
      VGA_OUTPUT_DEPTH_G : integer := 6

    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        config_finished : in std_logic;

        --camera signals  
        ov7670_vsync : in std_logic;
        ov7670_href : in std_logic;
        ov7670_pclk : in std_logic;
        ov7670_data : in std_logic_vector(7 downto 0);
        start : in std_logic;
        frame_finished_o : out std_logic;
        pixel_data : out std_logic_vector(15 downto 0);

        --frame_buffer signals
        wea : out std_logic_vector(0 downto 0);
        dina : out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
        addra : out std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0)
    );
end ov7670_capture;

architecture rtl of ov7670_capture is

    type state_type is (
        idle, start_capturing, wait_for_new_frame, frame_finished, capture_line, capture_rgb_byte, write_to_bram
    );

    --registers
    signal vsync_reg, vsync_next : std_logic := '0';
    signal href_reg, href_next : std_logic := '0';
    signal pclk_reg, pclk_next : std_logic := '0';

    signal vsync_falling_edge, vsync_rising_edge : std_logic := '0';
    signal href_rising_edge, href_falling_edge : std_logic := '0';
    signal pclk_edge : std_logic := '0';

    signal frame_finished_reg, frame_finished_next : std_logic := '0';
    
    type reg_type is record
        state : state_type;
        href_cnt : integer range 0 to 500;
        rgb_reg : std_logic_vector(15 downto 0);
        pixel_reg : integer range 0 to 650;
        bram_address : unsigned(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0);
    end record reg_type;

    constant init_reg_file : reg_type := (
        state => idle,
        href_cnt => 0,
        rgb_reg => (others => '0'),
        pixel_reg => 0,
        bram_address => (others => '0')
    );

    signal reg, reg_next : reg_type := init_reg_file;

begin
    addra <= std_logic_vector(reg.bram_address);

    vsync_next <= ov7670_vsync;
    vsync_falling_edge <= '1' when vsync_reg = '1' and ov7670_vsync = '0' else
        '0'; --detect falling edge of external vsync signal (start of frame) 

    vsync_rising_edge <= '1' when vsync_reg = '0' and ov7670_vsync = '1' else
        '0'; --detect rising edge of external vsync signal (end of frame) 

    href_next <= ov7670_href; --register external href signal from camera

    href_rising_edge <= '1' when href_reg = '0' and ov7670_href = '1' else
        '0';
    href_falling_edge <= '1' when href_reg = '1' and ov7670_href = '0' else
        '0';

    pclk_next <= ov7670_pclk;
    pclk_edge <= '1' when pclk_reg = '0' and ov7670_pclk = '1' else --todo can external pclk be directly used as a clk? 
        '0';

    sync : process (clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then --todo tie reset to pll lock? 
                reg <= init_reg_file;
                vsync_reg <= '0';
                pclk_reg <= '0';
                href_reg <= '0';
            else
                reg <= reg_next;
                vsync_reg <= vsync_next;
                href_reg <= href_next;
                pclk_reg <= pclk_next;
            end if;
        end if;
    end process;

    comb : process (reg, ov7670_data, pclk_edge, href_rising_edge, start, vsync_falling_edge, vsync_rising_edge, config_finished)
    begin
        reg_next <= reg;
        frame_finished_o <= '0'; --debug
        wea <= "0";
        dina <= (others => '0');
        case reg.state is

            when idle =>
                if start = '1' and config_finished = '1' then
                    reg_next.bram_address <= (others => '0');
                    reg_next.state <= wait_for_new_frame;
                end if;

            when wait_for_new_frame =>
                if vsync_falling_edge = '1' then --new frame is about to start
                    reg_next.href_cnt <= 0;
                    reg_next.state <= start_capturing;
                end if;

            when start_capturing =>
                if href_rising_edge = '1' then
                    reg_next.pixel_reg <= 0; -- new line: start with pixel position 0
                    reg_next.state <= capture_line;
                end if;

            when capture_line =>
                if pclk_edge = '1' then

                    reg_next.rgb_reg(15 downto 8) <= ov7670_data; --capture first byte of pixel data
                    reg_next.state <= capture_rgb_byte;
                end if;

            when capture_rgb_byte =>
                if pclk_edge = '1' then

                    reg_next.rgb_reg(7 downto 0) <= ov7670_data; --capture first byte of pixel data

                    reg_next.pixel_reg <= reg.pixel_reg + 1; --keep track of current pixel position in line

                    if reg.pixel_reg = 639 then --line finished
                        reg_next.href_cnt <= reg.href_cnt + 1;

                        if reg.href_cnt = 479 then
                            reg_next.state <= frame_finished; --frame finished
                        else
                            reg_next.state <= start_capturing; -- wait for start of new line 
                        end if;

                    else
                        reg_next.state <= write_to_bram;
                    end if;
                end if;

            when write_to_bram =>
                wea <= "1"; --write enable bram
                dina <= reg.rgb_reg(VGA_OUTPUT_DEPTH_G - 1 downto 0); --write 12 bit pixel value to bram
                reg_next.bram_address <= reg.bram_address + 1; --increment address register for next pixel
                reg_next.state <= capture_line; --capture next pixel

            when frame_finished =>
                frame_finished_o <= '1';
                reg_next.rgb_reg <= (others => '0');
                reg_next.bram_address <= (others => '0');
                reg_next.state <= wait_for_new_frame;

            when others => null;
        end case;
    end process;

    pixel_data <= reg.rgb_reg;

end architecture;
