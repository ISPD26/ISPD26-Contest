import json
import os
def cell_extraction(content,cell_map):
    cell_name = content[0].split("(")[1].split(")")[0]
    # Extract VT (voltage threshold) from cell name - part after the last underscore
    vt = ""
    if "_" in cell_name:
        vt = cell_name.split("_")[-1]
    
    cell_info = {
            "cell_name":cell_name,
            "vt":vt,
            "area":-1.0,
            "width":"",
            "height":"",
            "pin_info":{}
            }
    pin_info = {}
    # Collect leakage_power values for related_pg_pin == VDD
    leakage_values = []
    in_leakage_block = False
    cur_leak_value = None
    cur_leak_related = None
    pin_name = ""
    pin_type = ""  # "pin" or "bus"
    for line in content:
        # Detect both pin() and bus() declarations
        if(("pin (" in line and "pg_pin" not in line) or ("bus (" in line)):
            # Finalize previous pin/bus if exists
            if(pin_info != {}):
                # Print function for finalized output pin if available
                if pin_info.get("direction", "") == "output":
                    print(cell_info["cell_name"], pin_name, "function:", pin_info.get("function", ""))
                cell_info["pin_info"][pin_name]=pin_info
                pin_info = {}
            
            # Extract pin/bus name and type
            pin_name = line.split("(")[1].split(")")[0]
            pin_type = "bus" if "bus (" in line else "pin"
            print(cell_info["cell_name"], pin_name, f"({pin_type})")
            
            pin_info = {
                    "name": pin_name,
                    "type": pin_type,
                    "direction":"",
                    "max_capacitance":"",
                    "capacitance":"",
                    "rise_capacitance":"",
                    "fall_capacitance":"",
                    "function":"",
                    "bus_type":"",  # for bus pins
                    }
        # Start of leakage_power block
        if ("leakage_power" in line) and ("{" in line):
            in_leakage_block = True
            cur_leak_value = None
            cur_leak_related = None
            continue
        # Inside leakage_power block, parse fields
        if in_leakage_block:
            if ("value :" in line):
                try:
                    val_str = line.split(":")[1].split(";")[0].strip()
                    if val_str.startswith('"') and val_str.endswith('"'):
                        val_str = val_str[1:-1]
                    cur_leak_value = float(val_str)
                except Exception:
                    pass
            elif ("related_pg_pin" in line):
                related = line.split(":")[1].split(";")[0].strip()
                related = related.replace('"','')
                cur_leak_related = related
            elif ("}" in line):
                # End of this leakage_power block
                if (cur_leak_related is not None) and (cur_leak_related.upper() == 'VDD') and (cur_leak_value is not None):
                    leakage_values.append(cur_leak_value)
                in_leakage_block = False
                cur_leak_value = None
                cur_leak_related = None
        elif ("direction :" in line and pin_info!={}):
            pin_info["direction"] = line.split(":")[1].split(";")[0].strip()
        elif ("function :" in line and pin_info!={} and pin_info.get("direction", "") == "output"):
            # Extract boolean function only for output pins, skip power_down_function
            if "power_down_function" not in line:
                func = line.split(":")[1].split(";")[0].strip()
                if func.startswith('"') and func.endswith('"'):
                    func = func[1:-1]
                pin_info["function"] = func
        elif ("area :" in line):
            cell_info["area"] = line.split(":")[1].split(";")[0].strip()
        elif ("max_capacitance :" in line and pin_info!={}):
            pin_info["max_capacitance"] = line.split(":")[1].split(";")[0].strip()
        elif ("rise_capacitance :" in line and pin_info!={}):
            pin_info["rise_capacitance"] = line.split(":")[1].split(";")[0].strip()
        elif ("fall_capacitance :" in line and pin_info!={}):
            pin_info["fall_capacitance"] = line.split(":")[1].split(";")[0].strip()
        elif ("capacitance :" in line and pin_info!={}):
            pin_info["capacitance"] = line.split(":")[1].split(";")[0].strip()
        elif ("bus_type :" in line and pin_info!={}):
            pin_info["bus_type"] = line.split(":")[1].split(";")[0].strip()
    if(pin_info!={}):
        # Print function for the last pin in the cell if it is output
        if pin_info.get("direction", "") == "output":
            print(cell_info["cell_name"], pin_name, "function:", pin_info.get("function", ""))
        cell_info["pin_info"][pin_name]=pin_info
    # Average leakage power over VDD-related entries
    if len(leakage_values) > 0:
        cell_info["leakage_power"] = sum(leakage_values) / len(leakage_values)
    else:
        cell_info["leakage_power"] = 0.0
    #print(cell_info)
    cell_map[cell_info["cell_name"]] = cell_info
    

def lib_extraction(f, cell_map):
    lines = f.readlines()

    brace_stack = [];
    content = []
    for idx, line in enumerate(lines):
        if(line.strip().startswith("cell (")):
            brace_stack = []
            brace_stack.append("{")
            content = []
            content.append(line)
            continue
        elif "{" in line:
            brace_stack.append("{")
            #print(str(idx)+" append "+str(brace_stack))
    
        elif "}" in line:
            #print(str(brace_stack),end=" ")
            if(len(brace_stack)==0 or  brace_stack[-1]=="{"):
                if(len(brace_stack)!=0):
                    brace_stack.pop()
                #print(str(idx+1)+" "+str(brace_stack))
                if(len(brace_stack)==0):
                    print("get--------------")
                    content.append(line)
                    cell_extraction(content,cell_map)
                    continue
            else:
                print("-----------------error for brace--------------")
                exit(1)
        content.append(line)
    json_cell_map = json.dumps(cell_map)

    #print(json_cell_map)

def lef_extraction(f, cell_map):
    lines = f.readlines()
    title_stack = []
    content = []
    cell_name = ""
    pin_name = ""
    for idx, line in enumerate(lines):
        if(line.strip().startswith("MACRO ")):
            cell_name = line.strip().split(" ")[1]
            continue
        elif (line.strip().startswith("SIZE ") and len(cell_name)>0 ) and cell_name in cell_map:
            cell_map[cell_name]["width"] = line.strip().split(" ")[1]
            cell_map[cell_name]["height"] = line.strip().split(" ")[3]
            continue
        elif (line.strip().startswith("PIN ")) and cell_name in cell_map:
            pin_name = line.strip().split(" ")[1]
        elif (line.strip().startswith("RECT ")) and cell_name in cell_map:
            cell_map[cell_name]["pin_info"]["rect"] = line.strip().split(" ")[1:-1]


if __name__=='__main__':
    cell_map = {}
    for file in os.listdir("../../testcases/ASAP7/LIB/"):
        f = open("../../testcases/ASAP7/LIB/"+file)
        lib_extraction(f,cell_map)
        print(file)

    for file in os.listdir("../../testcases/ASAP7/LEF/"):
        if(file.endswith("lef")):
            f = open("../../testcases/ASAP7/LEF/"+file)
            lef_extraction(f, cell_map)
            print(file)

    with open('lib_info.json', 'w') as outfile:
        json.dump(cell_map, outfile)

