#!/usr/bin/env python3

import sys
import re

def repair_def(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Find the COMPONENTS section and replace FIXED with PLACED
    def replace_in_components(match):
        components_section = match.group(0)
        # Replace FIXED with PLACED in this section
        modified_section = components_section.replace('FIXED', 'PLACED')
        return modified_section
    
    # Pattern to match from "COMPONENTS <value> ;" to "END COMPONENTS"
    pattern = r'COMPONENTS\s+[^;]+\s*;.*?END COMPONENTS'
    
    # Replace FIXED with PLACED only in the COMPONENTS section
    modified_content = re.sub(pattern, replace_in_components, content, flags=re.DOTALL)
    
    with open(output_file, 'w') as f:
        f.write(modified_content)

def main():
    if len(sys.argv) != 3:
        print("Usage: scripts/repair_def.py <input def> <output def>")
        sys.exit(1)
    
    input_def = sys.argv[1]
    output_def = sys.argv[2]
    
    try:
        repair_def(input_def, output_def)
        print(f"Successfully repaired {input_def} -> {output_def}")
    except FileNotFoundError:
        print(f"Error: Input file '{input_def}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()