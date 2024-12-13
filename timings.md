# Build Time Tracking

This document will track build timings over time, this should enable me to focus on keeping build times in-check, and track what factors may increase build times.


## Compiler Version

```shell
$ zig version
0.14.0-dev.2435+7575f2121
```


## Time Consuming Factors

- Vulkan Binding Generation (~1 second)
- LLVM Code Emission (~1 second)


## Build Times (LLVM Backend)

This section will be for LLVM build timings


### 4:00pm, 11th December 2024

```
===-------------------------------------------------------------------------===
                      Instruction Selection and Scheduling
===-------------------------------------------------------------------------===
  Total Execution Time: 0.6131 seconds (0.6184 wall clock)

   ---User Time---   --System Time--   --User+System--   ---Wall Time---  --- Name ---
   0.1228 ( 24.4%)   0.0256 ( 23.1%)   0.1484 ( 24.2%)   0.1494 ( 24.2%)  Instruction Selection
   0.0844 ( 16.8%)   0.0185 ( 16.7%)   0.1029 ( 16.8%)   0.1037 ( 16.8%)  Instruction Scheduling
   0.0701 ( 14.0%)   0.0161 ( 14.6%)   0.0862 ( 14.1%)   0.0873 ( 14.1%)  DAG Combining 1
   0.0615 ( 12.2%)   0.0129 ( 11.7%)   0.0745 ( 12.1%)   0.0749 ( 12.1%)  Instruction Creation
   0.0505 ( 10.0%)   0.0109 (  9.8%)   0.0613 ( 10.0%)   0.0619 ( 10.0%)  DAG Combining 2
   0.0360 (  7.2%)   0.0082 (  7.4%)   0.0443 (  7.2%)   0.0447 (  7.2%)  DAG Legalization
   0.0291 (  5.8%)   0.0067 (  6.0%)   0.0357 (  5.8%)   0.0361 (  5.8%)  Type Legalization
   0.0192 (  3.8%)   0.0043 (  3.9%)   0.0234 (  3.8%)   0.0239 (  3.9%)  Vector Legalization
   0.0172 (  3.4%)   0.0045 (  4.0%)   0.0217 (  3.5%)   0.0220 (  3.6%)  Instruction Scheduling Cleanup
   0.0102 (  2.0%)   0.0025 (  2.3%)   0.0127 (  2.1%)   0.0128 (  2.1%)  DAG Combining after legalize types
   0.0009 (  0.2%)   0.0004 (  0.4%)   0.0013 (  0.2%)   0.0013 (  0.2%)  DAG Combining after legalize vectors
   0.0004 (  0.1%)   0.0001 (  0.1%)   0.0005 (  0.1%)   0.0005 (  0.1%)  Type Legalization 2
   0.5023 (100.0%)   0.1107 (100.0%)   0.6131 (100.0%)   0.6184 (100.0%)  Total

===-------------------------------------------------------------------------===
                          Pass execution timing report
===-------------------------------------------------------------------------===
  Total Execution Time: 2.2524 seconds (2.2726 wall clock)

   ---User Time---   --System Time--   --User+System--   ---Wall Time---  --- Name ---
   0.9039 ( 50.0%)   0.2090 ( 46.9%)   1.1128 ( 49.4%)   1.1230 ( 49.4%)  X86 DAG->DAG Instruction Selection
   0.2585 ( 14.3%)   0.0615 ( 13.8%)   0.3200 ( 14.2%)   0.3228 ( 14.2%)  X86 Assembly Printer
   0.2108 ( 11.7%)   0.0521 ( 11.7%)   0.2629 ( 11.7%)   0.2649 ( 11.7%)  Live DEBUG_VALUE analysis
   0.0676 (  3.7%)   0.0132 (  3.0%)   0.0808 (  3.6%)   0.0816 (  3.6%)  Fast Register Allocator
   0.0486 (  2.7%)   0.0114 (  2.6%)   0.0600 (  2.7%)   0.0607 (  2.7%)  Prologue/Epilogue Insertion & Frame Finalization
   0.0418 (  2.3%)   0.0133 (  3.0%)   0.0552 (  2.4%)   0.0557 (  2.5%)  Insert stack protectors
   0.0283 (  1.6%)   0.0060 (  1.3%)   0.0343 (  1.5%)   0.0347 (  1.5%)  Two-Address instruction pass
   0.0169 (  0.9%)   0.0000 (  0.0%)   0.0169 (  0.7%)   0.0170 (  0.7%)  Pre-ISel Intrinsic Lowering
   0.0120 (  0.7%)   0.0029 (  0.7%)   0.0149 (  0.7%)   0.0151 (  0.7%)  Check CFA info and insert CFI instructions if needed
   0.0108 (  0.6%)   0.0035 (  0.8%)   0.0143 (  0.6%)   0.0143 (  0.6%)  Lower constant intrinsics
   0.0109 (  0.6%)   0.0029 (  0.7%)   0.0138 (  0.6%)   0.0140 (  0.6%)  Free MachineFunction
   0.0102 (  0.6%)   0.0035 (  0.8%)   0.0137 (  0.6%)   0.0136 (  0.6%)  Expand large div/rem
   0.0086 (  0.5%)   0.0021 (  0.5%)   0.0107 (  0.5%)   0.0108 (  0.5%)  Remove Redundant DEBUG_VALUE analysis
   0.0075 (  0.4%)   0.0029 (  0.6%)   0.0104 (  0.5%)   0.0106 (  0.5%)  Expand vector predication intrinsics
   0.0073 (  0.4%)   0.0028 (  0.6%)   0.0101 (  0.4%)   0.0100 (  0.4%)  Scalarize Masked Memory Intrinsics
   0.0068 (  0.4%)   0.0026 (  0.6%)   0.0094 (  0.4%)   0.0095 (  0.4%)  Expand Atomic instructions
   0.0067 (  0.4%)   0.0027 (  0.6%)   0.0094 (  0.4%)   0.0094 (  0.4%)  Expand reduction intrinsics
   0.0072 (  0.4%)   0.0017 (  0.4%)   0.0090 (  0.4%)   0.0091 (  0.4%)  Post-RA pseudo instruction expansion pass
   0.0065 (  0.4%)   0.0024 (  0.5%)   0.0089 (  0.4%)   0.0090 (  0.4%)  Expand large fp convert
   0.0060 (  0.3%)   0.0024 (  0.5%)   0.0085 (  0.4%)   0.0085 (  0.4%)  Exception handling preparation
   0.0065 (  0.4%)   0.0018 (  0.4%)   0.0083 (  0.4%)   0.0083 (  0.4%)  Finalize ISel and expand pseudo-instructions
   0.0056 (  0.3%)   0.0019 (  0.4%)   0.0075 (  0.3%)   0.0076 (  0.3%)  Remove unreachable blocks from the CFG
   0.0053 (  0.3%)   0.0022 (  0.5%)   0.0074 (  0.3%)   0.0076 (  0.3%)  Expand indirectbr instructions
   0.0054 (  0.3%)   0.0014 (  0.3%)   0.0069 (  0.3%)   0.0070 (  0.3%)  X86 pseudo instruction expansion pass
   0.0049 (  0.3%)   0.0014 (  0.3%)   0.0064 (  0.3%)   0.0064 (  0.3%)  Eliminate PHI nodes for register allocation
   0.0040 (  0.2%)   0.0013 (  0.3%)   0.0052 (  0.2%)   0.0054 (  0.2%)  X86 vzeroupper inserter
   0.0041 (  0.2%)   0.0011 (  0.3%)   0.0053 (  0.2%)   0.0052 (  0.2%)  Bundle Machine CFG Edges
   0.0026 (  0.1%)   0.0009 (  0.2%)   0.0035 (  0.2%)   0.0035 (  0.2%)  Lower AMX type for load/store
   0.0025 (  0.1%)   0.0008 (  0.2%)   0.0034 (  0.1%)   0.0034 (  0.1%)  X86 EFLAGS copy lowering
   0.0025 (  0.1%)   0.0008 (  0.2%)   0.0033 (  0.1%)   0.0033 (  0.1%)  X86 PIC Global Base Reg Initialization
   0.0024 (  0.1%)   0.0009 (  0.2%)   0.0033 (  0.1%)   0.0033 (  0.1%)  Unpack machine instruction bundles
   0.0023 (  0.1%)   0.0008 (  0.2%)   0.0031 (  0.1%)   0.0033 (  0.1%)  Insert XRay ops
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0031 (  0.1%)   0.0032 (  0.1%)  Assignment Tracking Analysis
   0.0023 (  0.1%)   0.0009 (  0.2%)   0.0032 (  0.1%)   0.0031 (  0.1%)  Insert KCFI indirect call checks
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0030 (  0.1%)   0.0031 (  0.1%)  Stack Frame Layout Analysis
   0.0022 (  0.1%)   0.0009 (  0.2%)   0.0030 (  0.1%)   0.0031 (  0.1%)  Instrument function entry/exit with calls to e.g. mcount() (post inlining)
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0030 (  0.1%)   0.0030 (  0.1%)  X86 FP Stackifier
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0030 (  0.1%)   0.0030 (  0.1%)  X86 Indirect Branch Tracking
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0030 (  0.1%)   0.0030 (  0.1%)  Machine Optimization Remark Emitter
   0.0021 (  0.1%)   0.0008 (  0.2%)   0.0029 (  0.1%)   0.0030 (  0.1%)  Machine Optimization Remark Emitter #2
   0.0021 (  0.1%)   0.0008 (  0.2%)   0.0029 (  0.1%)   0.0030 (  0.1%)  Argument Stack Rebase
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0030 (  0.1%)   0.0029 (  0.1%)  Machine Sanitizer Binary Metadata
   0.0021 (  0.1%)   0.0008 (  0.2%)   0.0029 (  0.1%)   0.0029 (  0.1%)  Local Stack Slot Allocation
   0.0022 (  0.1%)   0.0008 (  0.2%)   0.0030 (  0.1%)   0.0029 (  0.1%)  X86 Indirect Thunks
   0.0021 (  0.1%)   0.0009 (  0.2%)   0.0030 (  0.1%)   0.0029 (  0.1%)  Implement the 'patchable-function' attribute
   0.0020 (  0.1%)   0.0008 (  0.2%)   0.0028 (  0.1%)   0.0029 (  0.1%)  Insert fentry calls
   0.0021 (  0.1%)   0.0008 (  0.2%)   0.0029 (  0.1%)   0.0029 (  0.1%)  Contiguously Lay Out Funclets
   0.0021 (  0.1%)   0.0007 (  0.2%)   0.0028 (  0.1%)   0.0029 (  0.1%)  X86 speculative load hardening
   0.0021 (  0.1%)   0.0007 (  0.2%)   0.0028 (  0.1%)   0.0029 (  0.1%)  Lazy Machine Block Frequency Analysis
   0.0021 (  0.1%)   0.0008 (  0.2%)   0.0029 (  0.1%)   0.0028 (  0.1%)  Shadow Stack GC Lowering
   0.0020 (  0.1%)   0.0008 (  0.2%)   0.0028 (  0.1%)   0.0028 (  0.1%)  Machine Optimization Remark Emitter #3
   0.0021 (  0.1%)   0.0007 (  0.2%)   0.0028 (  0.1%)   0.0028 (  0.1%)  Fast Tile Register Configure
   0.0021 (  0.1%)   0.0007 (  0.2%)   0.0028 (  0.1%)   0.0028 (  0.1%)  Fixup Statepoint Caller Saved
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0028 (  0.1%)  X86 Return Thunks
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0028 (  0.1%)  Prepare callbr
   0.0021 (  0.1%)   0.0007 (  0.2%)   0.0028 (  0.1%)   0.0028 (  0.1%)  X86 Discriminate Memory Operands
   0.0020 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0028 (  0.1%)  X86 Speculative Execution Side Effect Suppression
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0028 (  0.1%)  StackMap Liveness Analysis
   0.0019 (  0.1%)   0.0007 (  0.2%)   0.0026 (  0.1%)   0.0027 (  0.1%)  X86 Load Value Injection (LVI) Ret-Hardening
   0.0019 (  0.1%)   0.0007 (  0.2%)   0.0026 (  0.1%)   0.0027 (  0.1%)  X86 insert wait instruction
   0.0019 (  0.1%)   0.0007 (  0.2%)   0.0027 (  0.1%)   0.0027 (  0.1%)  Fast Tile Register Preconfigure
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0027 (  0.1%)  Lazy Machine Block Frequency Analysis #3
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0027 (  0.1%)  X86 Insert Cache Prefetches
   0.0020 (  0.1%)   0.0007 (  0.2%)   0.0028 (  0.1%)   0.0027 (  0.1%)  X86 DynAlloca Expander
   0.0020 (  0.1%)   0.0007 (  0.2%)   0.0027 (  0.1%)   0.0027 (  0.1%)  Analyze Machine Code For Garbage Collection
   0.0019 (  0.1%)   0.0007 (  0.2%)   0.0026 (  0.1%)   0.0027 (  0.1%)  X86 Lower Tile Copy
   0.0020 (  0.1%)   0.0008 (  0.2%)   0.0028 (  0.1%)   0.0027 (  0.1%)  Lazy Machine Block Frequency Analysis #2
   0.0018 (  0.1%)   0.0008 (  0.2%)   0.0026 (  0.1%)   0.0027 (  0.1%)  Lower AMX intrinsics
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0027 (  0.1%)  Pseudo Probe Inserter
   0.0020 (  0.1%)   0.0008 (  0.2%)   0.0028 (  0.1%)   0.0027 (  0.1%)  Compressing EVEX instrs when possible
   0.0019 (  0.1%)   0.0008 (  0.2%)   0.0027 (  0.1%)   0.0026 (  0.1%)  Safe Stack instrumentation pass
   0.0017 (  0.1%)   0.0007 (  0.2%)   0.0025 (  0.1%)   0.0026 (  0.1%)  Lower Garbage Collection Instructions
   0.0000 (  0.0%)   0.0007 (  0.2%)   0.0007 (  0.0%)   0.0007 (  0.0%)  Assumption Cache Tracker
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Target Pass Configuration
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Create Garbage Collector Module Metadata
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Machine Branch Probability Analysis
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Machine Module Information
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Target Transform Information
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Target Library Information
   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)   0.0000 (  0.0%)  Profile summary info
   1.8065 (100.0%)   0.4459 (100.0%)   2.2524 (100.0%)   2.2726 (100.0%)  Total

===-------------------------------------------------------------------------===
                        Analysis execution timing report
===-------------------------------------------------------------------------===
  Total Execution Time: 0.0031 seconds (0.0031 wall clock)

   ---User Time---   --System Time--   --User+System--   ---Wall Time---  --- Name ---
   0.0014 ( 99.5%)   0.0017 (100.0%)   0.0031 ( 99.8%)   0.0031 ( 99.7%)  TargetLibraryAnalysis
   0.0000 (  0.3%)   0.0000 (  0.0%)   0.0000 (  0.1%)   0.0000 (  0.2%)  InnerAnalysisManagerProxy<FunctionAnalysisManager, Module>
   0.0000 (  0.2%)   0.0000 (  0.0%)   0.0000 (  0.1%)   0.0000 (  0.1%)  ProfileSummaryAnalysis
   0.0014 (100.0%)   0.0017 (100.0%)   0.0031 (100.0%)   0.0031 (100.0%)  Total

===-------------------------------------------------------------------------===
                          Pass execution timing report
===-------------------------------------------------------------------------===
  Total Execution Time: 0.0157 seconds (0.0158 wall clock)

   ---User Time---   --System Time--   --User+System--   ---Wall Time---  --- Name ---
   0.0040 ( 40.6%)   0.0053 ( 90.9%)   0.0093 ( 59.2%)   0.0093 ( 59.2%)  AnnotationRemarksPass
   0.0040 ( 40.2%)   0.0000 (  0.0%)   0.0040 ( 25.4%)   0.0040 ( 25.4%)  AlwaysInlinerPass
   0.0019 ( 19.0%)   0.0005 (  9.1%)   0.0024 ( 15.4%)   0.0024 ( 15.3%)  EntryExitInstrumenterPass
   0.0000 (  0.1%)   0.0000 (  0.0%)   0.0000 (  0.1%)   0.0000 (  0.1%)  CoroConditionalWrapper
   0.0099 (100.0%)   0.0058 (100.0%)   0.0157 (100.0%)   0.0158 (100.0%)  Total

===-------------------------------------------------------------------------===
                          Pass execution timing report
===-------------------------------------------------------------------------===
  Total Execution Time: 0.0157 seconds (0.0158 wall clock)

   ---User Time---   --System Time--   --User+System--   ---Wall Time---  --- Name ---
   0.0040 ( 40.6%)   0.0053 ( 90.9%)   0.0093 ( 59.2%)   0.0093 ( 59.2%)  AnnotationRemarksPass
   0.0040 ( 40.2%)   0.0000 (  0.0%)   0.0040 ( 25.4%)   0.0040 ( 25.4%)  AlwaysInlinerPass
   0.0019 ( 19.0%)   0.0005 (  9.1%)   0.0024 ( 15.4%)   0.0024 ( 15.3%)  EntryExitInstrumenterPass
   0.0000 (  0.1%)   0.0000 (  0.0%)   0.0000 (  0.1%)   0.0000 (  0.1%)  CoroConditionalWrapper
   0.0099 (100.0%)   0.0058 (100.0%)   0.0157 (100.0%)   0.0158 (100.0%)  Total

===-------------------------------------------------------------------------===
                        Analysis execution timing report
===-------------------------------------------------------------------------===
  Total Execution Time: 0.0031 seconds (0.0031 wall clock)

   ---User Time---   --System Time--   --User+System--   ---Wall Time---  --- Name ---
   0.0014 ( 99.5%)   0.0017 (100.0%)   0.0031 ( 99.8%)   0.0031 ( 99.7%)  TargetLibraryAnalysis
   0.0000 (  0.3%)   0.0000 (  0.0%)   0.0000 (  0.1%)   0.0000 (  0.2%)  InnerAnalysisManagerProxy<FunctionAnalysisManager, Module>
   0.0000 (  0.2%)   0.0000 (  0.0%)   0.0000 (  0.1%)   0.0000 (  0.1%)  ProfileSummaryAnalysis
   0.0014 (100.0%)   0.0017 (100.0%)   0.0031 (100.0%)   0.0031 (100.0%)  Total
```


## Build Times (Native x86 Backend)

This section will be for native x86 backend build timings.

