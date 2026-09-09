--------------------------------------------------------------------------------
-- rv32i_pkg.vhd -- Package for the modules of the rv32i core.
--------------------------------------------------------------------------------

package rv32i_pkg is

  type alu_op_t is (ALU_ADD, ALU_SUB, ALU_SLL, ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND);

  type cmp_op_t is (CMP_EQ, CMP_NE, CMP_LT, CMP_GE, CMP_LTU, CMP_GEU);

  -- RV32I: shifts use the low 5 bits of the second operand.
  constant SHAMT_WIDTH : positive := 5;

  subtype alu_width_t is positive range SHAMT_WIDTH to positive'high;

end package rv32i_pkg;
