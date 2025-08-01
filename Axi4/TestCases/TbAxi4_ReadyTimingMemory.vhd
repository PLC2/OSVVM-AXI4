--
--  File Name:         TbAxi4_ReadyTimingMemory.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    WRITE_ADDRESS, WRITE_DATA & READ_ ADDRESS
--        Verify Initial values
--        READY_BEFORE_VALID  F/T/T w/ WFC(C,6)
--        READY_DELAY_CYCLES 0,2,4 
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    12/2020   2020.12    Initial revision
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2018 - 2021 by SynthWorks Design Inc.  
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

architecture ReadyTimingMemory of TestCtrl is

  signal TestDone, MemorySync : integer_barrier := 1 ;
  signal TbManagerID : AlertLogIDType ; 
  signal TbSubordinateID  : AlertLogIDType ; 
  signal TransactionCount : integer := 0 ; 

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbAxi4_ReadyTimingMemory") ;
    TbManagerID <= GetAlertLogID("TB Manager Proc") ;
    TbSubordinateID <= GetAlertLogID("TB Subordinate Proc") ;
    SetLogEnable(PASSED, TRUE) ;  -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    -- SetAlertLogJustify ;
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
    variable Addr : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;
  begin
    wait until nReset = '1' ;  
    WaitForClock(ManagerRec, 4) ; 
    -- Do 6 sets of 4 write operations
    for k in 0 to 2 loop 
      for j in 0 to 5 loop 
        WaitForClock(ManagerRec, 4) ; 
        -- Allow settings to update
        Write(ManagerRec,     X"0000_0000", X"0000_0000" + k*16 + j) ;
        ReadCheck(ManagerRec, X"0000_0000", X"0000_0000" + k*16 + j) ;
        WaitForClock(ManagerRec, 12) ; 

        Addr := X"0000_0000" + k*256 + j*16 ; 
        Data := X"0000_0000" + k*256 + j*16 ; 
--        if k /= 2 then 
        log(TbManagerID, "ManagerRec, Addr: " & to_hstring(Addr) & ",  Data: " & to_hstring(Data)) ; 
        WriteAsync(ManagerRec, Addr,    Data) ;
        if j = 4 then WaitForClock(ManagerRec, 6) ;  end if ; 
        WriteAsync(ManagerRec, Addr+4,  Data+1) ;
        if j = 4 then WaitForClock(ManagerRec, 6) ;  end if ; 
        WriteAsync(ManagerRec, Addr+8,  Data+2) ;
        if j = 4 then WaitForClock(ManagerRec, 6) ;  end if ; 
        WriteAsync(ManagerRec, Addr+12, Data+3) ;
--          WaitForClock(ManagerRec, 16) ; 
        WaitForTransaction(ManagerRec) ;
        WaitForClock(ManagerRec, 4) ; 
--        else
        log(TbManagerID, "ManagerRec, Addr: " & to_hstring(Addr) & ",  Data: " & to_hstring(Data)) ; 
        ReadAddressAsync(ManagerRec, Addr) ;
        if j = 4 then WaitForClock(ManagerRec, 6) ;  end if ; 
        ReadAddressAsync(ManagerRec, Addr+4) ;
        if j = 4 then WaitForClock(ManagerRec, 6) ;  end if ; 
        ReadAddressAsync(ManagerRec, Addr+8) ;
        if j = 4 then WaitForClock(ManagerRec, 6) ;  end if ; 
        ReadAddressAsync(ManagerRec, Addr+12) ;
        ReadCheckData(ManagerRec, Data) ;
        ReadCheckData(ManagerRec, Data+1) ;
        ReadCheckData(ManagerRec, Data+2) ;
        ReadCheckData(ManagerRec, Data+3) ;
        WaitForClock(ManagerRec, 4) ; 
