library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_pkg.all;

entity ov7670_fsm is
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        i2c_busy : in std_logic;
        i2c_rdata : in std_logic_vector(7 downto 0);
        i2c_addr : out std_logic_vector(6 downto 0);
        i2c_wdata : out std_logic_vector(7 downto 0);
        i2c_ena : out std_logic;
        i2c_rw : out std_logic;
        ov7670_reset : out std_logic;
        reg_value : out std_logic_vector(7 downto 0);
        config_finished : out std_logic;
        done : out std_logic
    );
end ov7670_fsm;

architecture rtl of ov7670_fsm is

    --type decleration
    type state_type is (powerup, idle, reset_device, i2c_write_register, wait_between_tx, i2c_write_read_register_address, wait_1us,
        i2c_read_reg, wait_1us_after_read);


    --signals
    constant i2c_read : std_logic := '1';
    constant i2c_write : std_logic := '0';
    constant ov7670_addr : std_logic_vector(6 downto 0) := "0100001";

    constant clk_cnt_600ms : integer := (c_arty_a7_clk_freq / 10) * 6;
    constant clk_cnt_1ms : integer := (c_arty_a7_clk_freq / 1000);
    constant clk_cnt_1us : integer := (c_arty_a7_clk_freq / 1_000_000);

    signal reset_busy_cnt : std_logic := '0';
    signal ov7670_reset_sig : std_logic := '1';
    signal busy_prev : std_logic := '0';
    signal register_config : std_logic_vector(15 downto 0) := (others => '0');
    signal i2c_busy_edge : std_logic := '0';

    type reg_type is record
        state : state_type;
        counter : integer range 0 to clk_cnt_600ms;
        i2c_ena : std_logic;
        read : std_logic_vector(7 downto 0);
        done : std_logic;
        config_finished : std_logic;
        rom_index : integer range 0 to register_config_rom'length;
    end record reg_type;

    type i2c_reg_type is record
        busy : std_logic;
        busy_cnt : integer range 0 to 3;
    end record i2c_reg_type;

    constant init_reg_file : reg_type := (
        state => powerup,
        counter => 0,
        i2c_ena => '0',
        read => (others => '0'),
        done => '0',
        config_finished => '0',
        rom_index => 0
    );

    constant init_i2c_regs : i2c_reg_type := (
        busy => '0',
        busy_cnt => 0
    );

    signal reg, reg_next : reg_type := init_reg_file;
    signal i2c_reg, i2c_next : i2c_reg_type := init_i2c_regs;
