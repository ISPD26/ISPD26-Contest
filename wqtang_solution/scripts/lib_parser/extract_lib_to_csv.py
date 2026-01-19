#!/usr/bin/env python3
import re
import os
import csv

# -----------------------------
# Output paths and other settings
# -----------------------------
LIB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../testcases/ASAP7/LIB'))
OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), './'))

# Only process these two templates
DELAY_TEMPLATE_NAME = "delay_template_7x7_x1"          
POWER_TEMPLATE_NAME = "power_template_7x7_x1"          

# Training merge policies
DELAY_POLICY = 'rise'   # rise|fall|avg -> cell_rise/cell_fall
SLEW_POLICY = 'rise'    # rise|fall|avg -> rise_transition/fall_transition
POWER_POLICY = 'rise'    # rise|fall|avg -> rise_power/fall_power


def parse_index_list(s):
    # s like: "5, 10, 20, 40, 80, 160, 320"
    return [float(x.strip()) for x in s.strip().strip('"').split(',')]


def tokenize_lines(lines):
    # minimal line cleanup
    for ln in lines:
        # strip comments
        pos = ln.find("/*")
        if pos != -1:
            ln = ln[:pos]
        ln = ln.strip()
        if ln:
            yield ln


def extract_templates_from_content(content):
    """Extract templates from cell content using brace stack approach"""
    templates = {}
    brace_stack = []
    current_block = []
    block_type = None
    template_name = None
    
    for line in content:
        line = line.strip()
        if not line:
            continue
            
        # Start of template block
        if line.startswith('lu_table_template') or line.startswith('power_lut_template'):
            template_name = line.split('(')[1].split(')')[0].strip()
            block_type = 'template'
            brace_stack = []
            current_block = [line]
            continue
            
        if block_type == 'template':
            current_block.append(line)
            
            if '{' in line:
                brace_stack.append('{')
            if '}' in line:
                if brace_stack:
                    brace_stack.pop()
                if len(brace_stack) == 0:
                    # End of template block
                    template_data = parse_template_block(current_block, template_name)
                    if template_data:
                        templates[template_name] = template_data
                    block_type = None
                    current_block = []
                    template_name = None
    
    return templates


def parse_template_block(content, name):
    """Parse a single template block"""
    var1 = var2 = None
    idx1 = idx2 = None
    
    for line in content:
        if 'variable_1' in line:
            var1 = line.split(':')[1].split(';')[0].strip()
        if 'variable_2' in line:
            var2 = line.split(':')[1].split(';')[0].strip()
        if 'index_1' in line:
            idx1 = parse_index_list(line.split('("', 1)[1].rsplit('")', 1)[0])
        if 'index_2' in line:
            idx2 = parse_index_list(line.split('("', 1)[1].rsplit('")', 1)[0])
    
    # Only keep the two named templates we care about
    is_named_ok = name in (DELAY_TEMPLATE_NAME, POWER_TEMPLATE_NAME)
    is_vars_delay = (var1 == 'input_net_transition' and var2 == 'total_output_net_capacitance')
    is_vars_power = (var1 in ('input_transition_time', 'input_net_transition') and var2 == 'total_output_net_capacitance')
    
    if is_named_ok or is_vars_delay or is_vars_power:
        return {
            'var1': var1,
            'var2': var2,
            'idx1': idx1 or [],
            'idx2': idx2 or [],
        }
    return None


def parse_values_block(content, start_idx):
    """Parse values block from content lines"""
    vals = []
    i = start_idx
    # find first line containing 'values'
    while i < len(content) and 'values' not in content[i]:
        i += 1
    if i == len(content):
        return None, start_idx
    i += 1
    while i < len(content):
        l = content[i].strip()
        if l.startswith(')') or l.endswith(');'):
            break
        if '"' in l:
            s = l.split('"', 1)[1].rsplit('"', 1)[0]
            row = [float(x.strip()) for x in s.split(',')]
            vals.append(row)
        i += 1
    return vals, i


