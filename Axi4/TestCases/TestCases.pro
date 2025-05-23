#  File Name:         testbench.pro
#  Revision:          STANDARD VERSION
#
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com
#  Contributor(s):
#     Jim Lewis      jim@synthworks.com
#
#
#  Description:
#        Script to run one Axi test cases  
#
#  Developed for:
#        SynthWorks Design Inc.
#        VHDL Training Classes
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
#
#  Revision History:
#    Date      Version    Description
#     4/2025   2025.04    Added Tests
#     1/2022   2022.01    Added Tests
#     1/2020   2020.01    Updated Licenses to Apache
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2019 - 2025 by SynthWorks Design Inc.  
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
RunTest  TbAxi4_DemoMemoryReadWrite1.vhd

include TestCases_NoBurst.pro
include TestCases_Burst.pro

# Both NoBurst and Burst
RunTest TbAxi4_ManagerRandomTiming1.vhd 
RunTest  TbAxi4_AxiManagerRandomTiming1.vhd 
RunTest  TbAxi4_AxiManagerRandomTiming2.vhd 
RunTest TbAxi4_ManagerRandomTimingAsync1.vhd 

RunTest TbAxi4_MemoryRandomTiming1.vhd 
RunTest  TbAxi4_AxiMemoryRandomTiming1.vhd 
RunTest  TbAxi4_AxiMemoryRandomTiming2.vhd 
RunTest TbAxi4_MemoryRandomTimingAsync1.vhd 

RunTest TbAxi4_SubordinateRandomTiming1.vhd
RunTest  TbAxi4_AxiSubordinateRandomTiming1.vhd 
RunTest  TbAxi4_AxiSubordinateRandomTiming2.vhd 

RunTest TbAxi4_ManagerMemoryRandomTiming1.vhd 
RunTest TbAxi4_ManagerSubordinateRandomTiming1.vhd
RunTest TbAxi4_ManagerSubordinateRandomTimingAsync1.vhd
RunTest TbAxi4_NoRandomTiming1.vhd 

