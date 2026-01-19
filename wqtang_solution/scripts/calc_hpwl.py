#!/usr/bin/env python3

import sys
import os
import torch
import numpy as np
from collections import defaultdict
import re

# Add DREAMPlace to path
dreamplace_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'extpkgs', 'DREAMPlace_install')
sys.path.append(dreamplace_path)

try:
    from dreamplace.ops.hpwl import hpwl
    from dreamplace.ops.pin_pos import pin_pos
except ImportError as e:
    print(f"Error importing DREAMPlace modules: {e}")
    print("Make sure DREAMPlace is properly installed and compiled.")
    sys.exit(1)

class LEFParser:
    def __init__(self):
        self.macros = {}
        
    def parse_lef_files(self, lef_paths):
        """Parse LEF files to extract pin offsets for each macro"""
        for lef_path in lef_paths:
            if os.path.exists(lef_path):
                self._parse_lef_file(lef_path)
    
    def _parse_lef_file(self, lef_path):
        """Parse a single LEF file"""
        try:
            with open(lef_path, 'r') as f:
                content = f.read()
            
            # Find all MACRO definitions
            macro_matches = re.finditer(r'MACRO\s+(\S+).*?END\s+\1', content, re.DOTALL)
            for match in macro_matches:
                macro_name = match.group(1)
                macro_content = match.group(0)
                self._parse_macro(macro_name, macro_content)
                
        except Exception as e:
            print(f"Warning: Could not parse LEF file {lef_path}: {e}")
    
    def _parse_macro(self, macro_name, macro_content):
        """Parse a macro definition to extract pin information"""
        pins = {}
        
        # Find all PIN definitions
        pin_matches = re.finditer(r'PIN\s+(\S+).*?END\s+\1', macro_content, re.DOTALL)
        for match in pin_matches:
            pin_name = match.group(1)
            pin_content = match.group(0)
            
            # Extract pin position from PORT/LAYER section
            port_match = re.search(r'PORT.*?LAYER.*?RECT\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)', pin_content, re.DOTALL)
            if port_match:
                x1, y1, x2, y2 = map(float, port_match.groups())
                # Use center of pin rectangle as offset
                pin_x = (x1 + x2) / 2
                pin_y = (y1 + y2) / 2
                pins[pin_name] = {'x': pin_x, 'y': pin_y}
        
        if pins:
            self.macros[macro_name] = pins

