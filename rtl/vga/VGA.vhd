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
       i_doutb : in std_logic_vector(VGA_TOTAL_DEPTH_C - 1 downto 0);
       i_count_x : in integer;
       i_count_y : in integer
     );
end VGA;

architecture Behavioral of VGA is

  signal hs : natural := 0;
  signal vs : natural := 0;

  signal red : std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0) := (others => '0');
  signal green : std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0) := (others => '0');
  signal blue : std_logic_vector(VGA_OUTPUT_DEPTH_G - 1 downto 0) := (others => '0');

  -- Colour is currently writable to the display
  signal is_addressable : std_logic := '0';

  signal counter : natural := 0;
  constant COUNTER_NEXT : natural := 25e6;
  signal test_channel : natural := 0;

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

  -- Address calculation
  o_addrb <= std_logic_vector(to_unsigned((i_count_y * H_RES) + i_count_x, FRAME_BUFFER_BIT_DEPTH_G));

  process (i_clk25)
  begin
    if rising_edge(i_clk25) then
      -- Increment counter
      -- if counter < COUNTER_NEXT then
      --   counter <= counter + 1;
      -- else
      --   counter <= 0;
      --   -- NOTE: An inferred latch but we don't care what it starts out as.
      --   test_channel <= (test_channel + 1) mod 4;
      -- end if;
      -- Background colour
      red <= (others => '0');
      green <= (others => '0');
      blue <= (others => '0');
      -- Test generation pattern
      -- if (  hs > H_RES / 2 - 200
      --   and hs < H_RES / 2 + 200
      --   and vs > V_RES / 2 - 200
      --   and vs < V_RES / 2 + 200
      -- ) then
      --   red <= (others => '1');
      -- end if;
      --   red <= "001";
      --   green <= (others => '1');
      --   blue <= (others => '1');
      -- end if;
      -- if test_channel = 0 then
      --   red <= std_logic_vector(to_unsigned(hs / 32, 3));
      --   blue <= std_logic_vector(to_unsigned(vs / 32, 3));
      --   green <= std_logic_vector(to_unsigned((hs + vs) / 16, 3));
      -- end if;
      -- if test_channel = 1 then
      --   green <= std_logic_vector(to_unsigned(hs / 32, 3));
      -- end if;
      -- if test_channel = 2 then
      --   blue <= std_logic_vector(to_unsigned(hs / 32, 3));
      -- end if;

      red <= i_doutb((VGA_OUTPUT_DEPTH_G * 3) - 1 downto (VGA_OUTPUT_DEPTH_G * 2));
      green <= i_doutb((VGA_OUTPUT_DEPTH_G * 2) - 1 downto VGA_OUTPUT_DEPTH_G);
      blue <= i_doutb(VGA_OUTPUT_DEPTH_G - 1 downto 0);
      -- Horizontal Sync Pulse
      if (hs < H_RES + H_FRONT_PORCH or hs > H_RES + H_FRONT_PORCH + H_SYNC_PULSE) then
        o_hs <= sync_polarity;
      else
        o_hs <= not sync_polarity;
      end if;
      
      -- Vertical Sync Pulse
      if (vs < V_RES + V_FRONT_PORCH or vs > V_RES + V_FRONT_PORCH + V_SYNC_PULSE) then
        o_vs <= sync_polarity;
      else
        o_vs <= not sync_polarity;
      end if;

      hs <= hs + 1;
      if ( hs = H_CYCLES ) then
        vs <= vs + 1;
        hs <= 0;
      end if;
      if (vs = V_CYCLES) then                 
        vs <= 0;
      end if;
    end if;
  end process;
end Behavioral;
