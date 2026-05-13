# AXI-Engine

A SystemVerilog implementation of an AXI-Lite (AMBA AXI) protocol engine for high-performance hardware design and system integration along with a UVM verification environment. 

# Repository Structure

```
AXI-Engine/ 
├── rtl/ 
│ └── axi.sv
├── tb/ 
│ └── interface.sv
│ └── tb.sv
│ └── test.sv
├── script/ 
│ └── run.sh 
```

### Directory Details

- **`rtl/`** - SystemVerilog hardware modules implementing AXI protocol functionality
- **`tb/`** - Testbenches and verification suites for validating RTL behavior
- **`script/`** - Automation scripts  for building, simulating, and testing

## Environment and Tools Used
- EndeavourOS 
- SystemVerilog
- Bash
- Verilator w/ UVM v1.0 (IEEE 1800.2-2017)
- GTKWave


## Getting Started


**Clone the repository**:
   ``` bash
   git clone https://github.com/ethan-almeida/AXI-Engine.git
   cd AXI-Engine

   # Navigate to the script directory
   cd script/
   chmod +x run.sh

   # Execute the build/simulation script (it's designed such that you can execute it from anywhere in the project)
   ./script/run.sh -t | -c | -z 
   ```

## Usage
### Running Simulations

Execute the provided shell scripts in the script/ directory to compile and simulate the design:
``` bash
cd script
./run.sh
```

### Script modes

``` bash
./script/run.sh -t <test_name> #this runs a single test once
./script/run.sh -c #this cleans the project of all the auto-generated files i.e., obj-dir/ 

./script/run.sh -z #this zips the project
./script/run.sh -h #this is a help menu of all the commands supported by the script
```

### Viewing Waveforms

Simulation generates waveform files that can be inspected using:

    GTKWave (.vcd files)


### Build Artifacts

Generated files (ignored by .gitignore):

    obj_dir/ - Compiled simulation objects
    .vcd, .vpd, .wlf - Waveform dumps
    .log, .jou - Simulation logs and journals

# References

https://corsair.readthedocs.io/en/latest/axil.html#protocol
https://developer.arm.com/documentation/ihi0022/e/


