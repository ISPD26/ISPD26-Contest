import sys
import re

if len(sys.argv) != 3:
    print("Usage: python3 fix_sdc.py <input sdc> <output sdc>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file, 'r') as f:
    lines = f.readlines()

with open(output_file, 'w') as f:
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('create_clock') and '-waveform' in stripped:
            match = re.match(r'create_clock\s+\[get_ports\s+{([^}]+)}\]\s+-name\s+(\S+)\s+-period\s+(\S+)\s+-waveform\s+{([^ ]+)\s+([^}]+)}', stripped)
            if match:
                Y, X, P, A, B = match.groups()
                f.write(f'create_clock [get_ports {{{Y}}}]  -name {X} -period {P}\n')
                f.write(f'set_input_delay {A} -min -rise [get_ports {{{Y}}}] -clock {X}\n')
                f.write(f'set_input_delay {B} -min -fall [get_ports {{{Y}}}] -clock {X}\n')
                f.write(f'set_input_delay {A} -max -rise [get_ports {{{Y}}}] -clock {X}\n')
                f.write(f'set_input_delay {B} -max -fall [get_ports {{{Y}}}] -clock {X}\n')
            else:
                f.write(line)
        elif stripped.startswith('set_max_transition'):
            f.write('# ' + line)
        elif stripped.startswith('set_propagated_clock'):
            f.write('# ' + line)
        elif stripped.startswith('current_design'):
            f.write('# ' + line)
        elif stripped.startswith('set_max_fanout'):
            # Match set_max_fanout command pattern
            match = re.match(r'set_max_fanout\s+(\S+)\s+\[get_designs\s+{[^}]+}\]', stripped)
            if match:
                fanout_value = match.group(1)
                # Replace [get_designs {xxx}] with [current_design]
                f.write(f'set_max_fanout {fanout_value} [current_design]\n')
            else:
                # Keep original line if pattern doesn't match
                f.write(line)
        else:
            f.write(line)