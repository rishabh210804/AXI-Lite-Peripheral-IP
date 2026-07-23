# 🚀 AXI4-Lite Peripheral IP Development & Verification

A robust, fully compliant **AXI4-Lite Slave Peripheral IP** designed in SystemVerilog/Verilog for FPGA SoC integration (MicroBlaze / Zynq ARM). Features complete 32-bit register mapping, bitwise processing logic, dynamic interrupt generation (`irq_out`), and decode error (`DECERR`) handling.

---

## 📌 Project Architecture & Register Map

The peripheral operates on a standard **4-bit address bus** (`0x0` to `0xF`) with a **32-bit data bus**.

| Address Offset | Register Name | Access Type | Description |
| :---: | :---: | :---: | :--- |
| **`0x00`** | `ctrl_reg` | Read/Write | Bit [0]: Enable Peripheral \| Bit [1]: Enable Interrupt |
| **`0x04`** | `status_reg` | Read-Only | Bit [0]: Busy Flag \| Bit [2]: Interrupt Pending |
| **`0x08`** | `data_in_reg` | Read/Write | Input Data Storage |
| **`0x0C`** | `data_out_reg` | Read-Only | Hardware Inverted Data Output (`~data_in_reg`) |
| **`0x0F`** | *Unmapped* | Read/Write | Returns `DECERR` (2'b11) & default payload (`0xDEADBEEF`) |

---

## 🛠️ Key Features & Protocol Compliance

* **AMBA AXI4-Lite Protocol Specification Compliant:** Full handshake implementation on Write Address (AW), Write Data (W), Write Response (B), Read Address (AR), and Read Data (R) channels.
* **Protocol Assertions:** SystemVerilog properties included to guarantee stability (e.g., ensuring `RVALID` holds until acknowledged by `RREADY`).
* **Interrupt Engine:** Active-high interrupt line (`irq_out`) driven upon processing completion.
* **Error Handling:** Robust address decoding with standard AXI response codes (`OKAY` vs `DECERR`).

---

## 📂 Repository Structure

```text
├── src/
│   ├── axi_peripheral.v       # Top-level AXI4-Lite Slave RTL Module
├── tb/
│   ├── tb_axil_peripheral.sv   # SystemVerilog Testbench & Protocol Assertions
│   └── tb_axl_peripheral.v    # Verilog-2001 Compliant Testbench
├── constraints/
│   └── constraints.xdc        # 100 MHz Timing & Clock Constraints
├── docs/
│   ├── Verification_Report.pdf # Detailed Compliance & Verification Report
│   └── Slide_Deck.pptx         # Presentation Slides
└── README.md                  # Project Documentation
