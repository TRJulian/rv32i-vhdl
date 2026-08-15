library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity hack_alu is
  generic (
    DATA_WIDTH : positive := 16
  );
  port (
    x_i      : in    signed(DATA_WIDTH - 1 downto 0);
    y_i      : in    signed(DATA_WIDTH - 1 downto 0);
    zx_i     : in    std_logic;
    zy_i     : in    std_logic;
    nx_i     : in    std_logic;
    ny_i     : in    std_logic;
    f_i      : in    std_logic;
    no_i     : in    std_logic;
    output_o : out   signed(DATA_WIDTH - 1 downto 0);
    zr_o     : out   std_logic;
    ng_o     : out   std_logic
  );
end entity hack_alu;

architecture rtl of hack_alu is

begin

  main_proc : process (all) is

    variable x_1      : signed(DATA_WIDTH - 1 downto 0);
    variable y_1      : signed(DATA_WIDTH - 1 downto 0);
    variable output_1 : signed(DATA_WIDTH - 1 downto 0);

  begin

    x_1      := x_i;
    y_1      := y_i;
    x_1      := (others => '0') when zx_i = '1';
    y_1      := (others => '0') when zy_i = '1';
    x_1      := not x_1 when nx_i = '1';
    y_1      := not y_1 when ny_i = '1';
    output_1 := x_1 + y_1 when f_i = '1' else x_1 and y_1;
    output_1 := not output_1 when no_i = '1';
    output_o <= output_1;
    zr_o     <= '1' when output_1 = 0 else '0';
    ng_o     <= '1' when output_1 < 0 else '0';

  end process main_proc;

end architecture rtl;