def extract_cell_data(content, templates, delay_writer, pwr_writer, acc):
    """Extract timing and power data from a single cell using brace stack approach"""
    cell_name = content[0].split('(')[1].split(')')[0].strip()

    brace_stack = []
    current_block = []
    block_type = None
    pin_name = None
    
    for line in content[1:]:  # Skip first line (cell declaration)
        line = line.strip()
        if not line:
            continue
            
        # Start of pin block (skip pg_pin)
        if line.startswith('pin (') and not line.startswith('pg_pin'):
            pin_name = line.split('(')[1].split(')')[0].strip()
            block_type = 'pin'
            brace_stack = []
            current_block = [line]
            continue
            
        # Start of timing block within pin
        if block_type == 'pin' and line.startswith('timing'):
            block_type = 'timing'
            brace_stack = []
            brace_stack.append('{')
            current_block = [line]
            continue
            
        # Start of internal_power block within pin
        if block_type == 'pin' and line.startswith('internal_power'):
            block_type = 'internal_power'
            brace_stack = []
            brace_stack.append('{')
            current_block = [line]
            continue
            
        if block_type in ['pin', 'timing', 'internal_power']:
            current_block.append(line)
            
            if '{' in line:
                brace_stack.append('{')
            if '}' in line:
                if brace_stack:
                    brace_stack.pop()
                if len(brace_stack) == 0:
                    # End of block
                    if block_type == 'timing':
                        process_timing_block(current_block, cell_name, pin_name, templates, delay_writer, acc)
                    elif block_type == 'internal_power':
                        process_power_block(current_block, cell_name, pin_name, templates, pwr_writer, acc)
                    
                    if block_type in ['timing', 'internal_power']:
                        block_type = 'pin'  # Back to pin level
                    else:
                        block_type = None
                        pin_name = None
                    current_block = []


def process_timing_block(content, cell_name, pin_name, templates, delay_writer, acc):
    """Process a timing() block"""
    # Extract related_pin
    related = None
    for line in content:
        if 'related_pin' in line:
            related = line.split(':')[1].split(';')[0].strip().strip('"')
            break
    
    from_pin_key = related or ''
    has_cell_rise = False
    
    for key in acc:
        if (len(key) >= 3 and key[0] == cell_name and 
            key[1] == from_pin_key and key[2] == pin_name):
            metrics = acc[key]
            if 'cell_rise' in metrics:
                has_cell_rise = True
    
    if has_cell_rise :
        return

    # Extract timing tables
    i = 0
    while i < len(content):
        line = content[i].strip()
        if line.startswith('cell_rise') or line.startswith('cell_fall') \
           or line.startswith('rise_transition') or line.startswith('fall_transition'):
            block = line.split('(')[0].strip()
            tmpl = line.split('(')[1].split(')')[0].strip()
            
            # Extract local index values if present in this block
            local_idx1 = None
            local_idx2 = None
            j = i + 1
            while j < len(content) and not content[j].strip().startswith('values'):
                if 'index_1' in content[j]:
                    local_idx1 = parse_index_list(content[j].split('("', 1)[1].rsplit('")', 1)[0])
                if 'index_2' in content[j]:
                    local_idx2 = parse_index_list(content[j].split('("', 1)[1].rsplit('")', 1)[0])
                j += 1
            
            if tmpl in templates:
                vals, next_i = parse_values_block(content, i)
                if vals is not None:
                    t = templates[tmpl]
                    # Use local indices if available, otherwise fall back to template
                    idx1 = local_idx1 if local_idx1 is not None else t['idx1']
                    idx2 = local_idx2 if local_idx2 is not None else t['idx2']
                    
                    for r, row in enumerate(vals):
                        for c, v in enumerate(row):
                            in_slew = idx1[r] if r < len(idx1) else None
                            c_load = idx2[c] if c < len(idx2) else None
                            if delay_writer is not None:
                                delay_writer.writerow({
                                    'cell_type': cell_name,
                                    'from_pin': related or '',
                                    'to_pin': pin_name,
                                    'input_slew': in_slew,
                                    'C_load': c_load,
                                    'metric': block,
                                    'value': v,
                                })
                            if in_slew is not None and c_load is not None:
                                key = (cell_name, related or '', pin_name, float(in_slew), float(c_load))
                                acc.setdefault(key, {})[block] = float(v)
                i = next_i    
                continue        
            else:
                # Skip unknown template - just move to next line
                _, next_i = parse_values_block(content, i)
                i = next_i
                continue
        i += 1   


