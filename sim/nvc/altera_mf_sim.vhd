-- SPDX-License-Identifier: GPL-2.0-or-later
-- Functional model of altera_mf.altsyncram for nvc simulation.
--
-- rtl/dpram.vhd instantiates altsyncram unconditionally (there is no
-- simulation generate branch like other cores have), so unit tests need a
-- behavioural model, not just an analysis stub. This models the subset the
-- WonderSwan core actually uses: BIDIR_DUAL_PORT, unregistered outputs,
-- NEW_DATA read-during-write on the same port, mixed port widths
-- (dpram_dif), clock enables. init_file is ignored - testbenches must load
-- memories explicitly.
--
-- Analyzed into a library named altera_mf by the sim/run_*.sh scripts.

library ieee;
use ieee.std_logic_1164.all;

package altera_mf_components is

   component altsyncram
      generic
      (
         address_aclr_a                : string  := "NONE";
         address_aclr_b                : string  := "NONE";
         address_reg_b                 : string  := "CLOCK1";
         byte_size                     : natural := 8;
         byteena_aclr_a                : string  := "NONE";
         byteena_aclr_b                : string  := "NONE";
         byteena_reg_b                 : string  := "CLOCK1";
         clock_enable_core_a           : string  := "USE_INPUT_CLKEN";
         clock_enable_core_b           : string  := "USE_INPUT_CLKEN";
         clock_enable_input_a          : string  := "NORMAL";
         clock_enable_input_b          : string  := "NORMAL";
         clock_enable_output_a         : string  := "NORMAL";
         clock_enable_output_b         : string  := "NORMAL";
         indata_aclr_a                 : string  := "NONE";
         indata_aclr_b                 : string  := "NONE";
         indata_reg_b                  : string  := "CLOCK1";
         init_file                     : string  := "UNUSED";
         init_file_layout              : string  := "PORT_A";
         intended_device_family        : string  := "Cyclone V";
         lpm_hint                      : string  := "UNUSED";
         lpm_type                      : string  := "altsyncram";
         maximum_depth                 : natural := 0;
         numwords_a                    : natural := 0;
         numwords_b                    : natural := 0;
         operation_mode                : string  := "BIDIR_DUAL_PORT";
         outdata_aclr_a                : string  := "NONE";
         outdata_aclr_b                : string  := "NONE";
         outdata_reg_a                 : string  := "UNREGISTERED";
         outdata_reg_b                 : string  := "UNREGISTERED";
         power_up_uninitialized        : string  := "FALSE";
         ram_block_type                : string  := "AUTO";
         rdcontrol_aclr_b              : string  := "NONE";
         rdcontrol_reg_b               : string  := "CLOCK1";
         read_during_write_mode_mixed_ports : string := "DONT_CARE";
         read_during_write_mode_port_a : string  := "NEW_DATA_NO_NBE_READ";
         read_during_write_mode_port_b : string  := "NEW_DATA_NO_NBE_READ";
         width_a                       : natural := 1;
         width_b                       : natural := 1;
         width_byteena_a               : natural := 1;
         width_byteena_b               : natural := 1;
         widthad_a                     : natural := 1;
         widthad_b                     : natural := 1;
         wrcontrol_aclr_a              : string  := "NONE";
         wrcontrol_aclr_b              : string  := "NONE";
         wrcontrol_wraddress_reg_b     : string  := "CLOCK1"
      );
      port
      (
         aclr0          : in  std_logic := '0';
         aclr1          : in  std_logic := '0';
         address_a      : in  std_logic_vector(widthad_a - 1 downto 0);
         address_b      : in  std_logic_vector(widthad_b - 1 downto 0) := (others => '0');
         addressstall_a : in  std_logic := '0';
         addressstall_b : in  std_logic := '0';
         byteena_a      : in  std_logic_vector(width_byteena_a - 1 downto 0) := (others => '1');
         byteena_b      : in  std_logic_vector(width_byteena_b - 1 downto 0) := (others => '1');
         clock0         : in  std_logic := '1';
         clock1         : in  std_logic := '1';
         clocken0       : in  std_logic := '1';
         clocken1       : in  std_logic := '1';
         clocken2       : in  std_logic := '1';
         clocken3      : in  std_logic := '1';
         data_a         : in  std_logic_vector(width_a - 1 downto 0) := (others => '0');
         data_b         : in  std_logic_vector(width_b - 1 downto 0) := (others => '0');
         eccstatus      : out std_logic_vector(2 downto 0);
         q_a            : out std_logic_vector(width_a - 1 downto 0);
         q_b            : out std_logic_vector(width_b - 1 downto 0);
         rden_a         : in  std_logic := '1';
         rden_b         : in  std_logic := '1';
         wren_a         : in  std_logic := '0';
         wren_b         : in  std_logic := '0'
      );
   end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity altsyncram is
   generic
   (
      address_aclr_a                : string  := "NONE";
      address_aclr_b                : string  := "NONE";
      address_reg_b                 : string  := "CLOCK1";
      byte_size                     : natural := 8;
      byteena_aclr_a                : string  := "NONE";
      byteena_aclr_b                : string  := "NONE";
      byteena_reg_b                 : string  := "CLOCK1";
      clock_enable_core_a           : string  := "USE_INPUT_CLKEN";
      clock_enable_core_b           : string  := "USE_INPUT_CLKEN";
      clock_enable_input_a          : string  := "NORMAL";
      clock_enable_input_b          : string  := "NORMAL";
      clock_enable_output_a         : string  := "NORMAL";
      clock_enable_output_b         : string  := "NORMAL";
      indata_aclr_a                 : string  := "NONE";
      indata_aclr_b                 : string  := "NONE";
      indata_reg_b                  : string  := "CLOCK1";
      init_file                     : string  := "UNUSED";
      init_file_layout              : string  := "PORT_A";
      intended_device_family        : string  := "Cyclone V";
      lpm_hint                      : string  := "UNUSED";
      lpm_type                      : string  := "altsyncram";
      maximum_depth                 : natural := 0;
      numwords_a                    : natural := 0;
      numwords_b                    : natural := 0;
      operation_mode                : string  := "BIDIR_DUAL_PORT";
      outdata_aclr_a                : string  := "NONE";
      outdata_aclr_b                : string  := "NONE";
      outdata_reg_a                 : string  := "UNREGISTERED";
      outdata_reg_b                 : string  := "UNREGISTERED";
      power_up_uninitialized        : string  := "FALSE";
      ram_block_type                : string  := "AUTO";
      rdcontrol_aclr_b              : string  := "NONE";
      rdcontrol_reg_b               : string  := "CLOCK1";
      read_during_write_mode_mixed_ports : string := "DONT_CARE";
      read_during_write_mode_port_a : string  := "NEW_DATA_NO_NBE_READ";
      read_during_write_mode_port_b : string  := "NEW_DATA_NO_NBE_READ";
      width_a                       : natural := 1;
      width_b                       : natural := 1;
      width_byteena_a               : natural := 1;
      width_byteena_b               : natural := 1;
      widthad_a                     : natural := 1;
      widthad_b                     : natural := 1;
      wrcontrol_aclr_a              : string  := "NONE";
      wrcontrol_aclr_b              : string  := "NONE";
      wrcontrol_wraddress_reg_b     : string  := "CLOCK1"
   );
   port
   (
      aclr0          : in  std_logic := '0';
      aclr1          : in  std_logic := '0';
      address_a      : in  std_logic_vector(widthad_a - 1 downto 0);
      address_b      : in  std_logic_vector(widthad_b - 1 downto 0) := (others => '0');
      addressstall_a : in  std_logic := '0';
      addressstall_b : in  std_logic := '0';
      byteena_a      : in  std_logic_vector(width_byteena_a - 1 downto 0) := (others => '1');
      byteena_b      : in  std_logic_vector(width_byteena_b - 1 downto 0) := (others => '1');
      clock0         : in  std_logic := '1';
      clock1         : in  std_logic := '1';
      clocken0       : in  std_logic := '1';
      clocken1       : in  std_logic := '1';
      clocken2       : in  std_logic := '1';
      clocken3       : in  std_logic := '1';
      data_a         : in  std_logic_vector(width_a - 1 downto 0) := (others => '0');
      data_b         : in  std_logic_vector(width_b - 1 downto 0) := (others => '0');
      eccstatus      : out std_logic_vector(2 downto 0);
      q_a            : out std_logic_vector(width_a - 1 downto 0);
      q_b            : out std_logic_vector(width_b - 1 downto 0);
      rden_a         : in  std_logic := '1';
      rden_b         : in  std_logic := '1';
      wren_a         : in  std_logic := '0';
      wren_b         : in  std_logic := '0'
   );
