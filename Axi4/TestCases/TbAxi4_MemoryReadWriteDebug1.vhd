--
--  File Name:         TbAxi4_MemoryReadWriteDebug1.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Test transaction source
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    09/2017   2017       Initial revision
--    01/2020   2020.01    Updated license notice
--    12/2020   2020.12    Updated signal and port names
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2017 - 2021 by SynthWorks Design Inc.  
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

architecture MemoryReadWrite1 of TestCtrl is

  signal TestDone, ManagerDone : integer_barrier := 1 ;
   
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbAxi4_MemoryReadWriteDebug1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 35 ms) ;
    
    TranscriptClose ; 
    -- Printing differs in different simulators due to differences in process order execution
    -- AffirmIfTranscriptsMatch(PATH_TO_VALIDATED_RESULTS) ;

    EndOfTestReports(TimeOut => (now >= 35 ms)) ; 
    std.env.stop ; 
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- ManagerProc
  --   Generate transactions for AxiManager
  ------------------------------------------------------------
  ManagerProc : process
    variable Data : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;
  begin
    wait until nReset = '1' ;  
    WaitForClock(ManagerRec, 2) ; 
    log("Write and Read with ByteAddr = 0, 4 Bytes") ;
    Write(ManagerRec,      X"0000_0400", X"04" ) ;
    ReadCheck(ManagerRec,  X"0000_0400", X"04" ) ;
    Write(ManagerRec,      X"0000_0000", X"01" ) ;
    ReadCheck(ManagerRec,  X"0000_0000", X"01" ) ;
    Write(ManagerRec,      X"0000_0800", X"08" ) ;
    ReadCheck(ManagerRec,  X"0000_0800", X"08" ) ;
    Write(ManagerRec,      X"0000_0000", X"02" ) ;
    ReadCheck(ManagerRec,  X"0000_0000", X"02" ) ;
    Write(ManagerRec,      X"0000_0C00", X"0C" ) ;
    ReadCheck(ManagerRec,  X"0000_0C00", X"0C" ) ;
    Write(ManagerRec,      X"0000_0000", X"03" ) ;
    ReadCheck(ManagerRec,  X"0000_0000", X"03" ) ;

    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ManagerRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process ManagerProc ;


  ------------------------------------------------------------
  -- MemoryProc
  --   Generate transactions for AxiMemory
  ------------------------------------------------------------
  MemoryProc : process
    variable Addr : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;   
  begin
    WaitForClock(SubordinateRec, 2) ;
        
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(SubordinateRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process MemoryProc ;


end MemoryReadWrite1 ;

library OSVVM_AXI4 ;

Configuration TbAxi4_MemoryReadWriteDebug1 of TbAxi4Memory is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(MemoryReadWrite1) ; 
    end for ; 
--!!    for Subordinate_1 : Axi4Subordinate 
--!!      use entity OSVVM_AXI4.Axi4Memory ; 
--!!    end for ; 
  end for ; 
end TbAxi4_MemoryReadWriteDebug1 ; 