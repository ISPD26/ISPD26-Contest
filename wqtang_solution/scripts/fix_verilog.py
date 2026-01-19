#!/usr/bin/env python3
"""
Verilog preprocessing script
Usage: python fix_verilog.py <input_verilog_file> <output_verilog_file>
1. Remove all escape characters
2. Fix array bracket spacing - remove spaces between ] and [
3. Fix pin declarations - add missing input/output declarations based on usage
4. Ensure pin names appear only once in declarations
5. Move pin declarations to beginning of file
"""

import sys
import re
import os
from collections import OrderedDict


def extract_existing_declarations(content):
    """Extract existing wire, input, and output declarations"""
    wires = set()
    inputs = set()
    outputs = set()
    
    # Extract wire declarations
    wire_matches = re.findall(r'wire\s+([^;]+)', content)
    for match in wire_matches:
        pins = [pin.strip() for pin in match.split(',')]
        wires.update(pins)
    
    # Extract input/output declarations
    io_matches = re.findall(r'^\s*(input|output)\s+([^;]+)', content, re.MULTILINE)
    for io_type, pins_str in io_matches:
        pins = [pin.strip() for pin in pins_str.split(',')]
        if io_type == 'input':
            inputs.update(pins)
        else:
            outputs.update(pins)
    
    return wires, inputs, outputs


def find_pin_usage(content):
    """Find pins used in connections"""
    output_pins = set()
    input_pins = set()
    
    # Find pins used in .Y() and .QN() connections (outputs)
    y_matches = re.findall(r'\.Y\s*\(\s*([^)]+)\s*\)', content)
    for match in y_matches:
        pin = match.strip()
        if pin:
            output_pins.add(pin)
    
    qn_matches = re.findall(r'\.QN\s*\(\s*([^)]+)\s*\)', content)
    for match in qn_matches:
        pin = match.strip()
        if pin:
            output_pins.add(pin)
    
    # Find pins used in other connections (inputs)
    other_matches = re.findall(r'\.\w+\s*\(\s*([^)]+)\s*\)', content)
    for match in other_matches:
        pin = match.strip()
        if pin and pin not in output_pins:
            input_pins.add(pin)
    
    return output_pins, input_pins


def process_verilog(input_file, output_file):
    """Process the Verilog file"""
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found")
        return False
    
    # Read input file
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Step 1: Remove escape characters
    content = content.replace('\\', '')
    
    # Step 2: Fix array bracket spacing - remove spaces between ] and [
    content = re.sub(r'\]\s+\[', '][', content)
    
    # Step 3: Extract existing declarations
    existing_wires, existing_inputs, existing_outputs = extract_existing_declarations(content)
    
    # Step 4: Find pin usage
    used_output_pins, used_input_pins = find_pin_usage(content)
    
    # Step 5: Determine missing declarations (avoid duplicates)
    missing_outputs = OrderedDict()
    missing_inputs = OrderedDict()
    
    for pin in used_output_pins:
        if pin not in existing_wires and pin not in existing_inputs and pin not in existing_outputs:
            missing_outputs[pin] = True
    
    for pin in used_input_pins:
        if pin not in existing_wires and pin not in existing_inputs and pin not in existing_outputs:
            # Don't add as input if already identified as output
            if pin not in missing_outputs:
                missing_inputs[pin] = True
    
    # Step 6: Process the file structure
    lines = content.split('\n')
    output_lines = []
    input_pins_added = False
    output_pins_added = False
    
    for line in lines:
        output_lines.append(line)
        
        # Add input pins after "input clk;"
        if not input_pins_added and re.match(r'^\s*input\s+clk\s*;', line):
            for pin in missing_inputs:
                output_lines.append(f"   input {pin};")
            input_pins_added = True
        
        # Add output pins after "output done;"
        if not output_pins_added and re.match(r'^\s*output\s+done\s*;', line):
            for pin in missing_outputs:
                output_lines.append(f"   output {pin};")
            output_pins_added = True
    
    # Write output file
    with open(output_file, 'w') as f:
        f.write('\n'.join(output_lines))
    
    return True


def main():
    if len(sys.argv) != 3:
        print("Usage: python fix_verilog.py <input_verilog_file> <output_verilog_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if process_verilog(input_file, output_file):
        print(f"Preprocessing complete: {input_file} -> {output_file}")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()