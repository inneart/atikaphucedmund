library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.constants.all;

entity sequencer2 is
    port(
		rst              : in  std_logic;
		clk              : in  std_logic;
		ale				 : out std_logic;
		psen			 : out std_logic;

		alu_op_code	 	 : out  std_logic_vector (3 downto 0);
		alu_src_1L		 : out  std_logic_vector (7 downto 0);
		alu_src_1H		 : out  std_logic_vector (7 downto 0);
		alu_src_2L		 : out  std_logic_vector (7 downto 0);
		alu_src_2H		 : out  std_logic_vector (7 downto 0);
		alu_by_wd		 : out  std_logic;            			 -- byte(0)/word(1) instruction
		alu_cy_bw		 : out  std_logic;             			 -- carry/borrow bit
		alu_ans_L		 : in std_logic_vector (7 downto 0);
		alu_ans_H		 : in std_logic_vector (7 downto 0);
		alu_cy		 	 : in std_logic;             				 -- carry out of bit 7/15
		alu_ac		 	 : in std_logic;		    					 -- carry out of bit 3/7
		alu_ov		 	 : in std_logic;		    					 -- overflow

		dividend_i		 : out  std_logic_vector(15 downto 0);
		divisor_i		 : out  std_logic_vector(15 downto 0);
		quotient_o		 : in std_logic_vector(15 downto 0); 
		remainder_o	 	 : in std_logic_vector(15 downto 0);
		div_done		 : in std_logic ;

		mul_a_i		 	 : out  std_logic_vector(15 downto 0);  -- Multiplicand
		mul_b_i		 	 : out  std_logic_vector(15 downto 0);  -- Multiplicator
		mul_prod_o 	 	 : in std_logic_vector(31 downto 0) ;	 -- Product

		i_ram_wrByte     : out std_logic; 
		i_ram_wrBit   	 : out std_logic; 
		i_ram_rdByte     : out std_logic; 
		i_ram_rdBit   	 : out std_logic; 
		i_ram_addr 	 	 : out std_logic_vector(7 downto 0); 
		i_ram_diByte  	 : out std_logic_vector(7 downto 0); 
		i_ram_diBit   	 : out std_logic; 
		i_ram_doByte     : in std_logic_vector(7 downto 0); 
		i_ram_doBit   	 : in std_logic; 
		
		i_rom_addr       : out std_logic_vector (15 downto 0);
		i_rom_data       : in  std_logic_vector (7 downto 0);
		i_rom_rd         : out std_logic;
		
		pc_debug	 	 : out std_logic_vector (15 downto 0);
		interrupt_flag	 : in  std_logic_vector (2 downto 0);
		erase_flag	 	 : out std_logic);

end sequencer2;

-------------------------------------------------------------------------------

architecture seq_arch of sequencer2 is

    type t_cpu_state is (T0, T1, I0); --these determine whether you are in initialisation state, normal execution state, etc
    type t_exe_state is (E0, E1, E2, E3, E4, E5, E6, E7, E8, E9, E10); --these are the equivalence T0, T1 in the lecture
    
	signal cpu_state 		: t_cpu_state;
    signal exe_state 		: t_exe_state;
    signal IR				: std_logic_vector(7 downto 0);		-- Instruction Register
	signal PC				: std_logic_vector(15 downto 0);	-- Program Counter
	--signal AR				: std_logic_vector(7 downto 0);		-- Address Register
	signal DR				: std_logic_vector(7 downto 0);		-- Data Register
	signal int_hold			: std_logic;
	
	
	begin
    process(rst, clk)
	variable decodedOP	:	std_logic_vector(2 downto 0);  --declare VARIABLES IN PROCESS, before BEGIN!!
    begin
	 
    if( rst = '1' ) then
	 
   	cpu_state <= T0;
		exe_state <= E0;	 
		ale <= '0';
		psen <= '0';
		mul_a_i <= (others => '0');
		mul_b_i <= (others => '0');
		dividend_i <= (others => '0'); 
		divisor_i <= (others => '1');
		i_ram_wrByte <= '0'; 
		i_ram_rdByte <= '0'; 
		i_ram_wrBit <= '0'; 
		i_ram_rdBit <= '0';
		IR <= (others => '0');
		PC <= (others => '0');
		--PC <= "0000000000100111";
		--AR <= (others => '0');
		DR <= (others => '0');
		pc_debug <= (others => '1');
		int_hold <= '0';
		erase_flag <= '0';	
		
    --START!
	elsif (clk'event and clk = '1') then
    case cpu_state is
		
		when T0 =>
			case exe_state is
				when E0	=>
					
					i_rom_rd <= '1';   --Set rom's read pin to 1
					i_rom_addr <= PC;  --Put address of next instruction into rom's address
						
					exe_state<=E1;
					
				when E1	=> 
				
					IR <= i_rom_data;	--Put instruction into IR
					PC<=PC+"00000001";   
					
					exe_state <= E0;
					cpu_state <= T1;
					
				when others =>
					
			end case;  

		when T1 =>
			case IR is 
				
				-- NOP
			when "00000000"  =>
				
				case exe_state is
					when E0	=>  
						exe_state <= E1;
						
					when E1	=>
						exe_state <= E2;
						
					when E2	=>
						exe_state <= E3;
						
					when E3	=>
						exe_state <= E4;
						
					when E4	=>
						exe_state <= E5;
						
					when E5	=>
						exe_state <= E6;
						
					when E6	=>
						exe_state <= E7;
						
					when E7	=>
						exe_state <= E8;
						
					when E8	=>
						exe_state <= E9;											
							
					when E9	=>			

						exe_state <= E0;
						cpu_state <= T0;
						
					when others => --other states?
				end case;  
				
			-- ADD A,Rn
			when "00101000"  =>  --ADD R0 to ACC
				
				case exe_state is
					
					when E0 =>
						
						i_ram_rdByte <= '1';
						i_ram_addr <= xE0;
						
						exe_state <= E1;
						
					when E1 => 	
					
						alu_src_1L <= i_ram_doByte;
						i_ram_addr <= x08;
						
						exe_state <= E2;
						
					when E2 =>
					
						alu_src_2L <= i_ram_doByte;
						i_ram_rdByte <= '0';
						
						exe_state <= E3;
						
					when E3 =>
					
						alu_by_wd <= '0';
						alu_op_code <= ALU_OPC_ADD;
						
						exe_state <= E4;
						
					when E4 =>
					
						if (alu_ac = '1') then
							--set carry flag to 1
							
						i_ram
						alu_ans_L						
			
			when others =>
			--other instructions?
				
			end case;
--				............
--				............
--				............
--				............
--				............
--				............
--				............
--				............
--				............
--				............
--				............
--				............
--
--
--				............
--				............
--				............
--				............
--				............
--				............




		when others => --other CPU state???? 
						exe_state <= E0;	
						cpu_state <= T0;
    
	end case; --cpu_state

end if;
	end process;
end seq_arch;

-------------------------------------------------------------------------------

-- end of file --