--        end if ; 
        WaitForBarrier(MemorySync) ;
      end loop ; 
    end loop ; 


    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ManagerRec, 4) ;  
    WaitForBarrier(TestDone) ;
    wait ;
  end process ManagerProc ;


  ------------------------------------------------------------
  -- MemoryProc
  --   Generate transactions for AxiSubordinate
  ------------------------------------------------------------
  MemoryProc : process
    variable Addr, ExpAddr : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data, ExpData : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;  
    variable ReadyDelayCycleOption, ReadyBeforeValidOption : Axi4OptionsType ; 
    variable IntOption  : integer ; 
    variable BoolOption : boolean ; 
  begin
    -- Must set Subordinate options before start otherwise, ready will be active on first cycle.
    wait for 0 ns ; 
    WaitForClock(SubordinateRec, 3) ; 
    
    -- Check Defaults
    GetAxi4Options(SubordinateRec, WRITE_ADDRESS_READY_DELAY_CYCLES, IntOption) ;
    AffirmIfEqual(TbSubordinateID, IntOption, 0, "WRITE_ADDRESS_READY_DELAY_CYCLES") ;
    GetAxi4Options(SubordinateRec, WRITE_ADDRESS_READY_BEFORE_VALID, BoolOption) ;
    AffirmIfEqual(TbSubordinateID, BoolOption, TRUE, "WRITE_ADDRESS_READY_BEFORE_VALID") ;

    GetAxi4Options(SubordinateRec, WRITE_DATA_READY_DELAY_CYCLES, IntOption) ;
    AffirmIfEqual(TbSubordinateID, IntOption, 0, "WRITE_DATA_READY_DELAY_CYCLES") ;
    GetAxi4Options(SubordinateRec, WRITE_DATA_READY_BEFORE_VALID, BoolOption) ;
    AffirmIfEqual(TbSubordinateID, BoolOption, TRUE, "WRITE_DATA_READY_BEFORE_VALID") ;

    GetAxi4Options(SubordinateRec, READ_ADDRESS_READY_DELAY_CYCLES, IntOption) ;
    AffirmIfEqual(TbSubordinateID, IntOption, 0, "READ_ADDRESS_READY_DELAY_CYCLES") ;
    GetAxi4Options(SubordinateRec, READ_ADDRESS_READY_BEFORE_VALID, BoolOption) ;
    AffirmIfEqual(TbSubordinateID, BoolOption, TRUE, "READ_ADDRESS_READY_BEFORE_VALID") ;

    for k in 0 to 2 loop 
      case k is 
        when 0 => 
          log(TbSubordinateID, "Write Address") ;
          ReadyDelayCycleOption  := WRITE_ADDRESS_READY_DELAY_CYCLES ;
          ReadyBeforeValidOption := WRITE_ADDRESS_READY_BEFORE_VALID ;
        when 1 => 
          log(TbSubordinateID, "Write Data") ;
          ReadyDelayCycleOption  := WRITE_DATA_READY_DELAY_CYCLES ;
          ReadyBeforeValidOption := WRITE_DATA_READY_BEFORE_VALID ;
        when 2 => 
          log(TbSubordinateID, "Read Address") ;
          ReadyDelayCycleOption  := READ_ADDRESS_READY_DELAY_CYCLES ;
          ReadyBeforeValidOption := READ_ADDRESS_READY_BEFORE_VALID ;       
        when others => 
          alert("K Loop Index Out of Range", FAILURE) ;
      end case ; 
      for j in 0 to 5 loop 
        case j is 
          when 0 => 
            log(TbSubordinateID, "Valid Before Ready, Delay Cycles 0") ;
            SetAxi4Options(SubordinateRec, ReadyDelayCycleOption, 0) ;
            SetAxi4Options(SubordinateRec, ReadyBeforeValidOption, FALSE) ;
          when 1 => 
            log(TbSubordinateID, "Valid Before Ready, Delay Cycles 2") ;
            SetAxi4Options(SubordinateRec, ReadyDelayCycleOption, 2) ;
            SetAxi4Options(SubordinateRec, ReadyBeforeValidOption, FALSE) ;
          when 2 => 
            log(TbSubordinateID, "Valid Before Ready, Delay Cycles 4") ;
            SetAxi4Options(SubordinateRec, ReadyDelayCycleOption, 4) ;
            SetAxi4Options(SubordinateRec, ReadyBeforeValidOption, FALSE) ;
          when 3 => 
            log(TbSubordinateID, "Ready Before Valid, Delay Cycles 4") ;
            SetAxi4Options(SubordinateRec, ReadyDelayCycleOption, 4) ;
            SetAxi4Options(SubordinateRec, ReadyBeforeValidOption, TRUE) ;
          when 4 => 
            log(TbSubordinateID, "Ready Before Valid, Delay Cycles 4") ;
            SetAxi4Options(SubordinateRec, ReadyDelayCycleOption, 4) ;
            SetAxi4Options(SubordinateRec, ReadyBeforeValidOption, TRUE) ;
          when 5 => 
            log(TbSubordinateID, "Ready Before Valid, Delay Cycles 0") ;
            SetAxi4Options(SubordinateRec, ReadyDelayCycleOption, 0) ;
            SetAxi4Options(SubordinateRec, ReadyBeforeValidOption, TRUE) ;
          when others => 
            Alert(TbSubordinateID, "Unimplemented test case", FAILURE)  ; 
        end case ; 
        increment(TransactionCount) ;
--        -- Check Set of 4 Data items      
--        for i in 0 to 3 loop 
--          ExpAddr := X"0000_0000" + k*256 + j*16 + i*4 ; 
--          ExpData := X"0000_0000" + k*256 + j*16 + i ; 
--          if k /= 2 then 
--            GetWrite(SubordinateRec, Addr, Data) ;
--            AffirmIfEqual(TbSubordinateID, Addr, ExpAddr, "Subordinate Write Addr: ") ;
--            AffirmIfEqual(TbSubordinateID, Data, ExpData, "Subordinate Write Data: ") ;
--          else
--            SendRead(SubordinateRec, Addr, ExpData) ;
--            AffirmIfEqual(TbSubordinateID, Addr, ExpAddr, "Subordinate Read Addr: ") ;
--          end if ; 
--        end loop ; 
--        WaitForClock(SubordinateRec, 8) ;  
        WaitForBarrier(MemorySync) ;
        print("") ; print("") ;
      end loop ; 
    end loop ; 


    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(SubordinateRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process MemoryProc ;


end ReadyTimingMemory ;

Configuration TbAxi4_ReadyTimingMemory of TbAxi4Memory is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(ReadyTimingMemory) ; 
    end for ; 
--!!    for Subordinate_1 : Axi4Subordinate 
--!!      use entity OSVVM_AXI4.Axi4Memory ; 
--!!    end for ; 
  end for ; 
end TbAxi4_ReadyTimingMemory ; 