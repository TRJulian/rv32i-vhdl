--------------------------------------------------------------------------------
-- alu_tb.vhd -- Testbench for the RV32I integer ALU module "alu.vhd"
--
-- Completes a value check and a property check using directed operand set at
-- default width 32, and an exhaustive operand set at default width 6 each.
-- Completes an exhaustive shift sweep at width 32 as well.
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
  use work.alu_pkg.all;

entity alu_tb is
  generic (
    WIDTH_DIRECTED       : positive := 32;
    WIDTH_EXHAUSTIVE     : positive := 6;
    MAX_VALUE_REPORTS    : natural  := 50;
    MAX_PROPERTY_REPORTS : natural  := 50
  );
end entity alu_tb;

architecture tb of alu_tb is

  signal src_a_dir   : std_logic_vector(WIDTH_DIRECTED - 1 downto 0) := (others => '0');
  signal src_b_dir   : std_logic_vector(WIDTH_DIRECTED - 1 downto 0) := (others => '0');
  signal alu_res_dir : std_logic_vector(WIDTH_DIRECTED - 1 downto 0);

  signal src_a_exh   : std_logic_vector(WIDTH_EXHAUSTIVE - 1 downto 0) := (others => '0');
  signal src_b_exh   : std_logic_vector(WIDTH_EXHAUSTIVE - 1 downto 0) := (others => '0');
  signal alu_res_exh : std_logic_vector(WIDTH_EXHAUSTIVE - 1 downto 0);
  signal alu_op      : alu_op_t                                        := alu_op_t'low;

  type int_array_t is array (natural range <>) of integer;

  function full_operand_set (
    w_p : positive
  ) return int_array_t is

    variable full : int_array_t(0 to 2 ** w_p - 1);

  begin

    for k in full'range loop

      full(k) := -2 ** (w_p - 1) + k;

    end loop;

    return full;

  end function full_operand_set;

  function operand_set (
    w_p : positive
  ) return int_array_t is

    variable min_s : signed(w_p - 1 downto 0);
    variable max_s : signed(w_p - 1 downto 0);

  begin

    min_s             := (others => '0');
    max_s             := (others => '1');
    min_s(min_s'high) := '1';
    max_s(max_s'high) := '0';

    if (w_p <= 8) then
      return full_operand_set(w_p);
    else
      return int_array_t'(to_integer(min_s), -1, 0, 1, to_integer(max_s));
    end if;

  end function operand_set;

  procedure check_values (
    constant w_p              : positive;
    variable error_counter_p  : inout natural;
    variable vector_counter_p : inout natural;

    signal src_a_p   : inout std_logic_vector;
    signal src_b_p   : inout std_logic_vector;
    signal alu_res_p : in std_logic_vector;
    signal alu_op_p  : inout alu_op_t
  ) is

    constant OPERANDS : int_array_t := operand_set(w_p);
    variable failed   : boolean;
    variable expected : std_logic_vector(w_p - 1 downto 0);

  begin

    for op in alu_op_t loop

      for a_idx in OPERANDS'range loop

        for b_idx in OPERANDS'range loop

          failed           := false;
          vector_counter_p := vector_counter_p + 1;

          alu_op_p <= op;
          src_a_p  <= std_logic_vector(to_signed(OPERANDS(a_idx), w_p));
          src_b_p  <= std_logic_vector(to_signed(OPERANDS(b_idx), w_p));
          wait for 10 ns;

          case op is

            when OP_ADD =>

              expected := std_logic_vector(signed(src_a_p) + signed(src_b_p));

            when OP_SUB =>

              expected := std_logic_vector(signed(src_a_p) - signed(src_b_p));

            when OP_SLL =>

              expected := std_logic_vector(shift_left(unsigned(src_a_p),
                                                      to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0)))));

            when OP_XOR =>

              expected := src_a_p xor src_b_p;

            when OP_SRL =>

              expected := std_logic_vector(shift_right(unsigned(src_a_p),
                                                       to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0)))));

            when OP_SRA =>

              expected := std_logic_vector(shift_right(signed(src_a_p),
                                                       to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0)))));

            when OP_OR =>

              expected := src_a_p or src_b_p;

            when OP_AND =>

              expected := src_a_p and src_b_p;

          end case;

          if (alu_res_p /= expected) then
            failed := true;
          end if;

          if (failed) then
            error_counter_p := error_counter_p + 1;
            if (error_counter_p <= MAX_VALUE_REPORTS) then
              report "fail alu_op=" & alu_op_t'image(op)
                     & " src_a=" & to_string(OPERANDS(a_idx)) & " src_b=" & to_string(OPERANDS(b_idx))
                     & " expected=" & to_string(expected)
                     & " got=" & to_string(alu_res_p)
                severity error;
            elsif (error_counter_p = MAX_VALUE_REPORTS + 1) then
              report "further failures suppressed..."
                severity note;
            end if;
          end if;

        end loop;

      end loop;

    end loop;

  end procedure check_values;

  procedure check_shift_exh (
    constant w_p              : positive;
    variable error_counter_p  : inout natural;
    variable vector_counter_p : inout natural;

    signal src_a_p   : inout std_logic_vector;
    signal src_b_p   : inout std_logic_vector;
    signal alu_res_p : in std_logic_vector;
    signal alu_op_p  : inout alu_op_t
  ) is

    constant OPERANDS : int_array_t := operand_set(w_p);
    variable failed   : boolean;
    variable expected : std_logic_vector(w_p - 1 downto 0);
    variable op       : alu_op_t;

  begin

    for i in 0 to 2 loop

      case i is

        when 0 =>

          op := OP_SLL;

        when 1 =>

          op := OP_SRL;

        when 2 =>

          op := OP_SRA;

      end case;

      alu_op_p <= op;

      for a_idx in OPERANDS'range loop

        for b_idx in 0 to (2 ** SHAMT_WIDTH - 1) loop

          failed           := false;
          vector_counter_p := vector_counter_p + 1;

          src_a_p <= std_logic_vector(to_signed(OPERANDS(a_idx), w_p));
          src_b_p <= std_logic_vector(to_signed(b_idx, w_p));
          wait for 10 ns;

          case op is

            when OP_SLL =>

              expected := std_logic_vector(shift_left(unsigned(src_a_p),
                                                      to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0)))));

            when OP_SRL =>

              expected := std_logic_vector(shift_right(unsigned(src_a_p),
                                                       to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0)))));

            when OP_SRA =>

              expected := std_logic_vector(shift_right(signed(src_a_p),
                                                       to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0)))));

            when others =>

              expected := (others => 'X');

          end case;

          if (alu_res_p /= expected) then
            failed := true;
          end if;

          if (failed) then
            error_counter_p := error_counter_p + 1;
            if (error_counter_p <= MAX_VALUE_REPORTS) then
              report "fail alu_op=" & alu_op_t'image(alu_op_p)
                     & " src_a=" & to_string(OPERANDS(a_idx)) & " src_b=" & to_string(b_idx)
                     & " expected=" & to_string(expected)
                     & " got=" & to_string(alu_res_p)
                severity error;
            elsif (error_counter_p = MAX_VALUE_REPORTS + 1) then
              report "further failures suppressed..."
                severity note;
            end if;
          end if;

        end loop;

      end loop;

    end loop;

  end procedure check_shift_exh;

  procedure check_shift_properties (
    constant w_p              : positive;
    variable error_counter_p  : inout natural;
    variable vector_counter_p : inout natural;

    signal src_a_p   : inout std_logic_vector;
    signal src_b_p   : inout std_logic_vector;
    signal alu_res_p : in std_logic_vector;
    signal alu_op_p  : inout alu_op_t
  ) is

    constant OPERANDS         : int_array_t := operand_set(w_p);
    variable failed           : boolean;
    variable r_sll            : std_logic_vector(w_p - 1 downto 0);
    variable r_srl            : std_logic_vector(w_p - 1 downto 0);
    variable r_sra            : std_logic_vector(w_p - 1 downto 0);
    variable shamt            : integer;
    variable shift_error_desc : line;

  begin

    for a_idx in OPERANDS'range loop

      for b_idx in OPERANDS'range loop

        failed           := false;
        vector_counter_p := vector_counter_p + 1;

        src_a_p <= std_logic_vector(to_signed(OPERANDS(a_idx), w_p));
        src_b_p <= std_logic_vector(to_signed(OPERANDS(b_idx), w_p));

        alu_op_p <= OP_SLL;
        wait for 1 ns;
        r_sll    := alu_res_p;

        alu_op_p <= OP_SRL;
        wait for 1 ns;
        r_srl    := alu_res_p;

        alu_op_p <= OP_SRA;
        wait for 1 ns;
        r_sra    := alu_res_p;

        shamt := minimum(to_integer(unsigned(src_b_p(SHAMT_WIDTH - 1 downto 0))), w_p);

        if ((shamt = 0) or (unsigned(src_a_p) = 0)) then
          if (not ((r_sll = r_srl) and (r_sll = r_sra))) then
            failed := true;
            write(shift_error_desc, string'("SLL/SRL/SRA don't agree while a or shamt = 0, "));
          end if;
        else
          if (unsigned(r_sll((shamt - 1) downto 0)) /= 0) then
            failed := true;
            write(shift_error_desc, string'("SLL: shamt lower bits of res /= 0, "));
          end if;
          if (unsigned(r_srl(r_srl'high downto (r_srl'high - (shamt - 1)))) /= 0) then
            failed := true;
            write(shift_error_desc, string'("SRL: shamt higher bits of res /= 0, "));
          end if;
          if (not ((and r_sra(r_sra'high downto r_sra'high - shamt + 1)) = src_a_p(src_a_p'high)
                   and (or r_sra(r_sra'high downto r_sra'high - shamt + 1)) = src_a_p(src_a_p'high))) then
            failed := true;
            write(shift_error_desc, string'("SRA: shamt higher bits or res /= msb of a, "));
          end if;
        end if;

        if (failed) then
          error_counter_p := error_counter_p + 1;
          if (error_counter_p <= MAX_PROPERTY_REPORTS) then
            report shift_error_desc.all &
                   "src_a=" & to_string(OPERANDS(a_idx)) & ", src_b=" & to_string(OPERANDS(b_idx))
                   & ", src_b(" & integer'image(SHAMT_WIDTH - 1) & " downto 0)="
                   & integer'image(to_integer(unsigned(to_signed(OPERANDS(b_idx), w_p)(SHAMT_WIDTH - 1 downto 0))))
                   & " r_sll=" & to_string(r_sll)
                   & " r_srl=" & to_string(r_srl)
                   & " r_sra=" & to_string(r_sra)
              severity error;
          elsif (error_counter_p = MAX_PROPERTY_REPORTS + 1) then
            report "further failures suppressed..."
              severity note;
          end if;
        end if;

        deallocate(shift_error_desc);

      end loop;

    end loop;

  end procedure check_shift_properties;

begin

  u_alu_dir : entity work.alu(rtl)
    generic map (
      WIDTH => WIDTH_DIRECTED
    )
    port map (
      src_a_i   => src_a_dir,
      src_b_i   => src_b_dir,
      alu_op_i  => alu_op,
      alu_res_o => alu_res_dir
    );

  u_alu_exh : entity work.alu(rtl)
    generic map (
      WIDTH => WIDTH_EXHAUSTIVE
    )
    port map (
      src_a_i   => src_a_exh,
      src_b_i   => src_b_exh,
      alu_op_i  => alu_op,
      alu_res_o => alu_res_exh
    );

  stim_proc : process is

    variable error_counter           : natural;
    variable value_vector_counter    : natural;
    variable property_vector_counter : natural;

  begin

    error_counter           := 0;
    value_vector_counter    := 0;
    property_vector_counter := 0;

    check_values(w_p      => WIDTH_DIRECTED, src_a_p => src_a_dir, src_b_p => src_b_dir, alu_res_p => alu_res_dir,
                 alu_op_p => alu_op, error_counter_p => error_counter, vector_counter_p => value_vector_counter);
    check_values(w_p      => WIDTH_EXHAUSTIVE, src_a_p => src_a_exh, src_b_p => src_b_exh, alu_res_p => alu_res_exh,
                 alu_op_p => alu_op, error_counter_p => error_counter, vector_counter_p => value_vector_counter);
    check_shift_properties(w_p              => WIDTH_DIRECTED, src_a_p => src_a_dir, src_b_p => src_b_dir,
                           alu_res_p        => alu_res_dir, alu_op_p => alu_op, error_counter_p => error_counter,
                           vector_counter_p => property_vector_counter);
    check_shift_properties(w_p              => WIDTH_EXHAUSTIVE, src_a_p => src_a_exh, src_b_p => src_b_exh,
                           alu_res_p        => alu_res_exh, alu_op_p => alu_op, error_counter_p => error_counter,
                           vector_counter_p => property_vector_counter);
    check_shift_exh(w_p      => WIDTH_DIRECTED, src_a_p => src_a_dir, src_b_p => src_b_dir, alu_res_p => alu_res_dir,
                    alu_op_p => alu_op, error_counter_p => error_counter, vector_counter_p => value_vector_counter);

    if (error_counter = 0) then
      report "pass: all " & integer'image(value_vector_counter) & " value vectors "
             & " and all " & integer'image(property_vector_counter) & " property vectors "
        severity note;
    else
      report integer'image(error_counter) & " failures"
        severity error;
    end if;

    wait;

  end process stim_proc;

end architecture tb;
