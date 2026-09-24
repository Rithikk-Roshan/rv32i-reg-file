# RV32I Synchronous Register File

A parameterized 32x32-bit general-purpose Register File implementing the architectural register state specifications for the RISC-V RV32I base integer instruction set.

## Architecture Highlights
- **32 Architectural Registers:** Standard 32-bit registers (`x0` through `x31`).
- **Hardwired Zero (x0):** Architectural invariant enforced via hardware write-protection and hardwired zero read routing.
- **Dual Asynchronous Read Ports:** Fully combinational dual read datapaths (`rs1_data`, `rs2_data`) allowing zero-cycle decode latency.
- **Synchronous Write Port:** Clock-edge triggered destination register updates with active-high write-enable gating.
- **Self-Checking Verification:** Automated testbench validating reset conditions, dual-port simultaneous reads, mid-cycle read latency, and x0 write-rejection.

## Implementation & Synthesis Metrics
Target Device: **AMD Xilinx Artix-7 (xc7a35tcpg236-1)**  
Toolchain: **Vivado 2024.2**

| Metric | Utilized | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **Slice LUTs** | 607 | 20,800 | 2.92% |
| **Slice Registers (FF)** | 992 | 41,600 | 2.38% |
| **Bonded IOB** | 114 | 106 | 107.55% |
| **DSP Slices** | 0 | 90 | 0.00% |
| **Block RAM** | 0 | 50 | 0.00% |

*\*Note: Bonded IOB exceeds physical package capacity because the module is synthesized out-of-context as an internal sub-block. All 114 ports are wired internally when integrated into the complete RV32I CPU core.*

### Synthesis Optimization Note
Synthesis automatically pruned the 32 flip-flops for register `x0` after recognizing the hardwired zero read logic, utilizing exactly 992 physical flip-flops ($31 \times 32\text{ bits}$) instead of the naive 1,024 allocation.
