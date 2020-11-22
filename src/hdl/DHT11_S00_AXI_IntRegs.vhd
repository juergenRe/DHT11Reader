library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DHT11_S00_AXI_IntRegs is
	generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;                   -- Width of S_AXI data bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 5;                    -- Width of S_AXI address bus
		C_NUM_OF_INTR	    : integer	:= 2;                    -- Number of Interrupts
		C_INTR_SENSITIVITY	: std_logic_vector	:= x"FFFFFFFF";  -- Each bit corresponds to Sensitivity of interrupt :  0 - EDGE, 1 - LEVEL
		C_INTR_ACTIVE_STATE	: std_logic_vector	:= x"FFFFFFFF";  -- Each bit corresponds to Sub-type of INTR: [0 - FALLING_EDGE, 1 - RISING_EDGE : if C_INTR_SENSITIVITY is EDGE(0)] and [ 0 - LEVEL_LOW, 1 - LEVEL_LOW : if C_INTR_SENSITIVITY is LEVEL(1) ]
		C_IRQ_SENSITIVITY	: integer	:= 1;                    -- Sensitivity of IRQ: 0 - EDGE, 1 - LEVEL
		C_IRQ_ACTIVE_STATE	: integer	:= 1                     -- Sub-type of IRQ: [0 - FALLING_EDGE, 1 - RISING_EDGE : if C_IRQ_SENSITIVITY is EDGE(0)] and [ 0 - LEVEL_LOW, 1 - LEVEL_LOW : if C_IRQ_SENSITIVITY is LEVEL(1) ]
	);
	port (
        USER_INTR           : in std_logic_vector(C_NUM_OF_INTR-1 downto 0);      -- main interrupt input lines: [0]: data available [1]: device ready
		irq	                : out std_logic;                                      -- interrupt out port

		S_AXI_ACLK	        : in std_logic;
		S_AXI_ARESETN	    : in std_logic;
		S_AXI_WDATA         : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        axi_awaddr          : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);   
        axi_araddr          : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        den_w               : in std_logic;
        den_r               : in std_logic;
        reg_int_out         : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
	);
end DHT11_S00_AXI_IntRegs;

architecture arch_imp of DHT11_S00_AXI_IntRegs is

	
	--------------------------------------------------
	---- Signals for Interrupt register space 
	--------------------------------------------------
	---- Number of Slave Registers 5
	-- Addressing scheme:
	-- 00:     R/W Global interrupt enable/disable (Bit 0)
	-- 04:     R/W specific interrupt enable/disable according # of interrupts set
	-- 08:     RO  activation status of specific interrupts 
	-- 0C:     R/W specific interrupt acknowledge by writing '1'
	-- 10:     RO  pending status of specific interrupts
	--
	signal reg_global_intr_en  : std_logic_vector(0 downto 0);           
	signal reg_intr_en	       : std_logic_vector(C_NUM_OF_INTR-1 downto 0);        
	signal reg_intr_sts	       : std_logic_vector(C_NUM_OF_INTR-1 downto 0);        
	signal reg_intr_ack	       : std_logic_vector(C_NUM_OF_INTR-1 downto 0);        
	signal reg_intr_pending    : std_logic_vector(C_NUM_OF_INTR-1 downto 0);        
	                                                                            
	signal intr	               : std_logic_vector(C_NUM_OF_INTR-1 downto 0);                
	signal det_intr            : std_logic_vector(C_NUM_OF_INTR-1 downto 0);                
	                                                                            
	signal intr_reg_rden	  : std_logic;                                          
	signal intr_reg_wren	  : std_logic;                                          
	signal reg_data_out	      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);    
	 	                                                                         
	signal intr_all           : std_logic;                                          
	signal intr_ack_all       : std_logic;                                          
	signal s_irq              : std_logic;                                          
	signal intr_all_ff        : std_logic;                                          
	signal intr_ack_all_ff    : std_logic;                                          
	signal aw_en	          : std_logic;                                                 

--    -- demo signal
--	signal intr_counter       : std_logic_vector(3 downto 0);                       

	function or_reduction (vec : in std_logic_vector) return std_logic is           
	  variable res_v : std_logic := '0';  -- Null vec vector will also return '1'   
	  begin                                                                         
	  for i in vec'range loop                                                       
	    res_v := res_v or vec(i);                                                   
	  end loop;                                                                     
	  return res_v;                                                                 
	end function;                                                                   
