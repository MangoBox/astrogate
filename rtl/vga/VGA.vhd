library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
  generic(
    sync_polarity : std_logic := '1';
    VGA_OUTPUT_DEPTH_G : integer := 3;
    VGA_TOTAL_DEPTH_C : integer := 9;
    FRAME_BUFFER_BIT_DEPTH_G : integer := 16
    );
  port(
       i_clk25: in std_logic;
       o_red:   out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
       o_green: out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
       o_blue:  out std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0);
       o_hs:    out std_logic;
       o_vs:    out std_logic;
       -- frame buffer read/wr signals
       o_addrb : out std_logic_vector(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0);
       i_doutb : in std_logic_vector(VGA_TOTAL_DEPTH_C - 1 downto 0)
     );
end VGA;

architecture Behavioral of VGA is

  signal hs, hs_next : natural := 0;
  signal vs, vs_next : natural := 0;

  signal o_vs_next, o_hs_next : std_logic;

  signal red : std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0) := (others => '0');
  signal green : std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0) := (others => '0');
  signal blue : std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0) := (others => '0');
  signal bram_address_reg, bram_address_next : unsigned(FRAME_BUFFER_BIT_DEPTH_G - 1 downto 0) := (others => '0');
  -- Colour is currently writable to the display
  signal is_addressable : std_logic := '0';

  -- Horizontal sync res
  constant H_RES : natural         := 640;
  constant H_FRONT_PORCH : natural := 16;
  constant H_BACK_PORCH : natural  := 48;
  constant H_SYNC_PULSE : natural  := 96;
  constant H_CYCLES : natural      := H_RES + H_FRONT_PORCH + H_BACK_PORCH + H_SYNC_PULSE;

  constant V_RES : natural         := 480;
  constant V_FRONT_PORCH : natural := 10;
  constant V_BACK_PORCH : natural  := 33;
  constant V_SYNC_PULSE : natural  := 2;
  constant V_CYCLES : natural      := V_RES + V_FRONT_PORCH + V_BACK_PORCH + V_SYNC_PULSE;

begin

  -- Output gating if in addressable area.
  o_red <= red when is_addressable = '1' else (others => '0');
  o_green <= green when is_addressable = '1' else (others => '0');
  o_blue <= blue when is_addressable = '1' else (others => '0');

  is_addressable <= '1' when
    vs < V_RES and
    hs < H_RES else '0';

  o_addrb <= std_logic_vector(bram_address_reg);
  red <= i_doutb((VGA_OUTPUT_DEPTH_G * 3) - 1 downto (VGA_OUTPUT_DEPTH_G * 2));
  green <= i_doutb((VGA_OUTPUT_DEPTH_G * 2) - 1 downto VGA_OUTPUT_DEPTH_G);
  blue <= i_doutb(VGA_OUTPUT_DEPTH_G - 1 downto 0);

  process(i_clk25)
  begin
      if rising_edge(i_clk25) then
          -- update counters
          hs <= hs_next;
          vs <= vs_next;
          bram_address_reg <= bram_address_next;
          -- update signal outs
          o_vs <= o_vs_next;
          o_hs <= o_hs_next;
      end if;
  end process;

  -- combinational logic for next state
  hs_next <= hs + 1 when hs <= H_CYCLES else 0;
  bram_address_next <= bram_address_reg + 1 when hs <= H_CYCLES;
  vs_next <= 0 when vs = V_CYCLES else vs + 1 when hs = H_CYCLES else vs;

  -- VSYNC and HSYNC computed from current state
  o_hs_next <= not sync_polarity when (hs >= H_RES + H_FRONT_PORCH and hs < H_RES + H_FRONT_PORCH + H_SYNC_PULSE)
          else sync_polarity;

  o_vs_next <= not sync_polarity when (vs >= V_RES + V_FRONT_PORCH and vs < V_RES + V_FRONT_PORCH + V_SYNC_PULSE)
          else sync_polarity;

end Behavioral;
