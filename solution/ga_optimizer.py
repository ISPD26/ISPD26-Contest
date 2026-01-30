#!/usr/bin/env python3
"""
GA-based buffer optimization for OpenROAD
Uses TCL scripting to interact with OpenROAD efficiently
"""

import subprocess
import numpy as np
from deap import base, creator, tools, algorithms
import random
import pickle
import time
import os
import json
import tempfile

class BufferGeneticOptimizer:
    """
    Genetic Algorithm for optimizing buffer insertion
    Each chromosome represents buffer configurations for all violating endpoints
    """
    
    def __init__(self, design_name, tech_dir, design_dir, output_dir):
        self.design_name = design_name
        self.tech_dir = tech_dir
        self.design_dir = design_dir
        self.output_dir = output_dir
        
        # OpenROAD instance - reused across evaluations
        self.ord_app = None
        self.initial_state = None
        
        # Buffer library (to be populated from tech library)
        self.buffer_cells = []
        self.buffer_vt_types = []
        
        # Endpoint information
        self.endpoints = []
        self.endpoint_paths = {}
        
        # GA parameters
        self.population_size = 50
        self.num_generations = 100
        self.mutation_rate = 0.2
        self.crossover_rate = 0.7
        
    def initialize_openroad(self):
        """Initialize OpenROAD once and save initial state"""
        print("[INFO] Initializing OpenROAD...")
        
        # Create OpenROAD application
        self.ord_app = ord.OpenRoad()
        tech = self.ord_app.getTech()
        chip = self.ord_app.getChip()
        
        # Read LEF files
        tech.readLef(f"{self.tech_dir}/lef/asap7_tech_1x_201209.lef")
        
        # Read all standard cell LEFs
        import glob
        for lef in sorted(glob.glob(f"{self.tech_dir}/lef/asap7sc7p5t_28_*_1x_220121a.lef")):
            tech.readLef(lef)
        for lef in sorted(glob.glob(f"{self.tech_dir}/lef/sram_asap7_*.lef")):
            tech.readLef(lef)
        tech.readLef(f"{self.tech_dir}/lef/fakeram_256x64.lef")
        
        # Read Liberty files
        sta = self.ord_app.getSta()
        for lib in sorted(glob.glob(f"{self.tech_dir}/lib/asap7sc7p5t_*.lib")):
            sta.readLiberty(lib)
        for lib in sorted(glob.glob(f"{self.tech_dir}/lib/sram_asap7_*.lib")):
            sta.readLiberty(lib)
        sta.readLiberty(f"{self.tech_dir}/lib/fakeram_256x64.lib")
        
        # Read design
        chip.readVerilog(f"{self.design_dir}/contest.v")
        chip.readDef(f"{self.design_dir}/contest.def")
        sta.readSdc(f"{self.design_dir}/contest.sdc")
        
        # Setup parasitics
        self.ord_app.getResizer().estimateParasitics()
        
        print("[INFO] OpenROAD initialized successfully")
        
        # Extract buffer library
        self._extract_buffer_library()
        
        # Extract violating endpoints
        self._extract_endpoints()
        
        # Save initial state for fast restoration
        self._save_initial_state()
        
    def _extract_buffer_library(self):
        """Extract available buffer cells from liberty library"""
        sta = self.ord_app.getSta()
        
        # Get all buffer/inverter cells
        # Simplified: assume buffer names contain "BUF" or "INV"
        # Group by VT type (LVT, RVT, SLVT, etc.)
        
        self.buffer_cells = [
            # Format: (cell_name, drive_strength, vt_type, area, delay_scale)
            ("BUFx2_ASAP7_75t_L", 2, "LVT", 0.5, 1.0),
            ("BUFx4_ASAP7_75t_L", 4, "LVT", 1.0, 0.8),
            ("BUFx8_ASAP7_75t_L", 8, "LVT", 2.0, 0.6),
            ("BUFx2_ASAP7_75t_R", 2, "RVT", 0.5, 1.2),
            ("BUFx4_ASAP7_75t_R", 4, "RVT", 1.0, 1.0),
            ("BUFx8_ASAP7_75t_R", 8, "RVT", 2.0, 0.8),
            ("BUFx2_ASAP7_75t_SL", 2, "SLVT", 0.5, 0.9),
            ("BUFx4_ASAP7_75t_SL", 4, "SLVT", 1.0, 0.7),
        ]
        
        print(f"[INFO] Found {len(self.buffer_cells)} buffer cell variants")
        
    def _extract_endpoints(self):
        """Extract violating timing endpoints"""
        sta = self.ord_app.getSta()
        
        # Get all endpoints with negative slack
        # This is a simplified version - actual implementation needs STA API
        print("[INFO] Extracting violating endpoints...")
        
        # Placeholder: in real implementation, use sta API
        # self.endpoints = [(endpoint_name, slack, fanout), ...]
        self.endpoints = []
        
    def _save_initial_state(self):
        """Save initial design state for fast restoration"""
        # In real implementation, this could be a journal checkpoint
        # For now, we'll reload from DEF each time (still faster than process restart)
        pass
        
    def restore_initial_state(self):
        """Restore design to initial state for new evaluation"""
        # Fast restoration without restarting OpenROAD
        # Could use journal restore or incremental updates
        pass
        
    def create_chromosome(self):
        """
        Create one chromosome (individual solution)
        
        Chromosome structure:
        For each violating endpoint:
        - Number of buffers to insert (0-3)
        - For each buffer: [cell_type_index, location_fraction]
        
        Example: [2, 3, 0.3, 5, 0.7, 1, 1, 0.5, ...]
                  ^  ^  ^    ^  ^    ^  ^  ^
                  |  |  |    |  |    |  |  |
                  |  |  |    |  |    |  |  +- Location (50% along path)
                  |  |  |    |  |    |  +---- Cell type index
                  |  |  |    |  |    +------- Num buffers for endpoint 2
                  |  |  |    |  +------------ Location (70% along path)
                  |  |  |    +--------------- Cell type index
                  |  |  +-------------------- Location (30% along path)
                  |  +----------------------- Cell type index
                  +-------------------------- Num buffers for endpoint 1
        """
        chromosome = []
        
        # For each endpoint, decide buffer configuration
        for endpoint in self.endpoints[:10]:  # Limit to first 10 for speed
            num_buffers = random.randint(0, 3)
            chromosome.append(num_buffers)
            
            for _ in range(num_buffers):
                cell_idx = random.randint(0, len(self.buffer_cells) - 1)
                location = random.uniform(0.2, 0.8)  # 20%-80% along path
                chromosome.extend([cell_idx, location])
                
        return chromosome
    
    def evaluate_fitness(self, chromosome):
        """
        Evaluate fitness of one chromosome
        
        Returns: (wns, tns, area_penalty)
        Lower is better for all three
        """
        # Restore to initial state
        self.restore_initial_state()
        
        # Apply buffer insertions according to chromosome
        self._apply_chromosome(chromosome)
        
        # Run timing analysis
        sta = self.ord_app.getSta()
        sta.updateTiming()
        
        # Get metrics
        wns = self._get_worst_slack()
        tns = self._get_total_negative_slack()
        area = self._get_design_area()
        
        # Fitness: weighted sum (lower is better)
        # Prioritize WNS > TNS > Area
        fitness = -wns * 1000 + -tns * 100 + area * 0.1
        
        return (fitness,)  # DEAP expects tuple
    
    def _apply_chromosome(self, chromosome):
        """Apply buffer configuration from chromosome to design"""
        resizer = self.ord_app.getResizer()
        
        idx = 0
        for ep_idx, endpoint in enumerate(self.endpoints[:10]):
            if idx >= len(chromosome):
                break
                
            num_buffers = int(chromosome[idx])
            idx += 1
            
            for buf_idx in range(num_buffers):
                if idx + 1 >= len(chromosome):
                    break
                    
                cell_idx = int(chromosome[idx])
                location = chromosome[idx + 1]
                idx += 2
                
                # Get buffer cell
                if cell_idx >= len(self.buffer_cells):
                    continue
                    
                cell_name = self.buffer_cells[cell_idx][0]
                
                # Insert buffer at specified location
                # This is simplified - real implementation needs path analysis
                # resizer.insertBuffer(endpoint, location, cell_name)
                
    def _get_worst_slack(self):
        """Get worst negative slack from design"""
        # Placeholder - use STA API
        return -0.5
    
    def _get_total_negative_slack(self):
        """Get total negative slack"""
        # Placeholder - use STA API
        return -10.0
    
    def _get_design_area(self):
        """Get current design area"""
        # Placeholder - use chip API
        return 100000.0
    
    def setup_ga(self):
        """Setup DEAP genetic algorithm"""
        # Create fitness and individual classes
        creator.create("FitnessMin", base.Fitness, weights=(-1.0,))
        creator.create("Individual", list, fitness=creator.FitnessMin)
        
        toolbox = base.Toolbox()
        
        # Register creation functions
        toolbox.register("individual", tools.initIterate, 
                        creator.Individual, self.create_chromosome)
        toolbox.register("population", tools.initRepeat, 
                        list, toolbox.individual)
        
        # Register genetic operators
        toolbox.register("evaluate", self.evaluate_fitness)
        toolbox.register("mate", tools.cxTwoPoint)
        toolbox.register("mutate", tools.mutGaussian, mu=0, sigma=1, indpb=0.2)
        toolbox.register("select", tools.selTournament, tournsize=3)
        
        return toolbox
    
    def run_optimization(self):
        """Run GA optimization"""
        print("[INFO] Starting GA optimization...")
        
        toolbox = self.setup_ga()
        
        # Create initial population
        population = toolbox.population(n=self.population_size)
        
        # Statistics
        stats = tools.Statistics(lambda ind: ind.fitness.values)
        stats.register("avg", np.mean)
        stats.register("min", np.min)
        stats.register("max", np.max)
        
        # Hall of fame (best individuals)
        hof = tools.HallOfFame(5)
        
        # Run evolution
        start_time = time.time()
        
        population, logbook = algorithms.eaSimple(
            population, toolbox,
            cxpb=self.crossover_rate,
            mutpb=self.mutation_rate,
            ngen=self.num_generations,
            stats=stats,
            halloffame=hof,
            verbose=True
        )
        
        elapsed = time.time() - start_time
        print(f"[INFO] GA completed in {elapsed:.1f} seconds")
        
        # Get best solution
        best_individual = hof[0]
        print(f"[INFO] Best fitness: {best_individual.fitness.values[0]}")
        
        # Apply best solution and save
        self._apply_chromosome(best_individual)
        self._save_results()
        
        return best_individual, logbook
    
    def _save_results(self):
        """Save optimized design"""
        chip = self.ord_app.getChip()
        chip.writeVerilog(f"{self.output_dir}/{self.design_name}.v")
        chip.writeDef(f"{self.output_dir}/{self.design_name}.def")
        print(f"[INFO] Results saved to {self.output_dir}")


def main():
    import sys
    
    if len(sys.argv) < 5:
        print("Usage: python ga_optimizer.py <design_name> <tech_dir> <design_dir> <output_dir>")
        sys.exit(1)
    
    design_name = sys.argv[1]
    tech_dir = sys.argv[2]
    design_dir = sys.argv[3]
    output_dir = sys.argv[4]
    
    # Create optimizer
    optimizer = BufferGeneticOptimizer(design_name, tech_dir, design_dir, output_dir)
    
    # Initialize OpenROAD (once)
    optimizer.initialize_openroad()
    
    # Run GA optimization
    best_solution, logbook = optimizer.run_optimization()
    
    print("[INFO] Optimization complete!")


if __name__ == "__main__":
    main()
