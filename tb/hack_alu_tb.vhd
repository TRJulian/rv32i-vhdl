library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity hack_alu_tb is
  generic (
    DATA_WIDTH : positive := 4
  );
end entity hack_alu_tb;

architecture tb of hack_alu_tb is

  signal x      : signed(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal y      : signed(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal zx     : std_logic                       := '0';
  signal zy     : std_logic                       := '0';
  signal nx     : std_logic                       := '0';
  signal ny     : std_logic                       := '0';
  signal f      : std_logic                       := '0';
  signal no     : std_logic                       := '0';
  signal output : signed(DATA_WIDTH - 1 downto 0);
  signal zr     : std_logic;
  signal ng     : std_logic;

  type test_name_t is (
    ZERO, ONE, M_ONE, XX, YY, NOT_X, NOT_Y,
    M_X, M_Y, INC_X, INC_Y, DEC_X, DEC_Y,
    ADD, SUB_X_Y, SUB_Y_X, AAND, OOR
  );

  type int_array_t is array (natural range <>) of integer;

  function operand_set (
    w : positive
  ) return int_array_t is

    variable full : int_array_t(0 to 2 ** w - 1);

  begin

    if (w <= 5) then

      for k in full'range loop

        full(k) := -2 ** (w - 1) + k;

      end loop;

      return full;
    else
      return int_array_t'(-2 ** (w - 1), -1, 0, 1, 2 ** (w - 1) - 1);
    end if;

  end function operand_set;

  constant OPERANDS : int_array_t := operand_set(DATA_WIDTH);

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

  u_alu : entity work.hack_alu(rtl)
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

    variable errors         : natural;
    variable failed         : boolean;
    variable vector_counter : natural;
    variable expected       : signed(DATA_WIDTH - 1 downto 0);

  begin

    errors         := 0;
    vector_counter := 0;

    for i in TESTS'range loop

      failed := false;

      zx <= TESTS(i).zx;
      zy <= TESTS(i).zy;
      nx <= TESTS(i).nx;
      ny <= TESTS(i).ny;
      f  <= TESTS(i).f;
      no <= TESTS(i).no;

      for j in OPERANDS'range loop

        for l in OPERANDS'range loop

          vector_counter := vector_counter + 1;

          x <= to_signed(OPERANDS(j), DATA_WIDTH);
          y <= to_signed(OPERANDS(l), DATA_WIDTH);
          wait for 1 ns;

          case TESTS(i).name is

            when ZERO =>

              expected := to_signed(0, DATA_WIDTH);

            when ONE =>

              expected := to_signed(1, DATA_WIDTH);

            when M_ONE =>

              expected := to_signed(-1, DATA_WIDTH);

            when XX =>

              expected := x;

            when YY =>

              expected := y;

            when NOT_X =>

              expected := not x;

            when NOT_Y =>

              expected := not y;

            when M_X =>

              expected := -x;

            when M_Y =>

              expected := -y;

            when INC_X =>

              expected := x + 1;

            when INC_Y =>

              expected := y + 1;

            when DEC_X =>

              expected := x - 1;

            when DEC_Y =>

              expected := y - 1;

            when ADD =>

              expected := x + y;

            when SUB_X_Y =>

              expected := x - y;

            when SUB_Y_X =>

              expected := y - x;

            when AAND =>

              expected := (x and y);

            when OOR =>

              expected := (x or y);

          end case;

          if (output /= expected) then
            failed := true;
          end if;

          if ((zr = '1') /= (output = 0)) then
            failed := true;
          end if;

          if ((ng = '1') /= (output < 0)) then
            failed := true;
          end if;

          if (failed) then
            errors := errors + 1;
            report "FAIL " & test_name_t'image(TESTS(i).name)
                   & " x=" & integer'image(OPERANDS(j)) & " y=" & integer'image(OPERANDS(l))
                   & " expected=" & integer'image(to_integer(expected))
                   & " got=" & integer'image(to_integer(output))
              severity error;
          end if;

        end loop;

      end loop;

    end loop;

    if (errors = 0) then
      report "PASS: all " & integer'image(vector_counter) & " vectors"
        severity note;
    else
      report integer'image(errors) & " failures"
        severity failure;
    end if;

    wait;

  end process main_proc;

end architecture tb;
