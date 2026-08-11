library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity alu_tb is
end entity alu_tb;

architecture tb of alu_tb is

  constant DATA_WIDTH : positive := 4;

  signal x      : signed(DATA_WIDTH - 1 downto 0);
  signal y      : signed(DATA_WIDTH - 1 downto 0);
  signal zx     : std_logic;
  signal zy     : std_logic;
  signal nx     : std_logic;
  signal ny     : std_logic;
  signal f      : std_logic;
  signal no     : std_logic;
  signal output : signed(DATA_WIDTH - 1 downto 0);
  signal zr     : std_logic;
  signal ng     : std_logic;

  type test_name_t is (
    ZERO, ONE, M_ONE, XX, YY, NOT_X, NOT_Y,
    M_X, M_Y, INC_X, INC_Y, DEC_X, DEC_Y,
    ADD, SUB_X_Y, SUB_Y_X, AAND, OOR
  );

  type test_vec_t is record
    zx, zy, nx, ny, f, no : std_logic;
    name                  : test_name_t;
  end record test_vec_t;

  type test_vec_array_t is array (natural range <>) of test_vec_t;

  constant TESTS : test_vec_array_t :=
  (
    (
      zx   => '1',
      nx   => '0',
      zy   => '1',
      ny   => '0',
      f    => '1',
      no   => '0',
      name => ZERO
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '1',
      ny   => '1',
      f    => '1',
      no   => '1',
      name => ONE
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '1',
      ny   => '0',
      f    => '1',
      no   => '0',
      name => M_ONE
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '1',
      ny   => '1',
      f    => '0',
      no   => '0',
      name => XX
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '0',
      ny   => '0',
      f    => '0',
      no   => '0',
      name => YY
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '1',
      ny   => '1',
      f    => '0',
      no   => '1',
      name => NOT_X
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '0',
      ny   => '0',
      f    => '0',
      no   => '1',
      name => NOT_Y
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '1',
      ny   => '1',
      f    => '1',
      no   => '1',
      name => M_X
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '0',
      ny   => '0',
      f    => '1',
      no   => '1',
      name => M_Y
    ),
    (
      zx   => '0',
      nx   => '1',
      zy   => '1',
      ny   => '1',
      f    => '1',
      no   => '1',
      name => INC_X
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '0',
      ny   => '1',
      f    => '1',
      no   => '1',
      name => INC_Y
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '1',
      ny   => '1',
      f    => '1',
      no   => '0',
      name => DEC_X
    ),
    (
      zx   => '1',
      nx   => '1',
      zy   => '0',
      ny   => '0',
      f    => '1',
      no   => '0',
      name => DEC_Y
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '0',
      ny   => '0',
      f    => '1',
      no   => '0',
      name => ADD
    ),
    (
      zx   => '0',
      nx   => '1',
      zy   => '0',
      ny   => '0',
      f    => '1',
      no   => '1',
      name => SUB_X_Y
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '0',
      ny   => '1',
      f    => '1',
      no   => '1',
      name => SUB_Y_X
    ),
    (
      zx   => '0',
      nx   => '0',
      zy   => '0',
      ny   => '0',
      f    => '0',
      no   => '0',
      name => AAND
    ),
    (
      zx   => '0',
      nx   => '1',
      zy   => '0',
      ny   => '1',
      f    => '0',
      no   => '1',
      name => OOR
    )
  );

begin

  u_alu : entity work.alu(rtl)
    generic map (
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      x_i      => x,
      y_i      => y,
      zx_i     => zx,
      zy_i     => zy,
      nx_i     => nx,
      ny_i     => ny,
      f_i      => f,
      no_i     => no,
      output_o => output,
      zr_o     => zr,
      ng_o     => ng
    );

  main_proc : process is

    variable errors : natural;
    variable failed : boolean;

  begin

    errors := 0;

    for i in TESTS'range loop

      failed := false;

      zx <= TESTS(i).zx;
      zy <= TESTS(i).zy;
      nx <= TESTS(i).nx;
      ny <= TESTS(i).ny;
      f  <= TESTS(i).f;
      no <= TESTS(i).no;

      for j in -2 ** (DATA_WIDTH - 1) to 2 ** (DATA_WIDTH - 1) - 1 loop

        for l in -2 ** (DATA_WIDTH - 1) to 2 ** (DATA_WIDTH - 1) - 1 loop

          x <= to_signed(j, DATA_WIDTH);
          y <= to_signed(l, DATA_WIDTH);
          wait for 1 ns;

          case TESTS(i).name is

            when ZERO =>

              failed := output /= 0;

            when ONE =>

              failed := output /= 1;

            when M_ONE =>

              failed := output /= -1;

            when XX =>

              failed := output /= x;

            when YY =>

              failed := output /= y;

            when NOT_X =>

              failed := output /= not x;

            when NOT_Y =>

              failed := output /= not y;

            when M_X =>

              failed := output /= -x;

            when M_Y =>

              failed := output /= -y;

            when INC_X =>

              failed := output /= x + 1;

            when INC_Y =>

              failed := output /= y + 1;

            when DEC_X =>

              failed := output /= x - 1;

            when DEC_Y =>

              failed := output /= y - 1;

            when ADD =>

              failed := output /= x + y;

            when SUB_X_Y =>

              failed := output /= x - y;

            when SUB_Y_X =>

              failed := output /= y - x;

            when AAND =>

              failed := output /= (x and y);

            when OOR =>

              failed := output /= (x or y);

          end case;

          if ((zr = '1') /= (output = 0)) then
            failed := true;
          end if;

          if ((ng = '1') /= (output < 0)) then
            failed := true;
          end if;

          if (failed) then
            errors := errors + 1;
            report "FAIL " & test_name_t'image(TESTS(i).name)
                   & " x=" & integer'image(j) & " y=" & integer'image(l)
                   & " got=" & integer'image(to_integer(output))
              severity error;
          end if;

        end loop;

      end loop;

    end loop;

    if (errors = 0) then
      report "PASS: all " & integer'image(TESTS'length) & " vectors"
        severity note;
    else
      report integer'image(errors) & " failures"
        severity failure;
    end if;

    wait;

  end process main_proc;

end architecture tb;
