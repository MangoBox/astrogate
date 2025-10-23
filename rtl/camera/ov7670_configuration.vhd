library ieee;
use ieee.std_logic_1164.all;

use work.common_pkg.all;

entity ov7670_configuration is
    port (
        clk : in std_logic;
        rst : in std_logic;
        sda : inout std_logic;
        scl : inout std_logic;
        start : in std_logic;
        done : out std_logic;
        ack_err : out std_logic;
        ov7670_reset : out std_logic;
        config_finished : out std_logic;
        reg_value : out std_logic_vector(7 downto 0)
    );
end ov7670_configuration;

architecture behavioral of ov7670_configuration is
    signal i2c_ena : std_logic := '0'; -- latch in command
    signal i2c_addr : std_logic_vector(6 downto 0) := (others => '0'); -- address of target slave
    signal i2c_rw : std_logic := '0';
    signal i2c_busy : std_logic := '0'; -- indicates transaction in progress
    signal i2c_rdata, i2c_wdata : std_logic_vector(7 downto 0) := (others => '0'); -- data read from slave
    signal i2c_ack_err : std_logic := '0'; -- flag if improper acknowledge from slave

begin

    ov7670_fsm : entity work.ov7670_fsm(rtl)
        port map(
            clk => clk,
            rst => rst,
            start => start,
            i2c_busy => i2c_busy,
            i2c_rdata => i2c_rdata,
            i2c_addr => i2c_addr,
            i2c_wdata => i2c_wdata,
            i2c_ena => i2c_ena,
            i2c_rw => i2c_rw,
            ov7670_reset => ov7670_reset,
            reg_value => reg_value,
            config_finished => config_finished,
            done => done
        );

    i2c_master : entity work.i2c_master(logic) --i2c_master entity
        generic map(
            input_clk => c_arty_a7_clk_freq
        )
        port map(
            clk => clk,
            reset_n => rst,
            ena => i2c_ena,
            addr => i2c_addr,
            rw => i2c_rw,
            data_wr => i2c_wdata,
            busy => i2c_busy,
            data_rd => i2c_rdata,
            ack_error => i2c_ack_err,
            sda => sda,
            scl => scl
        );

    ack_err <= i2c_ack_err;

end behavioral;