def process_power_block(content, cell_name, pin_name, templates, pwr_writer, acc):
    """Process an internal_power() block"""
    has_vss = any('VSS' in line and ':' in line for line in content)
    if has_vss:
        return  # Skip timing blocks with when conditions

    # Extract related_pin
    related = None
    for line in content:
        if 'related_pin' in line:
            related = line.split(':')[1].split(';')[0].strip().strip('"')
            break
    
    # Check if we already have both rise_power and fall_power for this from_pin
    # Look for any existing key in acc that matches (cell_name, related, pin_name, *, *)
    from_pin_key = related or ''
    has_rise_power = False
    has_fall_power = False
    
    for key in acc:
        if (len(key) >= 3 and key[0] == cell_name and 
            key[1] == from_pin_key and key[2] == pin_name):
            metrics = acc[key]
            if 'rise_power' in metrics:
                has_rise_power = True
            if 'fall_power' in metrics:
                has_fall_power = True
    
    # If we already have both rise_power and fall_power, skip this block
    if has_rise_power and has_fall_power:
        return
    
    # Extract power tables
    i = 0
    while i < len(content):
        line = content[i].strip()
        if line.startswith('rise_power') or line.startswith('fall_power'):
            block = line.split('(')[0].strip()
            tmpl = line.split('(')[1].split(')')[0].strip()
            
            # Extract local index values if present in this block
            local_idx1 = None
            local_idx2 = None
            j = i + 1
            while j < len(content) and not content[j].strip().startswith('values'):
                if 'index_1' in content[j]:
                    local_idx1 = parse_index_list(content[j].split('("', 1)[1].rsplit('")', 1)[0])
                if 'index_2' in content[j]:
                    local_idx2 = parse_index_list(content[j].split('("', 1)[1].rsplit('")', 1)[0])
                j += 1
            
            if tmpl in templates:
                vals, next_i = parse_values_block(content, i)
                if vals is not None:
                    t = templates[tmpl]
                    # Use local indices if available, otherwise fall back to template
                    idx1 = local_idx1 if local_idx1 is not None else t['idx1']
                    idx2 = local_idx2 if local_idx2 is not None else t['idx2']
                    
                    for r, row in enumerate(vals):
                        for c, v in enumerate(row):
                            in_slew = idx1[r] if r < len(idx1) else None
                            c_load = idx2[c] if c < len(idx2) else None
                            if pwr_writer is not None:
                                pwr_writer.writerow({
                                    'cell_type': cell_name,
                                    'from_pin': related or '',
                                    'to_pin': pin_name,
                                    'input_slew': in_slew,
                                    'C_load': c_load,
                                    'metric': block,
                                    'value': v,
                                })
                            if in_slew is not None and c_load is not None:
                                key = (cell_name, related or '', pin_name, float(in_slew), float(c_load))
                                acc.setdefault(key, {})[block] = float(v)
                i = next_i      
                continue        
            else:
                # Skip unknown template - just move to next line
                _, next_i = parse_values_block(content, i)
                i = next_i
                continue
        i += 1   


