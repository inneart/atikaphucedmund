library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity int_rom is
port(
		clk      : in  std_logic;
		rst      : in  std_logic; -- Reset PIN
		rd       : in  std_logic; -- Read PIN (1 or 0)
		addr     : in  std_logic_vector (15 downto 0); -- Address
		data     : out std_logic_vector (7 downto 0) -- Output data
);
end int_rom;

architecture Behavioral of int_rom is
	type rom_type is array (0 to 4095) of STD_LOGIC_VECTOR (7 downto 0);
	constant PROGRAM : ROM_TYPE := (

	"11101001", --LABEL1: MOV A,R1
	"00100100", --ADD A,#01H
	"00000001",
	"11111001", --MOV R1,A
	"10111001", --CJNE R1,#04H,LABEL1
	"00000100",
	"11111001",
	"10001001", --MOV 90H,R1
	"10010000",
	others => "00000000"
);

	begin

	process (rst, rd, addr)
	begin
		if( rst = '1' ) then
			data <= "0000000";	-- If reset, output data = 0H
		elsif( rd = '1' ) then
			data <= PROGRAM(conv_integer(addr)); -- If read, output data = int(result_A)
		else
			data <= "--------";	-- If no read, do nothing.
		end if;
	end process;
end Behavioral;
