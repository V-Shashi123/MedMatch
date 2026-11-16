# MedMatch
## Offline Medicine-Strip Verification and Tracking System

### Project Overview
MedMatch is an offline medicine verification and tracking system developed using Verilog HDL in Xilinx Vivado.

### Main Modules
1. Patient Verification
2. Medicine Verification
3. Schedule Controller
4. Dose Tracker
5. Expiry Checker
6. MedMatch Controller
7. Alert Controller
8. IR Sensor Controller
9. Servo Controller
10. MFRC522 SPI Controller
11. DS3231 I2C Controller
12. LCD Controller

### Simulation Environment
- Xilinx Vivado 2023.2
- Verilog HDL
- Target FPGA: XC7S50CSGA324-1

### Simulation Results
Core verification testbench: 7/7 tests passed.
RFID SPI testbench: 3/3 tests passed.
RTC NACK-handling testbench: 3/3 tests passed.
LCD interface testbench: 2/2 tests passed.

### Project Scope
This project focuses on RTL development and behavioral simulation.

### Important Verification Notes
- RFID SPI tests verify basic transaction behaviour, not complete card UID extraction.
- RTC tests verify NACK handling, not successful reading from a simulated RTC slave.
- LCD tests verify interface activity and output validity, not complete character-by-character display correctness.
- Core verification tests use simulated patient and medicine IDs.