def parse_size_from_cell(cell_name: str) -> float:
    # try patterns like *_x1, *_X2, or drive in suffix
    m = re.search(r'[xX]([0-9]+)$', cell_name)
    if m:
        try:
            return float(m.group(1))
        except Exception:
            return 1.0
    return 1.0


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    inputs = [
        os.path.join(LIB_DIR, f)
        for f in sorted(os.listdir(LIB_DIR))
        if f.endswith('.lib') and not f.lower().startswith('sram')
    ]

    if not inputs:
        raise SystemExit(f'No .lib files found in {LIB_DIR}')

    # Raw outputs
    delay_raw_path = os.path.join(OUT_DIR, 'delay_raw.csv')
    power_raw_path = os.path.join(OUT_DIR, 'power_raw.csv')
    fd = open(delay_raw_path, 'w', newline='')
    fp = open(power_raw_path, 'w', newline='')
    dfield = ['cell_type', 'from_pin', 'to_pin', 'input_slew', 'C_load', 'metric', 'value']
    pfield = ['cell_type', 'from_pin', 'to_pin', 'input_slew', 'C_load', 'metric', 'value']
    dw = csv.DictWriter(fd, fieldnames=dfield)
    pw = csv.DictWriter(fp, fieldnames=pfield)
    dw.writeheader()
    pw.writeheader()

    acc = {}
    templates_global = None
    
    for libp in inputs:
        print(f"Processing {libp}...")
        with open(libp, 'r') as f:
            raw = f.readlines()
        lines = list(tokenize_lines(raw))
        
        # Extract templates only once
        if templates_global is None:
            templates_global = extract_templates_from_content(lines)
            print(f"Found templates: {list(templates_global.keys())}")

        # Process cells using brace stack approach
        brace_stack = []
        content = []
        
        for idx, line in enumerate(lines):
            if line.strip().startswith("cell ("):
                brace_stack = ["{"]
                content = [line]
                continue
            elif "{" in line:
                brace_stack.append("{")
            elif "}" in line:
                if brace_stack and brace_stack[-1] == "{":
                    brace_stack.pop()
                    if len(brace_stack) == 0:
                        # End of cell
                        content.append(line)
                        extract_cell_data(content, templates_global, dw, pw, acc)
                        content = []
                        continue
                else:
                    # print(f"Brace error at line {idx}")
                    break
            if content:  # Only append if we're in a cell
                content.append(line)

    fd.close()
    fp.close()

    # Training outputs
    delay_train_path = os.path.join(OUT_DIR, 'delay_train.csv')
    power_train_path = os.path.join(OUT_DIR, 'power_train.csv')

    with open(delay_train_path, 'w', newline='') as fo:
        w = csv.DictWriter(fo, fieldnames=['cell_type', 'from_pin', 'to_pin', 'input_slew', 'C_load', 'D_cell', 'output_slew'])
        w.writeheader()
        for (cell, frm, to, slew, cload), m in acc.items():
            # delay per policy
            if DELAY_POLICY == 'rise':
                d_val = m.get('cell_rise')
            elif DELAY_POLICY == 'fall':
                d_val = m.get('cell_fall')
            else:
                vals = [v for k, v in m.items() if k in ('cell_rise', 'cell_fall')]
                d_val = sum(vals) / len(vals) if len(vals) else None
            # slew per policy
            if SLEW_POLICY == 'rise':
                s_val = m.get('rise_transition')
            elif SLEW_POLICY == 'fall':
                s_val = m.get('fall_transition')
            else:
                vals = [v for k, v in m.items() if k in ('rise_transition', 'fall_transition')]
                s_val = sum(vals) / len(vals) if len(vals) else None
            if d_val is None or s_val is None:
                continue
            w.writerow({'cell_type': cell, 'from_pin': frm, 'to_pin': to, 'input_slew': slew, 'C_load': cload,
                        'D_cell': d_val, 'output_slew': s_val})

    with open(power_train_path, 'w', newline='') as fo:
        w = csv.DictWriter(fo, fieldnames=['cell_type', 'from_pin', 'to_pin', 'input_slew', 'C_load', 'P_internal'])
        w.writeheader()
        for (cell, frm, to, slew, cload), m in acc.items():
            if POWER_POLICY == 'rise':
                p_val = m.get('rise_power')
            elif POWER_POLICY == 'fall':
                p_val = m.get('fall_power')
            else:
                vals = [v for k, v in m.items() if k in ('rise_power', 'fall_power')]
                p_val = sum(vals) / len(vals) if len(vals) else None
            if p_val is None:
                continue
            w.writerow({'cell_type': cell, 'from_pin': frm, 'to_pin': to, 'input_slew': slew, 'C_load': cload,
                        'P_internal': p_val})

    print(f'Done. Wrote:\n  {delay_raw_path}\n  {power_raw_path}\n  {delay_train_path}\n  {power_train_path}')


if __name__ == '__main__':
    main()