class DEFParser:
    def __init__(self, lef_parser=None, ignore_net_degree=100):
        self.cells = {}
        self.nets = {}
        self.io_pins = {}
        self.pins = []
        self.cell_to_pins = defaultdict(list)
        self.lef_parser = lef_parser
        self.ignore_net_degree = ignore_net_degree
        
    def parse_def(self, def_file):
        """Parse DEF file and extract placement and netlist information"""
        with open(def_file, 'r') as f:
            content = f.read()
        
        # Parse components
        self._parse_components(content)
        
        # Parse IO pins
        self._parse_io_pins(content)
        
        # Parse nets
        self._parse_nets(content)
        
        return self._build_hpwl_data()
    
    def _parse_components(self, content):
        """Parse COMPONENTS section"""
        components_section = re.search(r'COMPONENTS\s+(\d+)\s*;(.*?)END\s+COMPONENTS', content, re.DOTALL)
        if not components_section:
            return
        
        components_text = components_section.group(2)
        
        # Parse each component
        for line in components_text.split('\n'):
            line = line.strip()
            if line.startswith('-'):
                match = re.search(r'-\s+(\S+)\s+(\S+).*?PLACED\s*\(\s*(\d+)\s+(\d+)\s*\)', line)
                if match:
                    comp_name = match.group(1)
                    macro_name = match.group(2)
                    x = float(match.group(3))
                    y = float(match.group(4))
                    
                    self.cells[comp_name] = {
                        'name': comp_name,
                        'macro': macro_name,
                        'x': x,
                        'y': y
                    }
    
    def _parse_io_pins(self, content):
        """Parse PINS section for IO pins"""
        pins_section = re.search(r'PINS\s+(\d+)\s*;(.*?)END\s+PINS', content, re.DOTALL)
        if not pins_section:
            return
        
        pins_text = pins_section.group(2)
        
        # Parse each IO pin - handle multi-line definitions
        pin_definitions = re.findall(r'-\s+(\S+)\s+\+\s+NET\s+(\S+).*?PLACED\s*\(\s*(\d+)\s+(\d+)\s*\)\s*(\S+)\s*;', pins_text, re.DOTALL)
        
        for pin_def in pin_definitions:
            pin_name = pin_def[0]
            net_name = pin_def[1] 
            x = float(pin_def[2])
            y = float(pin_def[3])
            
            self.io_pins[pin_name] = {
                'name': pin_name,
                'net': net_name,
                'x': x,
                'y': y
            }
    
    def _parse_nets(self, content):
        """Parse NETS section"""
        nets_section = re.search(r'NETS\s+(\d+)\s*;(.*?)END\s+NETS', content, re.DOTALL)
        if not nets_section:
            return
        
        nets_text = nets_section.group(2)
        
        # Parse each net
        current_net = None
        for line in nets_text.split('\n'):
            line = line.strip()
            if line.startswith('-'):
                # New net
                match = re.search(r'-\s+(\S+)', line)
                if match:
                    net_name = match.group(1)
                    current_net = {
                        'name': net_name,
                        'pins': []
                    }
                    self.nets[net_name] = current_net
                
                # Parse pins in the same line
                self._parse_net_pins(line, current_net)
            
            elif current_net and ('(' in line or ')' in line):
                # Continue parsing pins
                self._parse_net_pins(line, current_net)
    
    def _parse_net_pins(self, line, net):
        """Parse pins from a net line"""
        if not net:
            return
        
        # Find all pin connections: ( CELL_NAME PIN_NAME )
        pin_matches = re.findall(r'\(\s*(\S+)\s+(\S+)\s*\)', line)
        for cell_name, pin_name in pin_matches:
            if cell_name in self.cells and cell_name != 'PIN':
                net['pins'].append({
                    'cell': cell_name,
                    'pin': pin_name,
                    'type': 'cell'
                })
            elif cell_name == 'PIN' and pin_name in self.io_pins:
                # This is an IO pin connection
                net['pins'].append({
                    'cell': pin_name,  # Use pin name as cell name for IO pins
                    'pin': pin_name,
                    'type': 'io'
                })
    
    def _build_hpwl_data(self):
        """Build data structures for HPWL calculation matching native DREAMPlace"""
        # Create pin list with accurate positions using pin offsets
        pin_positions = []
        flat_netpin = []
        netpin_start = [0]
        net_weights = []
        net_mask = []
        
        valid_nets = []
        filtered_nets = []
        
        for net_name, net in self.nets.items():
            net_pins = []
            
            for pin_info in net['pins']:
                cell_name = pin_info['cell']
                pin_name = pin_info['pin']
                pin_type = pin_info.get('type', 'cell')
                
                if pin_type == 'cell' and cell_name in self.cells:
                    cell = self.cells[cell_name]
                    
                    # Calculate pin position with offset if available
                    pin_x = cell['x']
                    pin_y = cell['y']
                    
                    # Add pin offset from LEF if available
                    if (self.lef_parser and 
                        cell['macro'] in self.lef_parser.macros and
                        pin_name in self.lef_parser.macros[cell['macro']]):
                        pin_offset = self.lef_parser.macros[cell['macro']][pin_name]
                        pin_x += pin_offset['x']
                        pin_y += pin_offset['y']
                    
                    pin_positions.append([pin_x, pin_y])
                    net_pins.append(len(pin_positions) - 1)
                    
                elif pin_type == 'io' and pin_name in self.io_pins:
                    io_pin = self.io_pins[pin_name]
                    pin_x = io_pin['x']
                    pin_y = io_pin['y']
                    
                    pin_positions.append([pin_x, pin_y])
                    net_pins.append(len(pin_positions) - 1)
            
            # Apply net filtering like native DREAMPlace
            if len(net_pins) >= 2:  # Only consider nets with 2+ pins
                valid_nets.append(net_name)
                
                # Check if net should be masked (filtered) due to high degree
                if len(net_pins) <= self.ignore_net_degree:
                    flat_netpin.extend(net_pins)
                    netpin_start.append(len(flat_netpin))
                    net_weights.append(1.0)  # Equal weight for all nets
                    net_mask.append(1)  # Include this net
                else:
                    # High-degree net - add to structure but mask it out
                    flat_netpin.extend(net_pins)
                    netpin_start.append(len(flat_netpin))
                    net_weights.append(1.0)
                    net_mask.append(0)  # Mask out this net
                    filtered_nets.append(net_name)
        
        print(f"Filtered {len(filtered_nets)} high-degree nets (>{self.ignore_net_degree} pins)")
        
        return {
            'pin_positions': np.array(pin_positions, dtype=np.float32),
            'flat_netpin': np.array(flat_netpin, dtype=np.int32),
            'netpin_start': np.array(netpin_start, dtype=np.int32),
            'net_weights': np.array(net_weights, dtype=np.float32),
            'net_mask': np.array(net_mask, dtype=np.uint8),
            'num_nets': len(valid_nets),
            'num_pins': len(pin_positions),
            'valid_nets': valid_nets,
            'filtered_nets': filtered_nets
        }

