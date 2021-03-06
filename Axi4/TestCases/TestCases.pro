#  File Name:         testbench.pro
#  Revision:          STANDARD VERSION
#
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com
#  Contributor(s):
#     Jim Lewis      jim@synthworks.com
#
#
#  Description:
#        Script to run one Axi Stream test  
#
#  Developed for:
#        SynthWorks Design Inc.
#        VHDL Training Classes
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
#
#  Revision History:
#    Date      Version    Description
#     1/2019   2019.01    Compile Script for OSVVM
#     1/2020   2020.01    Updated Licenses to Apache
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2019 - 2020 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#  

##
## runs in conjunction with either 
## Testbench/Testbench.pro or TestbenchVTI/TestbenchVTI.pro
## Continuing with library set previously by the above
##
##
# Tests for any AXI4 MIT
analyze TbAxi4_BasicReadWrite.vhd
analyze TbAxi4_RandomReadWrite.vhd
analyze TbAxi4_RandomReadWriteByte1.vhd

analyze TbAxi4_MemoryReadWrite1.vhd
analyze TbAxi4_MemoryReadWrite2.vhd
analyze TbAxi4_MemoryBurst1.vhd
analyze TbAxi4_MemoryBurstAsync1.vhd
analyze TbAxi4_MemoryBurstByte1.vhd
analyze TbAxi4_MemoryBurstSparse1.vhd

analyze TbAxi4_MultipleDriversMaster.vhd
analyze TbAxi4_MultipleDriversResponder.vhd
analyze TbAxi4_MultipleDriversMemory.vhd

analyze TbAxi4_AlertLogIDMaster.vhd
analyze TbAxi4_AlertLogIDResponder.vhd
analyze TbAxi4_AlertLogIDMemory.vhd

analyze TbAxi4_ReadWriteAsync1.vhd
analyze TbAxi4_ReadWriteAsync2.vhd
analyze TbAxi4_ReadWriteAsync3.vhd
analyze TbAxi4_ReadWriteAsync4.vhd

analyze TbAxi4_ResponderReadWrite1.vhd
analyze TbAxi4_ResponderReadWrite2.vhd
analyze TbAxi4_ResponderReadWrite3.vhd

analyze TbAxi4_ResponderReadWriteAsync1.vhd
analyze TbAxi4_ResponderReadWriteAsync2.vhd

analyze TbAxi4_TransactionApiMaster.vhd
analyze TbAxi4_TransactionApiMasterBurst.vhd
analyze TbAxi4_TransactionApiMemory.vhd
analyze TbAxi4_TransactionApiMemoryBurst.vhd
analyze TbAxi4_TransactionApiResponder.vhd

analyze TbAxi4_ValidTimingMaster.vhd
analyze TbAxi4_ValidTimingMemory.vhd
analyze TbAxi4_ValidTimingResponder.vhd
analyze TbAxi4_ValidTimingBurstMaster.vhd
analyze TbAxi4_ValidTimingBurstMemory.vhd

analyze TbAxi4_ReadyTimingMaster.vhd
analyze TbAxi4_ReadyTimingResponder.vhd
analyze TbAxi4_ReadyTimingMemory.vhd

analyze TbAxi4_AxiIfOptionsMasterMemory.vhd
analyze TbAxi4_AxiIfOptionsMasterResponder.vhd

analyze TbAxi4_AxSizeMasterMemory1.vhd
analyze TbAxi4_AxSizeMasterMemory2.vhd

analyze TbAxi4_TimeOutMaster.vhd
analyze TbAxi4_TimeOutResponder.vhd
analyze TbAxi4_TimeOutMemory.vhd

analyze TbAxi4_MemoryAsync.vhd


# simulate TbAxi4_BasicReadWrite
# simulate TbAxi4_RandomReadWrite
# simulate TbAxi4_RandomReadWriteByte1

# simulate TbAxi4_MemoryReadWrite1
# simulate TbAxi4_MemoryReadWrite2
# simulate TbAxi4_MemoryBurst1
# simulate TbAxi4_MemoryBurstAsync1
# simulate TbAxi4_MemoryBurstByte1
# simulate TbAxi4_MemoryBurstSparse1

# simulate TbAxi4_MultipleDriversMaster
# simulate TbAxi4_MultipleDriversResponder
# simulate TbAxi4_MultipleDriversMemory

# simulate TbAxi4_AlertLogIDMaster
# simulate TbAxi4_AlertLogIDResponder
# simulate TbAxi4_AlertLogIDMemory

# simulate TbAxi4_ReadWriteAsync1
# simulate TbAxi4_ReadWriteAsync2
# simulate TbAxi4_ReadWriteAsync3
# simulate TbAxi4_ReadWriteAsync4

# simulate TbAxi4_ResponderReadWrite1
# simulate TbAxi4_ResponderReadWrite2
# simulate TbAxi4_ResponderReadWrite3

# simulate TbAxi4_ResponderReadWriteAsync1
# simulate TbAxi4_ResponderReadWriteAsync2

# simulate TbAxi4_TransactionApiMaster
# simulate TbAxi4_TransactionApiMasterBurst
# simulate TbAxi4_TransactionApiMemory
# simulate TbAxi4_TransactionApiMemoryBurst
# simulate TbAxi4_TransactionApiResponder

# simulate TbAxi4_ValidTimingMaster
# simulate TbAxi4_ValidTimingMemory
# simulate TbAxi4_ValidTimingResponder
# simulate TbAxi4_ValidTimingBurstMaster
# simulate TbAxi4_ValidTimingBurstMemory

# simulate TbAxi4_ReadyTimingMaster
# simulate TbAxi4_ReadyTimingResponder
# simulate TbAxi4_ReadyTimingMemory

# simulate TbAxi4_AxiIfOptionsMasterMemory
# simulate TbAxi4_AxiIfOptionsMasterResponder

# simulate TbAxi4_AxSizeMasterMemory1
# simulate TbAxi4_AxSizeMasterMemory2

# simulate TbAxi4_TimeOutMaster
# simulate TbAxi4_TimeOutResponder
# simulate TbAxi4_TimeOutMemory

simulate TbAxi4_MemoryAsync


