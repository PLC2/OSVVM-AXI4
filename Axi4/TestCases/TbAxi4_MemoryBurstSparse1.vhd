--
--  File Name:         TbAxi4_MemoryBurstSparse1.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Testing of Burst Features in AXI Model
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    04/2020   2020.04    Initial revision
--    12/2020   2020.12    Updated signal and port names
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2020 by SynthWorks Design Inc.  
--  
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--  
--      https://www.apache.org/licenses/LICENSE-2.0
--  
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--  

architecture MemoryBurstSparse1 of TestCtrl is

  signal TestDone, WriteDone : integer_barrier := 1 ;
  constant BURST_MODE : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_WORD_MODE ;   
--  constant BURST_MODE : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_BYTE_MODE ;   
  constant DATA_WIDTH : integer := IfElse(BURST_MODE = ADDRESS_BUS_BURST_BYTE_MODE, 8, AXI_DATA_WIDTH)  ;  

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetAlertLogName("TbAxi4_MemoryBurstSparse1") ;
    SetLogEnable(PASSED, TRUE) ;   -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;     -- Enable INFO logs
    SetLogEnable(DEBUG, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbAxi4_MemoryBurstSparse1.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 1 ms) ;
    AlertIf(now >= 1 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
    -- Printing differs in different simulators due to differences in process order execution
    -- AlertIfDiff("./results/TbAxi4_MemoryBurstSparse1.txt", "../AXI4/Axi4/testbench/validated_results/TbAxi4_MemoryBurstSparse1.txt", "") ; 
    
    print("") ;
    ReportAlerts ; 
    print("") ;
    std.env.stop ; 
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- MasterProc
  --   Generate transactions for AxiMaster
  ------------------------------------------------------------
  MasterProc : process
    variable ByteData : std_logic_vector(7 downto 0) ;
    variable BurstVal : AddressBusFifoBurstModeType ; 
  begin
    wait until nReset = '1' ;  
    WaitForClock(MasterRec, 2) ; 
    
----------------------------------------  Test 1, Word Aligned
    log("Write with ByteAddr = 8, 12 Bytes -- word aligned") ;
    WriteBurstFIFO.push(X"UUUU_UU01") ;
    WriteBurstFIFO.push(X"UUUU_02UU") ;
    WriteBurstFIFO.push(X"UU03_UUUU") ;
    WriteBurstFIFO.push(X"04UU_UUUU") ;
    
    WriteBurstFIFO.push(X"UUUU_0605") ;
    WriteBurstFIFO.push(X"UU08_07UU") ;
    WriteBurstFIFO.push(X"0A09_UUUU") ;

    WriteBurstFIFO.push(X"UU0D_0C0B") ;
    WriteBurstFIFO.push(X"100F_0EUU") ;
    
    WriteBurst(MasterRec, X"0000_1000", 9) ;


    ReadBurst (MasterRec, X"0000_1000", 9) ;
    
    ReadBurstFIFO.Check(X"----_--01") ;
    ReadBurstFIFO.Check(X"----_02--") ;
    ReadBurstFIFO.Check(X"--03_----") ;
    ReadBurstFIFO.Check(X"04--_----") ;
    
    ReadBurstFIFO.Check(X"----_0605") ;
    ReadBurstFIFO.Check(X"--08_07--") ;
    ReadBurstFIFO.Check(X"0A09_----") ;

    ReadBurstFIFO.Check(X"--0D_0C0B") ;
    ReadBurstFIFO.Check(X"100F_0E--") ;
    
    
----------------------------------------  Test 2, Byte Aligned
    WriteBurstFIFO.push(X"UU02_01UU") ;
    WriteBurstFIFO.push(X"05UU_0403") ;
    WriteBurstFIFO.push(X"8877_UU06") ;
    WriteBurstFIFO.push(X"BBAA_99UU") ;
    
    WriteBurstFIFO.push(X"UUUU_DDCC") ;
    WriteBurstFIFO.push(X"FFUU_UUEE") ;
    WriteBurstFIFO.push(X"1110_UUUU") ;

    WriteBurstFIFO.push(X"UUUU_UU12") ;
    WriteBurstFIFO.push(X"UUUU_13UU") ;
    WriteBurstFIFO.push(X"UU14_UUUU") ;
    WriteBurstFIFO.push(X"15UU_UUUU") ;
    
    WriteBurst(MasterRec, X"0000_2001", 11) ;

    ReadBurst(MasterRec, X"0000_2001", 11) ;
    ReadBurstFIFO.Check(X"--02_01--") ;
    ReadBurstFIFO.Check(X"05--_0403") ;
    ReadBurstFIFO.Check(X"8877_--06") ;
    ReadBurstFIFO.Check(X"BBAA_99--") ;

    ReadBurstFIFO.Check(X"----_DDCC") ;
    ReadBurstFIFO.Check(X"FF--_--EE") ;
    ReadBurstFIFO.Check(X"1110_----") ;

    ReadBurstFIFO.Check(X"----_--12") ;
    ReadBurstFIFO.Check(X"----_13--") ;
    ReadBurstFIFO.Check(X"--14_----") ;
    ReadBurstFIFO.Check(X"15--_----") ;


    WaitForBarrier(WriteDone) ;
    
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(MasterRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process MasterProc ;


  ------------------------------------------------------------
  -- MemoryProc
  --   Generate transactions for AxiResponder
  ------------------------------------------------------------
  MemoryProc : process
    variable Addr : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ; 
  begin
    WaitForClock(ResponderRec, 2) ; 
   
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ResponderRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process MemoryProc ;


end MemoryBurstSparse1 ;

Configuration TbAxi4_MemoryBurstSparse1 of TbAxi4Memory is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(MemoryBurstSparse1) ; 
    end for ; 
--!!    for Responder_1 : Axi4Responder 
--!!      use entity OSVVM_AXI4.Axi4Memory ; 
--!!    end for ; 
  end for ; 
end TbAxi4_MemoryBurstSparse1 ; 