def calculate_hpwl_dreamplace(def_file, lef_paths=None, use_cuda=False, ignore_net_degree=100, apply_dreamplace_scaling=False):
    """Calculate HPWL using DREAMPlace kernel matching native implementation"""
    
    # Parse LEF files if provided
    lef_parser = None
    if lef_paths:
        lef_parser = LEFParser()
        lef_parser.parse_lef_files(lef_paths)
        print(f"Parsed {len(lef_parser.macros)} macros from LEF files")
    
    # Parse DEF file
    parser = DEFParser(lef_parser=lef_parser, ignore_net_degree=ignore_net_degree)
    data = parser.parse_def(def_file)
    
    if data['num_pins'] == 0:
        print("No valid pins found in DEF file")
        return 0.0
    
    active_nets = sum(data['net_mask'])
    print(f"Parsed {data['num_pins']} pins and {data['num_nets']} nets ({active_nets} active)")
    print(f"IO pins found: {len(parser.io_pins)}")
    
    # Convert to PyTorch tensors
    device = torch.device('cuda' if use_cuda and torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    # Pin positions: [x1, x2, ..., xn, y1, y2, ..., yn] (native DREAMPlace format)
    pin_pos = data['pin_positions'].copy()
    
    # Apply DREAMPlace coordinate scaling if requested
    if apply_dreamplace_scaling:
        # DREAMPlace scaling parameters from log:
        # The log shows "scale back by 0.0185185" which means it scales up by 54 then back down
        # For the initial HPWL calculation, we need to use the unscaled coordinates
        # The value 31968358.000 appears to be calculated without the final scaling
        shift_x, shift_y = 1008.0, 1008.0
        
        print(f"Applying DREAMPlace coordinate transformation: shift=({shift_x}, {shift_y})")
        
        # Apply coordinate transformation: just shift, don't scale
        # DREAMPlace calculates HPWL on the shifted but unscaled coordinates
        pin_pos[:, 0] = pin_pos[:, 0] - shift_x  # X coordinates
        pin_pos[:, 1] = pin_pos[:, 1] - shift_y  # Y coordinates
    
    pos_tensor = torch.from_numpy(np.concatenate([pin_pos[:, 0], pin_pos[:, 1]])).to(device)
    
    flat_netpin = torch.from_numpy(data['flat_netpin']).to(device)
    netpin_start = torch.from_numpy(data['netpin_start']).to(device)
    net_weights = torch.from_numpy(data['net_weights']).to(device)
    net_mask = torch.from_numpy(data['net_mask']).to(device)
    
    # Create HPWL calculator with native DREAMPlace settings
    hpwl_calculator = hpwl.HPWL(
        flat_netpin=flat_netpin,
        netpin_start=netpin_start,
        net_weights=net_weights,
        net_mask=net_mask,
        algorithm='net-by-net'  # Native DREAMPlace default
    )
    
    # Calculate HPWL
    with torch.no_grad():
        total_hpwl = hpwl_calculator(pos_tensor)
    
    return total_hpwl.item()

def find_lef_files(lib_path):
    """Find all LEF files in the library path"""
    lef_files = []
    
    if not lib_path or not os.path.exists(lib_path):
        return lef_files
    
    # Look for tech LEF files
    tech_lef_dir = os.path.join(lib_path, 'techlef')
    if os.path.exists(tech_lef_dir):
        for file in os.listdir(tech_lef_dir):
            if file.endswith('.lef'):
                lef_files.append(os.path.join(tech_lef_dir, file))
    
    # Look for macro LEF files  
    macro_lef_dir = os.path.join(lib_path, 'LEF')
    if os.path.exists(macro_lef_dir):
        for file in os.listdir(macro_lef_dir):
            if file.endswith('.lef'):
                lef_files.append(os.path.join(macro_lef_dir, file))
    
    return sorted(lef_files)

def main():
    if len(sys.argv) < 2:
        print("Usage: python calc_hpwl.py <def_file> [lib_path] [options]")
        print("  def_file: Path to DEF file")
        print("  lib_path: Optional path to library directory with LEF files")
        print("  options:")
        print("    --cuda: Enable GPU acceleration")
        print("    --ignore-net-degree N: Filter nets with >N pins (default: 100)")
        print("    --dreamplace-scaling: Apply DREAMPlace coordinate scaling")
        print("    --verbose: Enable verbose output")
        sys.exit(1)
    
    def_file = sys.argv[1]
    lib_path = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith('--') else None
    
    # Parse options
    use_cuda = '--cuda' in sys.argv
    ignore_net_degree = 100
    verbose = '--verbose' in sys.argv
    apply_dreamplace_scaling = '--dreamplace-scaling' in sys.argv
    
    # Parse ignore-net-degree option
    for i, arg in enumerate(sys.argv):
        if arg == '--ignore-net-degree' and i + 1 < len(sys.argv):
            try:
                ignore_net_degree = int(sys.argv[i + 1])
            except ValueError:
                print(f"Invalid ignore-net-degree value: {sys.argv[i + 1]}")
                sys.exit(1)
    
    if not os.path.exists(def_file):
        print(f"Error: DEF file {def_file} not found")
        sys.exit(1)
    
    # Find LEF files
    lef_files = find_lef_files(lib_path) if lib_path else []
    
    if verbose:
        print(f"DEF file: {def_file}")
        print(f"Library path: {lib_path}")
        print(f"LEF files found: {len(lef_files)}")
        print(f"Use CUDA: {use_cuda}")
        print(f"Ignore net degree: {ignore_net_degree}")
        print(f"DREAMPlace scaling: {apply_dreamplace_scaling}")
    
    try:
        hpwl_value = calculate_hpwl_dreamplace(
            def_file, 
            lef_paths=lef_files, 
            use_cuda=use_cuda, 
            ignore_net_degree=ignore_net_degree,
            apply_dreamplace_scaling=apply_dreamplace_scaling
        )
        print(f"HPWL: {hpwl_value:.2f}")
        
    except Exception as e:
        print(f"Error calculating HPWL: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()