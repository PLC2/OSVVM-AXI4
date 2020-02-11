--
--  File Name:         Axi4LiteMasterTransactionPkg.vhd
--  Design Unit Name:  Axi4LiteMasterTransactionPkg
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Defines types, constants, and subprograms used by
--      OSVVM Address Master Transaction Based Models (aka: TBM, TLM, VVC)
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
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2017 - 2020 by SynthWorks Design Inc.  
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
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  use ieee.math_real.all ;

library osvvm ;
    context osvvm.OsvvmContext ;

package Axi4LiteMasterTransactionPkg is

  -- Address Master Common Operations
  type UnresolvedMasterOperationType is (
    -- Model Directives
    WAIT_CLOCK, 
    GET_ALERTLOG_ID, 
    GET_TRANSACTION_COUNT, GET_WRITE_TRANSACTION_COUNT, GET_READ_TRANSACTION_COUNT,
    SET_MODEL_OPTIONS, GET_MODEL_OPTIONS,
    GET_ERRORS, -- Deprecate
    --  bus operations
    --                       -- Master
    --                       ----------------------------
    WRITE,                   -- Blocking (Tx Addr & Data)
    READ,                    -- Blocking(Tx Addr, Rx Data)
    --  Master Only
    READ_CHECK,              -- Blocking (Tx Addr & Data)
    ASYNC_WRITE,             -- Non-blocking (Tx Addr & Data)
    ASYNC_WRITE_ADDRESS,     -- Non-blocking (Tx Addr)
    ASYNC_WRITE_DATA,        -- Non-blocking (Tx Data)
    ASYNC_READ_ADDRESS,      -- Non-blocking (Tx Addr)
    READ_DATA,               -- Blocking (Rx Data)
    READ_DATA_CHECK,         -- Blocking (Tx Data)
    TRY_READ_DATA,           -- Non-blocking try & get
    TRY_READ_DATA_CHECK,     -- Non-blocking read check
    THE_END
  ) ;
  type UnresolvedMasterOperationVectorType is array (natural range <>) of UnresolvedMasterOperationType ;
--  alias resolved_max is maximum[ UnresolvedMasterOperationVectorType return UnresolvedMasterOperationType] ;
  -- Maximum is implicitly defined for any array type in VHDL-2008.   Function resolved_max is a fall back.
  function resolved_max ( s : UnresolvedMasterOperationVectorType) return UnresolvedMasterOperationType ;
  subtype MasterOperationType is resolved_max UnresolvedMasterOperationType ;

  -- AXI4 Model Options
  type Axi4UnresolvedMasterOptionsType is (
    --
    -- Master Ready TimeOut Checks
    WRITE_ADDRESS_READY_TIME_OUT,
    WRITE_DATA_READY_TIME_OUT,
    READ_ADDRESS_READY_TIME_OUT,
    -- Master Valid TimeOut Checks
    WRITE_RESPONSE_VALID_TIME_OUT,
    READ_DATA_VALID_TIME_OUT,
    --
    -- Master Ready Before Valid
    WRITE_RESPONSE_READY_BEFORE_VALID,
    READ_DATA_READY_BEFORE_VALID,
    --
    -- Master Ready Delay Cycles
    WRITE_RESPONSE_READY_DELAY_CYCLES,
    READ_DATA_READY_DELAY_CYCLES,
    --
    -- Master PROT Settings
    READ_PROT,
    WRITE_PROT,
    
    -- Master RESP Settings
    WRITE_RESP,
    READ_RESP,

    --
    -- The End -- Done
    THE_END
  ) ;
  type Axi4UnresolvedMasterOptionsVectorType is array (natural range <>) of Axi4UnresolvedMasterOptionsType ;
  -- alias resolved_max is maximum[ Axi4UnresolvedMasterOptionsVectorType return Axi4UnresolvedMasterOptionsType] ;
  function resolved_max(A : Axi4UnresolvedMasterOptionsVectorType) return Axi4UnresolvedMasterOptionsType ;
  subtype Axi4LiteMasterOptionsType is resolved_max Axi4UnresolvedMasterOptionsType ;


  -- Record creates a channel for communicating transactions to the model.
  type MasterTransactionRecType is record
    -- All Address Bus Masters
    Rdy                : bit_max ;
    Ack                : bit_max ;
    Operation          : MasterOperationType ;
    Address            : std_logic_vector_max_c ;
    AddrWidth          : integer_max ;
    DataToModel        : std_logic_vector_max_c ;
    DataFromModel      : std_logic_vector_max_c ;
    DataWidth          : integer_max ;
    StatusMsgOn        : boolean_max ;
    -- Model Options 
    Options            : Axi4LiteMasterOptionsType ;
    -- Optional parameter handling
    BoolFromModel      : boolean_max ;
    IntFromModel       : integer_max ; 
    BoolToModel        : boolean_max ; 
    IntToModel         : integer_max ;
  end record MasterTransactionRecType ;

