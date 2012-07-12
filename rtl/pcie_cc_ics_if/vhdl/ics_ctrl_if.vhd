library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity ics_ctrl_if is
    port (
        mgt_clksel      : out std_logic;
        clk             : in  std_logic;
        --ICS PLL 2
        strobe          : out std_logic;
        pload           : out std_logic;
        sdata           : out std_logic;
        sclock          : out std_logic
);
end ics_ctrl_if;

architecture behavioral of ics_ctrl_if is

type state is (
s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD,sE, sF, 
s10,s11, s12, s13, s14, s15, s16, s17, s18, s19, s1A, s1B, s1C, s1D, s1E, s1F);

signal next_state     : state;

signal pll_value      : std_logic_vector (10 downto 0) := "10001000001";

signal strobe_sig     : std_logic;
signal pload_sig      : std_logic;
signal sdata_sig      : std_logic;
signal sclock_sig     : std_logic;

signal resetcnt         : std_logic_vector(4 downto 0);
signal reset            : std_logic := '1';

begin
strobe <= strobe_sig;
sdata <= sdata_sig;
pload <= pload_sig;

-- PLOAD signal is not used in this design but the user
-- can perform a PLOAD on the board by pushing the button on the board
-- the PLOAD value will over ride until another serial configurtion of the PLL is performed
pload_sig <= '0';
sclock <= sclock_sig;

-- Control output port SATA_MGT_CLKSEL on FPGA pin H15:
-- (= 0) selects the fixed 125 MHz oscillator output
-- (= 1) selects the variable-frequency Clock Synthesizer 2 output
-- as the clock source for the differential global clock inputs on FPGA
-- pins J20 and J21.
mgt_clksel <= '1';

--
-- Internal reset counter
--
process (clk)
begin
    if rising_edge(clk) then
        if (resetcnt(4) = '1') then
            reset <= '0';
        else
            resetcnt <= resetcnt + '1';
            reset <= '1';
        end if;
    end if;
end process;

process (reset, clk)
begin
    if (reset = '1') then
        next_state <= s0;
        strobe_sig <= '0';
        sdata_sig <= '0';
        sclock_sig <= '0';
    elsif clk'event and clk = '1' then
        case (next_state) is
            when s0 =>
                strobe_sig <= '0';
                sdata_sig <= '0';
                sclock_sig <= '0';
                next_state <= s1;
            when s1 =>
                strobe_sig <= '0';
                sdata_sig <= '0';
                sclock_sig <= '0';
                next_state <= s2;
            when s2 => 
                strobe_sig <= '0';
                sdata_sig <= '1';
                sclock_sig <= '0';
                next_state <= s3;
                -- First Bit don't care
            when s3 => 
                strobe_sig <= '0';
                sdata_sig <= '1';
                sclock_sig <= '1';
                next_state <= s4;
                -- Toggle clock
            when s4 => 
                strobe_sig <= '0';
                sdata_sig <= '0';
                sclock_sig <= '0';
                next_state <= s5;
                -- Second Bit don't care
            when s5 => 
                strobe_sig <= '0';
                sdata_sig <= '0';
                sclock_sig <= '1';
                next_state <= s6;
                -- Toggle clock
            when s6 => 
                strobe_sig <= '0';
                sdata_sig <= '1';
                sclock_sig <= '0';
                next_state <= s7;
                -- Third bit don't care
            when s7 => 
                strobe_sig <= '0';
                sdata_sig <= '1';
                sclock_sig <= '1';
                next_state <= s8;
                -- toggle clock
            when s8 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(0);
                sclock_sig <= '0';
                next_state <= s9;
                --Fourth bit N1 value
            when s9 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(0);
                sclock_sig <= '1';
                next_state <= sA;
                -- togle clock
            when sA => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(1);
                sclock_sig <= '0';
                next_state <= sB;
                --Fith bit N0 value
            when sB => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(1);
                sclock_sig <= '1';
                next_state <= sC;
                --toggle clock
            when sC => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(2);
                sclock_sig <= '0';
                next_state <= sD;
                --Sixth bit M8 value
            when sD => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(2);
                sclock_sig <= '1';
                next_state <= sE;
                -- togle clock
            when sE => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(3);
                sclock_sig <= '0';
                next_state <= sF;
                --Seventh bit M7 value
            when sF => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(3);
                sclock_sig <= '1';
                next_state <= s10;
                -- togle clock
            when s10 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(4);
                sclock_sig <= '0';
                next_state <= s11;
                --Eighth bit M6 value

            when s11 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(4);
                sclock_sig <= '1';
                next_state <= s12;
                -- togle clock
            when s12 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(5);
                sclock_sig <= '0';
                next_state <= s13;
                --ninth bit M5 value
            when s13 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(5);
                sclock_sig <= '1';
                next_state <= s14;
                -- togle clock
            when s14 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(6);
                sclock_sig <= '0';
                next_state <= s15;
                --Tenth bit M4 value
            when s15 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(6);
                sclock_sig <= '1';
                next_state <= s16;
                -- togle clock
            when s16 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(7);
                sclock_sig <= '0';
                next_state <= s17;
                --eleventh bit M3 value
            when s17 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(7);
                sclock_sig <= '1';
                next_state <= s18;
                -- togle clock
            when s18 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(8);
                sclock_sig <= '0';
                next_state <= s19;
                --twelfth bit M2 value
            when s19 => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(8);
                sclock_sig <= '1';
                next_state <= s1A;
                -- togle clock
            when s1A => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(9);
                sclock_sig <= '0';
                next_state <= s1B;
                --Thirtenth bit M1 value
            when s1B => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(9);
                sclock_sig <= '1';
                next_state <= s1C;
                -- togle clock
            when s1C => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(10);
                sclock_sig <= '0';
                next_state <= s1D;
                --fourtenth bit M0 value
            when s1D => 
                strobe_sig <= '0';
                sdata_sig <= pll_value(10);
                sclock_sig <= '1';
                next_state <= s1E;
                -- togle clock
            when s1E =>
                strobe_sig <= '1';
                sdata_sig <= '0';
                sclock_sig <= '0';
                next_state <= s1F;
            when s1F =>
                strobe_sig <= '0';
                sdata_sig <= '0';
                sclock_sig <= '0';
                --deassert strobe_sig and stop process must deassert reconfigure pll to leave state
        end case;
    end if;
end process;

end behavioral;
