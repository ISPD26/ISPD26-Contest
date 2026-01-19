#!/usr/bin/env python3

import os
import sys
import shutil
import glob
from pathlib import Path
import re

def parse_ppad_out(file_path):
    """Parse PPAD.out file and extract metrics."""
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        metrics = {}
        for line in lines:
            line = line.strip()
            if line.startswith('TNS:'):
                metrics['TNS'] = float(line.split(':')[1].strip())
            elif line.startswith('Power:'):
                metrics['Power'] = float(line.split(':')[1].strip())
            elif line.startswith('HPWL:'):
                metrics['HPWL'] = float(line.split(':')[1].strip())
            elif line.startswith('Displacement:'):
                metrics['Displacement'] = float(line.split(':')[1].strip())
        
        return metrics
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        return None

def is_better_solution(input_metrics, output_metrics):
    """Check if input solution is better than output solution."""
    if not input_metrics or not output_metrics:
        return False
    
    # Better if: TNS_in >= TNS_out AND Power_in <= Power_out AND HPWL_in <= HPWL_out AND Displacement_in <= Displacement_out
    return (input_metrics['TNS'] >= output_metrics['TNS'] and
            input_metrics['Power'] <= output_metrics['Power'] and
            input_metrics['HPWL'] <= output_metrics['HPWL'] and
            input_metrics['Displacement'] <= output_metrics['Displacement'])

def copy_required_files(src_folder, dst_folder):
    """Copy *.def, *.changelist, and PPAD.out files from src to dst."""
    os.makedirs(dst_folder, exist_ok=True)
    
    copied_files = []
    
    # Copy *.def files
    def_files = glob.glob(os.path.join(src_folder, '*.def'))
    for def_file in def_files:
        if def_file.endswith('.gp.def'):
            continue
        dst_file = os.path.join(dst_folder, os.path.basename(def_file))
        shutil.copy2(def_file, dst_file)
        copied_files.append(os.path.basename(def_file))
    
    # Copy *.changelist files
    changelist_files = glob.glob(os.path.join(src_folder, '*.changelist'))
    for changelist_file in changelist_files:
        dst_file = os.path.join(dst_folder, os.path.basename(changelist_file))
        shutil.copy2(changelist_file, dst_file)
        copied_files.append(os.path.basename(changelist_file))
    
    # Copy PPAD.out
    ppad_file = os.path.join(src_folder, 'PPAD.out')
    if os.path.exists(ppad_file):
        dst_file = os.path.join(dst_folder, 'PPAD.out')
        shutil.copy2(ppad_file, dst_file)
        copied_files.append('PPAD.out')
    
    # Check if all three required file types are present in the destination folder
    has_def = any(f.endswith('.def') for f in copied_files)
    has_changelist = any(f.endswith('.changelist') for f in copied_files)
    has_ppad = 'PPAD.out' in copied_files
    
    if not (has_def and has_changelist and has_ppad):
        missing_types = []
        if not has_def:
            missing_types.append('*.def')
        if not has_changelist:
            missing_types.append('*.changelist')
        if not has_ppad:
            missing_types.append('PPAD.out')
        
        print(f"Error: Folder '{dst_folder}' is missing required file types: {', '.join(missing_types)}")
    
    return copied_files

def main():
    if len(sys.argv) != 3:
        print("Usage: ./scripts/update_db.py <input_path> <output_path>")
        print("Example: scripts/update_db.py ./output/aes/ ./database/aes/")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    if not os.path.exists(input_path):
        print(f"Error: Input path {input_path} does not exist")
        sys.exit(1)
    
    os.makedirs(output_path, exist_ok=True)
    
    # Get all folders in input path
    input_folders = [f for f in os.listdir(input_path) 
                    if os.path.isdir(os.path.join(input_path, f))]
    
    new_solutions_count = 0
    
    # Handle 'original' folder first
    if 'original' in input_folders:
        src_original = os.path.join(input_path, 'original')
        dst_original = os.path.join(output_path, 'original')
        
        if not os.path.exists(dst_original):
            copied_files = copy_required_files(src_original, dst_original)
            print(f"Copied original folder with files: {copied_files}")
        else:
            print("Original folder already exists, skipping")
    
    
    # Process other folders
    for folder in input_folders:
        if folder == 'original':
            continue
        
        src_folder = os.path.join(input_path, folder)
        src_ppad = os.path.join(src_folder, 'PPAD.out')
        
        if not os.path.exists(src_ppad):
            continue
        
        input_metrics = parse_ppad_out(src_ppad)
        if not input_metrics:
            continue
        
        # Check if this solution is dominated by any existing solution
        is_dominated = False
        output_folders = [f for f in os.listdir(output_path) 
                         if os.path.isdir(os.path.join(output_path, f))]
        
        folders_to_remove = []
        for output_folder in output_folders:
            output_ppad = os.path.join(output_path, output_folder, 'PPAD.out')
            if os.path.exists(output_ppad):
                output_metrics = parse_ppad_out(output_ppad)
                if output_metrics:
                    if is_better_solution(output_metrics, input_metrics):
                        is_dominated = True
                    if is_better_solution(input_metrics, output_metrics) and input_metrics!=output_metrics:
                        # Mark folder for removal if input dominates output
                        if output_folder != 'original':  # Preserve original folder
                            folders_to_remove.append(output_folder)
                            # print(f"'{folder}' dominates '{output_folder}' - ({input_metrics['TNS']}, {input_metrics['Power']}, {input_metrics['HPWL']}, {input_metrics['Displacement']}) ({output_metrics['TNS']}, {output_metrics['Power']}, {output_metrics['HPWL']}, {output_metrics['Displacement']})")
        
        # Remove dominated folders
        for folder_to_remove in folders_to_remove:
            remove_path = os.path.join(output_path, folder_to_remove)
            try:
                shutil.rmtree(remove_path)
                print(f"Removed dominated solution: {folder_to_remove}")
            except Exception as e:
                print(f"Error removing {folder_to_remove}: {e}")
        
        if not is_dominated:
            dst_folder_name = folder
            dst_folder = os.path.join(output_path, dst_folder_name)
            
            # If folder already exists, append/increment numeric suffix
            if os.path.exists(dst_folder):
                m = re.match(r'^(.*?)(\d+)$', folder)
                if m:
                    base, num = m.group(1), int(m.group(2)) + 1
                else:
                    base, num = folder, 1
                while True:
                    candidate = f"{base}{num}"
                    dst_folder = os.path.join(output_path, candidate)
                    if not os.path.exists(dst_folder):
                        dst_folder_name = candidate
                        break
                    num += 1
            
            copy_required_files(src_folder, dst_folder)
            print(f"found a non-dominated solution {dst_folder_name} (tns={input_metrics['TNS']}, power={input_metrics['Power']}, hpwl={input_metrics['HPWL']}, disp.={input_metrics['Displacement']})")
            new_solutions_count += 1
    
    print(f"\nTotal new solutions found: {new_solutions_count}")

if __name__ == '__main__':
    main()