end entity;

architecture sim of altsyncram is
   -- one flat bit array, so mixed-width ports (dpram_dif) address the same
   -- storage: port A sees width_a chunks, port B width_b chunks
   constant total_bits : natural := numwords_a * width_a;
begin

   process (clock0, clock1)
      type bitmem_t is array (0 to total_bits - 1) of std_logic;
      variable mem  : bitmem_t := (others => '0');
      variable base : natural;
   begin
      if rising_edge(clock0) and clocken0 = '1' then
         base := to_integer(unsigned(address_a)) * width_a;
         if base + width_a <= total_bits then
            if wren_a = '1' then
               for i in 0 to width_a - 1 loop
                  mem(base + i) := data_a(i);
               end loop;
            end if;
            for i in 0 to width_a - 1 loop      -- NEW_DATA read-during-write
               q_a(i) <= mem(base + i);
            end loop;
         end if;
      end if;
      if rising_edge(clock1) and clocken1 = '1' then
         base := to_integer(unsigned(address_b)) * width_b;
         if base + width_b <= total_bits then
            if wren_b = '1' then
               for i in 0 to width_b - 1 loop
                  mem(base + i) := data_b(i);
               end loop;
            end if;
            for i in 0 to width_b - 1 loop
               q_b(i) <= mem(base + i);
            end loop;
         end if;
      end if;
   end process;

   eccstatus <= (others => '0');

end architecture;