--!TODO add VHDL-2018 Interfaces


  ------------------------------------------------------------
  procedure WaitForClock (
  -- Directive:  Wait for NumberOfClocks number of clocks
  ------------------------------------------------------------
    signal   TransRec        : InOut MasterTransactionRecType ;
             NumberOfClocks  : In    natural := 1
  ) ;

  alias NoOp is WaitForClock [MasterTransactionRecType, natural] ;

  ------------------------------------------------------------
  procedure GetAlertLogID (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable AlertLogID  : Out   AlertLogIDType
  ) ;

  ------------------------------------------------------------
  procedure GetErrors (
  -- Error reporting for testbenches that do not use AlertLogPkg
  -- Returns error count.  If an error count /= 0, also print it
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable ErrCnt      : Out   natural
  ) ;

  ------------------------------------------------------------
  procedure GetTransactionCount (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable Count       : Out   integer
  ) ;

  ------------------------------------------------------------
  procedure GetWriteTransactionCount (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable Count       : Out   integer
  ) ;

  ------------------------------------------------------------
  procedure GetReadTransactionCount (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable Count       : Out   integer
  ) ;

  ------------------------------------------------------------
  procedure MasterWrite (
  -- do CPU Write Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterWriteAsync (
  -- dispatch CPU Write Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterWriteAddressAsync (
  -- dispatch CPU Write Address Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterWriteDataAsync (
  -- dispatch CPU Write Data Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterWriteDataAsync (
  -- dispatch CPU Write Data Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterRead (
  -- do CPU Read Cycle and return data
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
    variable oData       : Out   std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterReadCheck (
  -- do CPU Read Cycle and check supplied data
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterReadAddressAsync (
  -- dispatch CPU Read Address Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterReadData (
  -- Do CPU Read Data Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable oData       : Out   std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterReadDataCheck (
  -- Do CPU Read Data Cycle and check received Data
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterTryReadData (
  -- Try to Get CPU Read Data Cycle
  -- If data is available, get it and return available TRUE.
  -- Otherwise Return Available FALSE.
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable oData       : Out   std_logic_vector ;
    variable Available   : Out   boolean ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterTryReadDataCheck (
  -- Try to Get CPU Read Data Cycle
  -- If data is available, check it and return available TRUE.
  -- Otherwise Return Available FALSE.
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iData       : In    std_logic_vector ;
    variable Available   : Out   boolean ;
             StatusMsgOn : In    boolean := false
  ) ;

  ------------------------------------------------------------
  procedure MasterReadPoll (
  -- Read location (iAddr) until Data(IndexI) = ValueI
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             Index       : In    Integer ;
             BitValue    : In    std_logic ;
             StatusMsgOn : In    boolean := false ;
             WaitTime    : In    natural := 10
  ) ;

  ------------------------------------------------------------
  function IsWriteAddress (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsBlockOnWriteAddress (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsWriteData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsBlockOnWriteData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsReadAddress (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsReadData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsReadCheck (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  ------------------------------------------------------------
  function IsTryReadData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean ;

  --
  --  Extensions to support model customizations
  -- 
  
  ------------------------------------------------------------
  procedure SetModelOptions (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    constant Option      : In    Axi4LiteMasterOptionsType ;
    constant OptVal      : In    boolean
  ) ;

  ------------------------------------------------------------
  procedure SetModelOptions (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    constant Option      : In    Axi4LiteMasterOptionsType ;
    constant OptVal      : In    integer
  ) ;

  ------------------------------------------------------------
  procedure SetModelOptions (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    constant Option      : In    Axi4LiteMasterOptionsType ;
    constant OptVal      : In    std_logic_vector
  ) ;

end package Axi4LiteMasterTransactionPkg ;

-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////

package body Axi4LiteMasterTransactionPkg is

  function resolved_max ( s : UnresolvedMasterOperationVectorType) return UnresolvedMasterOperationType is
  begin
    return maximum(s) ;
  end function resolved_max ;

  function resolved_max ( A : Axi4UnresolvedMasterOptionsVectorType) return Axi4UnresolvedMasterOptionsType is
  begin
    return maximum(A) ;
  end function resolved_max ;

  ------------------------------------------------------------
  procedure WaitForClock (
  -- Directive:  Wait for NumberOfClocks number of clocks in the model
  ------------------------------------------------------------
    signal   TransRec        : InOut MasterTransactionRecType ;
             NumberOfClocks  : In    natural := 1
  ) is
  begin
    TransRec.Operation     <= WAIT_CLOCK ;
    TransRec.DataToModel   <= ToTransaction(NumberOfClocks, TransRec.DataToModel'length);
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure WaitForClock ;

  ------------------------------------------------------------
  procedure GetAlertLogID (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable AlertLogID  : Out   AlertLogIDType
  ) is
  begin
    TransRec.Operation     <= GET_ALERTLOG_ID ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;

    -- Return AlertLogID
    AlertLogID := AlertLogIDType(TransRec.IntFromModel) ;
  end procedure GetAlertLogID ;

  ------------------------------------------------------------
  procedure GetErrors (
  -- Error reporting for testbenches that do not use AlertLogPkg
  -- Returns error count.  If an error count /= 0, also print it
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable ErrCnt      : Out   natural
  ) is
    variable ModelID : AlertLogIDType ;
  begin
    GetAlertLogID(TransRec, ModelID) ;
    ReportNonZeroAlerts(AlertLogID => ModelID) ;
    ErrCnt := GetAlertCount(AlertLogID => ModelID) ;
  end procedure GetErrors ;

  ------------------------------------------------------------
  procedure GetTransactionCount (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable Count       : Out   integer
  ) is
  begin
    TransRec.Operation     <= GET_TRANSACTION_COUNT ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;

    -- Return AlertLogID
    Count := TransRec.IntFromModel ;
  end procedure GetTransactionCount ;

  ------------------------------------------------------------
  procedure GetWriteTransactionCount (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable Count       : Out   integer
  ) is
  begin
    TransRec.Operation     <= GET_WRITE_TRANSACTION_COUNT ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;

    -- Return AlertLogID
    Count := TransRec.IntFromModel ;
  end procedure GetWriteTransactionCount ;

  ------------------------------------------------------------
  procedure GetReadTransactionCount (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable Count       : Out   integer
  ) is
  begin
    TransRec.Operation     <= GET_READ_TRANSACTION_COUNT ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;

    -- Return AlertLogID
    Count := TransRec.IntFromModel ;
  end procedure GetReadTransactionCount ;

  ------------------------------------------------------------
  procedure MasterWrite (
  -- do CPU Write Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation        <= WRITE ;
    TransRec.Address          <= ToTransaction(iAddr) ;
    TransRec.AddrWidth        <= iAddr'length ;
    TransRec.DataToModel      <= ToTransaction(Extend(iData, TransRec.DataToModel'length)) ;
    TransRec.DataWidth        <= iData'length ;
    TransRec.StatusMsgOn      <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterWrite ;

  ------------------------------------------------------------
  procedure MasterWriteAsync (
  -- dispatch CPU Write Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation        <= ASYNC_WRITE ;
    TransRec.Address          <= ToTransaction(iAddr) ;
    TransRec.AddrWidth        <= iAddr'length ;
    TransRec.DataToModel      <= ToTransaction(Extend(iData, TransRec.DataToModel'length)) ;
    TransRec.DataWidth        <= iData'length ;
    TransRec.StatusMsgOn      <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterWriteAsync ;

  ------------------------------------------------------------
  procedure MasterWriteAddressAsync (
  -- dispatch CPU Write Address Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation        <= ASYNC_WRITE_ADDRESS ;
    TransRec.Address          <= ToTransaction(iAddr) ;
    TransRec.AddrWidth        <= iAddr'length ;
    TransRec.DataToModel      <= (TransRec.DataToModel'range => 'X') ;
    TransRec.DataWidth        <= 0 ;
    TransRec.StatusMsgOn      <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterWriteAddressAsync ;

  ------------------------------------------------------------
  procedure MasterWriteDataAsync (
  -- dispatch CPU Write Data Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation        <= ASYNC_WRITE_DATA ;
    TransRec.Address          <= ToTransaction(iAddr, TransRec.Address'length) ;
    TransRec.AddrWidth        <= iAddr'length ;
    TransRec.DataToModel      <= ToTransaction(iData, TransRec.DataToModel'length) ;
    TransRec.DataWidth        <= iData'length ;
    TransRec.StatusMsgOn      <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterWriteDataAsync ;

  ------------------------------------------------------------
  procedure MasterWriteDataAsync (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    MasterWriteDataAsync(TransRec, X"00", iData, StatusMsgOn) ;
  end procedure MasterWriteDataAsync ;

  ------------------------------------------------------------
  procedure MasterRead (
  -- do CPU Read Cycle and return data
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
    variable oData       : Out   std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= READ ;
    TransRec.Address            <= ToTransaction(iAddr) ;
    TransRec.AddrWidth          <= iAddr'length ;
    TransRec.DataWidth          <= oData'length ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
    -- Return Results
    oData := Reduce(FromTransaction(TransRec.DataFromModel), oData'Length) ;
  end procedure MasterRead ;

  ------------------------------------------------------------
  procedure MasterReadCheck (
  -- do CPU Read Cycle and check supplied data
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= READ_CHECK ;
    TransRec.Address            <= ToTransaction(iAddr) ;
    TransRec.AddrWidth          <= iAddr'length ;
    TransRec.DataToModel        <= ToTransaction(Extend(iData, TransRec.DataToModel'length)) ;
    TransRec.DataWidth          <= iData'length ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterReadCheck ;

  ------------------------------------------------------------
  procedure MasterReadAddressAsync (
  -- dispatch CPU Read Address Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= ASYNC_READ_ADDRESS ;
    TransRec.Address            <= ToTransaction(iAddr) ;
    TransRec.AddrWidth          <= iAddr'length ;
    TransRec.DataToModel        <= (TransRec.DataToModel'range => 'X') ;
    TransRec.DataWidth          <= 0 ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterReadAddressAsync ;

  ------------------------------------------------------------
  procedure MasterReadData (
  -- Do CPU Read Data Cycle
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable oData       : Out   std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= READ_DATA ;
    TransRec.Address            <= (TransRec.Address'range => 'X') ;
    TransRec.DataWidth          <= oData'length ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
    -- Return Results
    oData := Reduce(FromTransaction(TransRec.DataFromModel), oData'Length) ;
  end procedure MasterReadData ;

  ------------------------------------------------------------
  procedure MasterReadDataCheck (
  -- Do CPU Read Data Cycle and check received Data
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iData       : In    std_logic_vector ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= READ_DATA_CHECK ;
    TransRec.Address            <= (TransRec.Address'range => 'X') ;
    TransRec.DataToModel        <= ToTransaction(Extend(iData, TransRec.DataToModel'length)) ;
    TransRec.DataWidth          <= iData'length ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure MasterReadDataCheck ;

  ------------------------------------------------------------
  procedure MasterTryReadData (
  -- Try to Get CPU Read Data Cycle
  -- If data is available, get it and return available TRUE.
  -- Otherwise Return Available FALSE.
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    variable oData       : Out   std_logic_vector ;
    variable Available   : Out   boolean ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= TRY_READ_DATA ;
    TransRec.Address            <= (TransRec.Address'range => 'X') ;
    TransRec.DataWidth          <= oData'length ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
    -- Return Results
    oData := Reduce(FromTransaction(TransRec.DataFromModel), oData'Length) ;
    Available := TransRec.BoolFromModel ;
  end procedure MasterTryReadData ;

  ------------------------------------------------------------
  procedure MasterTryReadDataCheck (
  -- Try to Get CPU Read Data Cycle
  -- If data is available, check it and return available TRUE.
  -- Otherwise Return Available FALSE.
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iData       : In    std_logic_vector ;
    variable Available   : Out   boolean ;
             StatusMsgOn : In    boolean := false
  ) is
  begin
    -- Put values in record
    TransRec.Operation          <= TRY_READ_DATA ;
    TransRec.Address            <= (TransRec.Address'range => 'X') ;
    TransRec.DataToModel        <= ToTransaction(Extend(iData, TransRec.DataToModel'length)) ;
    TransRec.DataWidth          <= iData'length ;
    TransRec.StatusMsgOn        <= StatusMsgOn ;
    -- Start Transaction
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
    Available := TransRec.BoolFromModel ;
  end procedure MasterTryReadDataCheck ;

  ------------------------------------------------------------
  procedure MasterReadPoll (
  -- Read location (iAddr) until Data(IndexI) = ValueI
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
             iAddr       : In    std_logic_vector ;
             Index       : In    Integer ;
             BitValue    : In    std_logic ;
             StatusMsgOn : In    boolean := false ;
             WaitTime    : In    natural := 10
  ) is
    variable iData    : std_logic_vector(TransRec.DataFromModel'range) ;
    variable ModelID  : AlertLogIDType ;
  begin
    loop
      WaitForClock(TransRec, WaitTime) ;
      MasterRead (TransRec, iAddr, iData) ;
      exit when iData(Index) = BitValue ;
    end loop ;

    GetAlertLogID(TransRec, ModelID) ;
    Log(ModelID, "CpuPoll: address" & to_hstring(iAddr) &
      "  Data: " & to_hstring(FromTransaction(TransRec.DataFromModel)), INFO, StatusMsgOn) ;
  end procedure MasterReadPoll ;

  ------------------------------------------------------------
  function IsWriteAddress (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return
      (Operation = WRITE) or
      (Operation = ASYNC_WRITE) or
      (Operation = ASYNC_WRITE_ADDRESS) ;
  end function IsWriteAddress ;

  ------------------------------------------------------------
  function IsBlockOnWriteAddress (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return (Operation = WRITE) ;
  end function IsBlockOnWriteAddress ;

  ------------------------------------------------------------
  function IsWriteData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return
      (Operation = WRITE) or
      (Operation = ASYNC_WRITE) or
      (Operation = ASYNC_WRITE_DATA) ;
  end function IsWriteData ;

  ------------------------------------------------------------
  function IsBlockOnWriteData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return (Operation = WRITE) ;
  end function IsBlockOnWriteData ;

  ------------------------------------------------------------
  function IsReadAddress (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return
      (Operation = READ) or
      (Operation = READ_CHECK) or
      (Operation = ASYNC_READ_ADDRESS) ;
  end function IsReadAddress ;

  ------------------------------------------------------------
  function IsReadData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return
      (Operation = READ) or
      (Operation = READ_CHECK) or
      (Operation = READ_DATA) or
      (Operation = TRY_READ_DATA) or
      (Operation = READ_DATA_CHECK) or
      (Operation = TRY_READ_DATA_CHECK) ;
  end function IsReadData ;

  ------------------------------------------------------------
  function IsTryReadData (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return (Operation = TRY_READ_DATA) or (Operation = TRY_READ_DATA_CHECK)  ;
  end function IsTryReadData ;

  ------------------------------------------------------------
  function IsReadCheck (
  -----------------------------------------------------------
    constant Operation     : in MasterOperationType
  ) return boolean is
  begin
    return
      (Operation = READ_CHECK) or
      (Operation = READ_DATA_CHECK) or
      (Operation = TRY_READ_DATA_CHECK) ;
  end function IsReadCheck ;

  --
  --  Extensions to support model customizations
  -- 
  
  ------------------------------------------------------------
  procedure SetModelOptions (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    constant Option      : In    Axi4LiteMasterOptionsType ;
    constant OptVal      : In    boolean
  ) is
  begin
    TransRec.Operation     <= SET_MODEL_OPTIONS ;
    TransRec.Options       <= Option ;
    TransRec.BoolToModel   <= OptVal ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure SetModelOptions ;

  ------------------------------------------------------------
  procedure SetModelOptions (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    constant Option      : In    Axi4LiteMasterOptionsType ;
    constant OptVal      : In    integer
  ) is
  begin
    TransRec.Operation     <= SET_MODEL_OPTIONS ;
    TransRec.Options       <= Option ;
    TransRec.IntToModel    <= OptVal ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure SetModelOptions ;

  ------------------------------------------------------------
  procedure SetModelOptions (
  ------------------------------------------------------------
    signal   TransRec    : InOut MasterTransactionRecType ;
    constant Option      : In    Axi4LiteMasterOptionsType ;
    constant OptVal      : In    std_logic_vector
  ) is
  begin
    TransRec.Operation     <= SET_MODEL_OPTIONS ;
    TransRec.Options       <= Option ;
    TransRec.IntToModel    <= to_integer(OptVal) ;
    RequestTransaction(Rdy => TransRec.Rdy, Ack => TransRec.Ack) ;
  end procedure SetModelOptions ;
end package body Axi4LiteMasterTransactionPkg ;