begin
	
	intr <= USER_INTR;
	
	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	gen_intr_reg  : for i in 0 to (C_NUM_OF_INTR - 1) generate                      
	begin                                                                           

      -- enabling/disabling global interrupt using bit 0	                                                                                
	  process (S_AXI_ACLK)                                                          
	  begin                                                                         
	    if rising_edge(S_AXI_ACLK) then                                             
	      if S_AXI_ARESETN = '0' then                                               
	        reg_global_intr_en <= (others => '0');	                               
	      else                                                                      
	        if (den_w = '1' and axi_awaddr(4 downto 2) = "000") then      
	          reg_global_intr_en(0) <= S_AXI_WDATA(0);                              
	        end if;                                                                 
	      end if;                                                                   
	    end if;                                                                     
	  end process;                                                                  
	                                                                                
      -- generate the specific interrupt enable/disable line	                                                                                
	  process (S_AXI_ACLK)                                                          
	  begin                                                                         
	    if rising_edge(S_AXI_ACLK) then                                             
	      if S_AXI_ARESETN = '0' then                                               
	        reg_intr_en(i) <= '0';	                                               
	      else                                                                      
	        if (den_w = '1' and axi_awaddr(4 downto 2) = "001") then      
	          reg_intr_en(i) <= S_AXI_WDATA(i);                                     
	        end if;                                                                 
	      end if;                                                                   
	    end if;                                                                     
	  end process;                                                                  
	                                                                                
      -- store detected interrupts here, even they will not be propagated yet if not enabled
	  process (S_AXI_ACLK)                                                          
	  begin                                                                         
	    if rising_edge(S_AXI_ACLK) then                                             
	      if (S_AXI_ARESETN = '0' or  reg_intr_ack(i) = '1') then                   
	        reg_intr_sts(i) <= '0';	                                               
	      else                                                                      
	        reg_intr_sts(i) <= det_intr(i);                                         
	      end if;                                                                   
	    end if;                                                                     
	  end process;                                                                  
	                                                                                
	                                                                                
      -- generate the specific interrupt acknowledge line connection 	                                                                                
	  process (S_AXI_ACLK)                                                          
	  begin                                                                         
	    if rising_edge(S_AXI_ACLK) then                                             
	      if (S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then                    
	        reg_intr_ack(i) <= '0';	                                               
	      else                                                                      
	        if (den_w = '1' and axi_awaddr(4 downto 2) = "011") then      
	          reg_intr_ack(i) <= S_AXI_WDATA(i);                                    
	        end if;                                                                 
	      end if;                                                                   
	    end if;                                                                     
	  end process;                                                                  
	                                                                                
      -- pending interrupts will show up only when enabled	                                                                                
	  process (S_AXI_ACLK)                                                          
	  begin                                                                         
	    if rising_edge(S_AXI_ACLK) then                                             
	      if (S_AXI_ARESETN = '0' or  reg_intr_ack(i) = '1') then                   
	        reg_intr_pending(i) <= '0';	                                           
	      else                                                                      
	          reg_intr_pending(i) <= reg_intr_sts(i) and reg_intr_en(i);            
	      end if;                                                                   
	    end if;                                                                     
	  end process;                                                                  
	end generate gen_intr_reg;                                                      

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.

    -- Generate logic when we use 32bit of interrupts
	RDATA_INTR_NUM_32: if (C_NUM_OF_INTR=32) generate                                   
	  begin                                                                             
	                                                                                    
        process (reg_global_intr_en, reg_intr_en, reg_intr_sts, reg_intr_ack, reg_intr_pending, axi_araddr, S_AXI_ARESETN)
          variable loc_addr : std_logic_vector(2 downto 0);                                  
        begin                                                                               
          if S_AXI_ARESETN = '0' then                                                       
            reg_data_out  <= (others => '0');                                               
          else                                                                              
            -- Address decoding for reading registers                                       
            loc_addr := axi_araddr(4 downto 2);                                             
            case loc_addr is                                                                
              when "000" =>                                                               
                reg_data_out <= x"0000000" & "000" & reg_global_intr_en(0);             
              when "001" =>                                                               
                reg_data_out <= reg_intr_en;                                                
              when "010" =>                                                               
                reg_data_out <= reg_intr_sts;                                               
              when "011" =>                                                               
                reg_data_out <= reg_intr_ack;                                               
              when "100" =>                                                               
                reg_data_out <= reg_intr_pending;                                           
              when others =>                                                                
                reg_data_out  <= (others => '0');                                           
            end case;                                                                       
          end if;                                                                           
        end process;                                                                                                                                                            
	end generate RDATA_INTR_NUM_32;                                                     
	                                                                                    
    -- Generate logic when we use less than 32bit of interrupts (usual case)
	RDATA_INTR_NUM_LESS_32: if (C_NUM_OF_INTR/=32) generate                             
	  begin                                                                             
	                                                                                    
        process (reg_global_intr_en, reg_intr_en, reg_intr_sts, reg_intr_ack, reg_intr_pending, axi_araddr, S_AXI_ARESETN)
          variable loc_addr : std_logic_vector(2 downto 0);                                  
          variable zero     : std_logic_vector (C_S_AXI_DATA_WIDTH-C_NUM_OF_INTR-1 downto 0);   
        begin                                                                               
          if S_AXI_ARESETN = '0' then                                                       
            reg_data_out  <= (others => '0');                                               
            zero := (others=>'0');                                                          
          else                                                                              
            zero := (others=>'0');                                                          
            -- Address decoding for reading registers                                       
            loc_addr := axi_araddr(4 downto 2);                                             
            case loc_addr is                                                                
              when "000" =>                                                               
                reg_data_out <= x"0000000" & "000" & reg_global_intr_en(0);             
              when "001" =>                                                               
                reg_data_out <= zero & reg_intr_en;                                         
              when "010" =>                                                               
                reg_data_out <= zero & reg_intr_sts;                                        
              when "011" =>                                                               
                reg_data_out <= zero & reg_intr_ack;                                        
              when "100" =>                                                               
                reg_data_out <= zero & reg_intr_pending;                                    
              when others =>                                                                
                reg_data_out  <= (others => '0');                                           
            end case;                                                                       
          end if;                                                                           
        end process;                                                                        
	end generate RDATA_INTR_NUM_LESS_32;                                                


--	------------------------------------------------------
--	--Example code to generate user logic interrupts
--	--Note: The example code presented here is to show you one way of generating
--	--      interrupts from the user logic. This code snippet generates a level
--	--      triggered interrupt when the intr_counter_reg counts down to zero.
--	--      while intr_control_reg[0] is asserted. Deasserting the intr_control_reg[0]
--	--      disables the counter and clears the interrupt signal.
--	------------------------------------------------------

--	process( S_AXI_ACLK ) is                                                     
--	  begin                                                                            
--	    if (rising_edge (S_AXI_ACLK)) then                                             
--	      if ( S_AXI_ARESETN = '0') then                                               
--	        intr_counter <= (others => '1');                                           
--	      elsif (intr_counter /= x"0") then                                          
--	        intr_counter <= std_logic_vector (unsigned(intr_counter) - 1);                                        
--	      end if;                                                                      
--	    end if;                                                                        
--	end process;                                                                       
	                                                                                   
	                                                                                   
--	process( S_AXI_ACLK ) is                                                           
--	  begin                                                                            
--	    if (rising_edge (S_AXI_ACLK)) then                                             
--	      if ( S_AXI_ARESETN = '0') then                                               
--	        intr <= (others => '0');                                                   
--	      else                                                                         
--	        if (intr_counter = x"a") then                                            
--	          intr <= (others => '1');                                                 
--	        else                                                                       
--	          intr <= (others => '0');                                                 
--	        end if;                                                                    
--	      end if;                                                                      
--	    end if;                                                                        
--	end process;                                                                       
	                                                                                   
	  -- generate a global interrupt whenever an interrupt is pending.
	  -- this can happen also just after an interrupt has been enabled 
	  -- used to output an interrupt on physical line                                         
	  process (S_AXI_ACLK)                                                             
	    variable temp : std_logic;                                                     
	    begin                                                                          
	      if (rising_edge (S_AXI_ACLK)) then                                           
	        if( S_AXI_ARESETN = '0' or intr_ack_all_ff = '1') then                     
	          intr_all <= '0';                                                         
	        else                                                                       
	          intr_all <= or_reduction(reg_intr_pending);                              
	        end if;                                                                    
	      end if;                                                                      
	  end process;                                                                     
	                                                                                   
	  -- generate a global intr ack in any reg_intr_ack reg bits
	  -- used to clear the global inerrupt line                                 
	  process (S_AXI_ACLK)                                                             
	    variable temp : std_logic;                                                     
	    begin                                                                          
	      if (rising_edge (S_AXI_ACLK)) then                                           
	        if( S_AXI_ARESETN = '0' or intr_ack_all_ff = '1') then                     
	          intr_ack_all <= '0';                                                     
	        else                                                                       
	          intr_ack_all <= or_reduction(reg_intr_ack);                              
	        end if;                                                                    
	      end if;                                                                      
	  end process;                                                                     
	                      
	-- have intr_all and intr_ack_all set only for one cycle                                                             
	process( S_AXI_ACLK ) is                                                           
	  begin                                                                            
	    if (rising_edge (S_AXI_ACLK)) then                                             
	      if ( S_AXI_ARESETN = '0') then                                               
	        intr_all_ff <= '0';                                                        
	        intr_ack_all_ff <= '0';                                                    
	      else                                                                         
	        intr_all_ff <= intr_all;                                                   
	        intr_ack_all_ff <= intr_ack_all;                                           
	      end if;                                                                      
	   end if;                                                                         
	end process;                                                                       
	                                                                                   
    -- det_intr(i) will carry rhe signal if a new interrupt has been detected	                                                                                   
	gen_intr_detection  : for i in 0 to (C_NUM_OF_INTR - 1) generate                   
	  signal s_irq_lvl: std_logic;                                                     
	  begin                                                                            
	    gen_intr_level_detect: if (C_INTR_SENSITIVITY(i) = '1') generate               
	    begin                                                                          
	        gen_intr_active_high_detect: if (C_INTR_ACTIVE_STATE(i) = '1') generate    
	        begin                                                                      
	                                                                                   
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	              if (rising_edge (S_AXI_ACLK)) then                                   
	                if ( S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then            
	                  det_intr(i) <= '0';                                              
	                else                                                               
	                  if (intr(i) = '1') then                                          
	                    det_intr(i) <= '1';                                            
	                  end if;                                                          
	               end if;                                                             
	             end if;                                                               
	          end process;                                                             
	        end generate gen_intr_active_high_detect;                                  
	                                                                                   
	        gen_intr_active_low_detect: if (C_INTR_ACTIVE_STATE(i) = '0') generate     
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	              if (rising_edge (S_AXI_ACLK)) then                                   
	                if ( S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then            
	                  det_intr(i) <= '0';                                              
	                else                                                               
	                  if (intr(i) = '0') then                                          
	                    det_intr(i) <= '1';                                            
	                  end if;                                                          
	                end if;                                                            
	              end if;                                                              
	          end process;                                                             
	        end generate gen_intr_active_low_detect;                                   
	                                                                                   
	    end generate gen_intr_level_detect;                                            
	                                                                                   
						                                                                
	    gen_intr_edge_detect: if (C_INTR_SENSITIVITY(i) = '0') generate                
	      signal intr_edge : std_logic_vector (C_NUM_OF_INTR-1 downto 0);              
	      signal intr_ff : std_logic_vector (C_NUM_OF_INTR-1 downto 0);                
	      signal intr_ff2 : std_logic_vector (C_NUM_OF_INTR-1 downto 0);               
	      begin                                                                        
	        gen_intr_rising_edge_detect: if (C_INTR_ACTIVE_STATE(i) = '1') generate    
	        begin                                                                      
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	              if (rising_edge (S_AXI_ACLK)) then                                   
	                if ( S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then            
	                  intr_ff(i) <= '0';                                               
	                  intr_ff2(i) <= '0';                                              
	                else                                                               
	                  intr_ff(i) <= intr(i);                                           
	                  intr_ff2(i) <= intr_ff(i);                                       
	               end if;                                                             
	              end if;                                                              
	          end process;                                                             
	                                                                                   
	          intr_edge(i) <= intr_ff(i) and (not intr_ff2(i));                        
	                                                                                   
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	             if (rising_edge (S_AXI_ACLK)) then                                    
	               if ( S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then             
	                 det_intr(i) <= '0';                                               
	               elsif (intr_edge(i) = '1') then                                     
	                 det_intr(i) <= '1';                                               
	               end if;                                                             
	             end if;                                                               
	           end process;                                                            
	                                                                                   
	        end generate gen_intr_rising_edge_detect;                                  
	                                                                                   
	        gen_intr_falling_edge_detect: if (C_INTR_ACTIVE_STATE(i) = '0') generate   
	        begin                                                                      
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	              if (rising_edge (S_AXI_ACLK)) then                                   
	                if ( S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then            
	                  intr_ff(i) <= '0';                                               
	                  intr_ff2(i) <= '0';                                              
	                else                                                               
	                  intr_ff(i) <= intr(i);                                           
	                  intr_ff2(i) <= intr_ff(i);                                       
	                end if;                                                            
	              end if;                                                              
	          end process;                                                             
	                                                                                   
	          intr_edge(i) <= intr_ff2(i) and (not intr_ff(i));                        
	                                                                                   
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	              if (rising_edge (S_AXI_ACLK)) then                                   
	                if ( S_AXI_ARESETN = '0' or reg_intr_ack(i) = '1') then            
	                  det_intr(i) <= '0';                                              
	                elsif (intr_edge(i) = '1') then                                    
	                  det_intr(i) <= '1';                                              
	                end if;                                                            
	              end if;                                                              
	          end process;                                                             
	        end generate gen_intr_falling_edge_detect;                                 
	                                                                                   
	    end generate gen_intr_edge_detect;                                             
	                                                                                   
	    -- IRQ generation logic: will use the global interrupt flag to fire 
	    -- logic will refire a new interrupt after an acknowledge of the previously detected one                                                        
	   gen_irq_level: if (C_IRQ_SENSITIVITY = 1) generate                              
	   begin                                                                           
	       irq_level_high: if (C_IRQ_ACTIVE_STATE = 1) generate                        
	       begin                                                                       
	         process( S_AXI_ACLK ) is                                                  
	           begin                                                                   
	             if (rising_edge (S_AXI_ACLK)) then                                    
	               if ( S_AXI_ARESETN = '0' or intr_ack_all = '1') then                
	                 s_irq_lvl <= '0';                                                 
	               elsif (intr_all = '1' and reg_global_intr_en(0) = '1') then         
	                 s_irq_lvl <= '1';                                                 
	              end if;                                                              
	             end if;                                                               
	         end process;                                                              
	                                                                                   
	         s_irq <= s_irq_lvl;                                                       
	       end generate irq_level_high;                                                
	                                                                                   
		                                                                                
	       irq_level_low: if (C_IRQ_ACTIVE_STATE = 0) generate                         
	          process( S_AXI_ACLK ) is                                                 
	            begin                                                                  
	              if (rising_edge (S_AXI_ACLK)) then                                   
	                if ( S_AXI_ARESETN = '0' or intr_ack_all = '1') then               
	                  s_irq_lvl <= '1';                                                
	                elsif (intr_all = '1' and reg_global_intr_en(0) = '1') then        
	                  s_irq_lvl <= '0';                                                
	               end if;                                                             
	             end if;                                                               
	           end process;                                                            
	                                                                                   
	         s_irq <= s_irq_lvl;                                                       
	       end generate irq_level_low;                                                 
	                                                                                   
	   end generate gen_irq_level;                                                     
	                                                                                   
	                                                                                   
	   gen_irq_edge: if (C_IRQ_SENSITIVITY = 0) generate                               
	                                                                                   
	   signal s_irq_lvl_ff:std_logic;                                                  
	   begin                                                                           
	       irq_rising_edge: if (C_IRQ_ACTIVE_STATE = 1) generate                       
	       begin                                                                       
	         process( S_AXI_ACLK ) is                                                  
	           begin                                                                   
	             if (rising_edge (S_AXI_ACLK)) then                                    
	               if ( S_AXI_ARESETN = '0' or intr_ack_all = '1') then                
	                 s_irq_lvl <= '0';                                                 
	                 s_irq_lvl_ff <= '0';                                              
	               elsif (intr_all = '1' and reg_global_intr_en(0) = '1') then         
	                 s_irq_lvl <= '1';                                                 
	                 s_irq_lvl_ff <= s_irq_lvl;                                        
	              end if;                                                              
	            end if;                                                                
	         end process;                                                              
	                                                                                   
	         s_irq <= s_irq_lvl and (not s_irq_lvl_ff);                                
	       end generate irq_rising_edge;                                               
	                                                                                   
	       irq_falling_edge: if (C_IRQ_ACTIVE_STATE = 0) generate                      
	       begin                                                                       
	         process( S_AXI_ACLK ) is                                                  
	           begin                                                                   
	             if (rising_edge (S_AXI_ACLK)) then                                    
	               if ( S_AXI_ARESETN = '0' or intr_ack_all = '1') then                
	                 s_irq_lvl <= '1';                                                 
	                 s_irq_lvl_ff <= '1';                                              
	               elsif (intr_all = '1' and reg_global_intr_en(0) = '1') then         
	                 s_irq_lvl <= '0';                                                 
	                 s_irq_lvl_ff <= s_irq_lvl;                                        
	               end if;                                                             
	             end if;                                                               
	         end process;                                                              
	                                                                                   
	         s_irq <= not (s_irq_lvl_ff and (not s_irq_lvl));                          
	       end generate irq_falling_edge;                                              
	                                                                                   
	   end generate gen_irq_edge;                                                      
	                                                                                   
	   irq <= s_irq;                                                              
	end generate gen_intr_detection;                                                   

	-- Add user logic here

	-- User logic ends

end arch_imp;