begin

    process (clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= init_reg_file;
                i2c_reg <= init_i2c_regs;
            else
                reg <= reg_next;
                i2c_reg <= i2c_next;
            end if;
        end if;
    end process;

    process (reg, start, i2c_reg, register_config, i2c_rdata, i2c_busy, busy_prev)
    begin
        reg_next <= reg;

        i2c_rw <= '0';
        reset_busy_cnt <= '0';
        i2c_wdata <= (others => '0');
        ov7670_reset_sig <= '1';
        case reg.state is

            when powerup => --wait 600ms for device to powerup 
                reg_next.counter <= reg.counter + 1;
                if reg.counter = clk_cnt_600ms - 1 then
                    reg_next.counter <= 0;
                    reset_busy_cnt <= '1';
                    reg_next.state <= reset_device;
                end if;

            when idle =>
                if start = '1' then
                    reg_next.rom_index <= 0;
                    reg_next.config_finished <= '0';
                    reg_next.state <= reset_device;
                end if;

            when reset_device =>

                reg_next.counter <= reg.counter + 1;
                if reg.counter < clk_cnt_600ms / 2 then
                    ov7670_reset_sig <= '0'; --active low reset
                end if;

                if reg.counter = clk_cnt_600ms then
                    reg_next.counter <= 0; --reset counter
                    reg_next.state <= i2c_write_register; -- 600ms over
                    reset_busy_cnt <= '1';
                end if;

            when i2c_write_register =>
                case i2c_reg.busy_cnt is
                    when 0 =>
                        reg_next.i2c_ena <= '1'; --start i2c transaction
                        i2c_rw <= i2c_write;
                        i2c_wdata <= register_config(15 downto 8);-- register address
                    when 1 =>
                        i2c_wdata <= register_config(7 downto 0);-- register value
                    when 2 =>
                        reg_next.i2c_ena <= '0';
                        if i2c_busy = '0' then --i2c transaction completed 
                            reset_busy_cnt <= '1'; --reset busy_cnt register
                            reg_next.state <= wait_between_tx;
                        end if;
                    when others => null;
                end case;

            when wait_between_tx => -- waits for 1ms between write and read
                reg_next.counter <= reg.counter + 1;

                if reg.counter = clk_cnt_1ms - 1 then
                    reg_next.counter <= 0;
                    if reg.rom_index < register_config_rom'length then
                        reg_next.rom_index <= reg.rom_index + 1;
                        reg_next.state <= i2c_write_register;
                    else
                        reg_next.rom_index <= 0;
                        reg_next.config_finished <= '1';
                        reg_next.state <= i2c_write_read_register_address;
                    end if;
                end if;

            when i2c_write_read_register_address =>
                case i2c_reg.busy_cnt is
                    when 0 =>
                        reg_next.i2c_ena <= '1';
                        i2c_rw <= i2c_write;
                        i2c_wdata <= register_config(15 downto 8);
                    when 1 =>
                        reg_next.i2c_ena <= '0';
                        if i2c_busy = '0' then
                            reg_next.counter <= 0;

                            reg_next.state <= wait_1us;
                            reset_busy_cnt <= '1';
                        end if;
                    when others => null;
                end case;

            when wait_1us => --wait 1us between write register address and read register value
                reg_next.counter <= reg.counter + 1;
                if reg.counter = clk_cnt_1us - 1 then
                    reg_next.counter <= 0;
                    reg_next.state <= i2c_read_reg;
                    reset_busy_cnt <= '1';
                end if;

            when i2c_read_reg =>
                case i2c_reg.busy_cnt is
                    when 0 =>
                        reg_next.i2c_ena <= '1';
                        i2c_rw <= i2c_read;
                    when 1 =>
                        i2c_rw <= i2c_read;
                        if i2c_busy = '0' then
                            reg_next.done <= '1';
                            reg_next.read <= i2c_rdata;
                            reg_next.i2c_ena <= '0';
                            reg_next.state <= wait_1us_after_read;
                            reset_busy_cnt <= '1';
                        end if;
                    when others => null;
                end case;

            when wait_1us_after_read => --wait 1us between write register address and read register value
                reg_next.done <= '0';
                reg_next.counter <= reg.counter + 1;

                if reg.counter >= clk_cnt_1us - 1 then
                    reg_next.counter <= reg.counter;

                    if reg.rom_index < register_config_rom'length then
                        reg_next.rom_index <= reg.rom_index + 1;
                        reset_busy_cnt <= '1';
                        reg_next.counter <= 0;
                        reg_next.state <= i2c_write_read_register_address;
                    else
                        reg_next.counter <= 0;
                        reg_next.state <= idle;
                    end if;
                end if;
            when others =>
                reg_next.state <= idle;
        end case;
    end process;

    i2c_next.busy_cnt <= 0 when reset_busy_cnt = '1' else
    i2c_reg.busy_cnt + 1 when i2c_busy_edge = '1' else
    i2c_reg.busy_cnt;

    i2c_next.busy <= i2c_busy; --captures the current value of the busy signal in the busy register
    i2c_busy_edge <= '1' when (i2c_reg.busy = '0' and i2c_busy = '1') else
        '0'; --detects the rising_edge of the busy signal from the i2c_master
    i2c_addr <= ov7670_addr;

    reg_value <= reg.read;

    register_config <= register_config_rom(reg.rom_index);

    i2c_ena <= reg.i2c_ena;
    done <= reg.done;

    config_finished <= reg.config_finished;

    ov7670_reset <= ov7670_reset_sig;
end architecture;
