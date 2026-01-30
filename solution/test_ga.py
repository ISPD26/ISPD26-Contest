#!/usr/bin/env python3
"""
Simple test to verify GA approach without full OpenROAD integration
"""

import numpy as np
from deap import base, creator, tools, algorithms
import random

class SimpleBufferGA:
    """Simplified GA for testing concept"""
    
    def __init__(self):
        self.num_endpoints = 5
        self.buffer_types = 8  # 8 different buffer cells
        
    def create_chromosome(self):
        """
        Simplified chromosome:
        For each endpoint: [num_buffers, buf1_type, buf1_loc, buf2_type, buf2_loc, ...]
        """
        chromosome = []
        for _ in range(self.num_endpoints):
            num_buffers = random.randint(0, 3)
            chromosome.append(num_buffers)
            for _ in range(num_buffers):
                buf_type = random.randint(0, self.buffer_types - 1)
                location = random.uniform(0.2, 0.8)
                chromosome.extend([buf_type, location])
        return chromosome
    
    def evaluate_fitness(self, chromosome):
        """
        Mock fitness evaluation
        In real version, this calls OpenROAD STA
        """
        # Simulate: more buffers = better timing but worse area
        total_buffers = sum(1 for i, val in enumerate(chromosome) 
                          if i % 3 == 0 for _ in range(int(val)))
        
        # Mock timing improvement
        timing_score = -max(0, 10 - total_buffers * 2)  # Better with more buffers
        
        # Mock area penalty
        area_penalty = total_buffers * 0.5
        
        # Mock slack improvement based on buffer placement
        placement_score = 0
        idx = 0
        for ep in range(self.num_endpoints):
            if idx >= len(chromosome):
                break
            num_bufs = int(chromosome[idx])
            idx += 1
            for _ in range(num_bufs):
                if idx + 1 < len(chromosome):
                    buf_type = chromosome[idx]
                    location = chromosome[idx + 1]
                    # Prefer middle locations and stronger buffers
                    placement_score -= abs(location - 0.5) * 2
                    placement_score -= buf_type * 0.1  # Higher index = stronger
                    idx += 2
        
        fitness = timing_score - area_penalty + placement_score
        return (fitness,)
    
    def run(self):
        """Run GA optimization"""
        # Setup DEAP
        creator.create("FitnessMax", base.Fitness, weights=(1.0,))
        creator.create("Individual", list, fitness=creator.FitnessMax)
        
        toolbox = base.Toolbox()
        toolbox.register("individual", tools.initIterate, 
                        creator.Individual, self.create_chromosome)
        toolbox.register("population", tools.initRepeat, 
                        list, toolbox.individual)
        toolbox.register("evaluate", self.evaluate_fitness)
        toolbox.register("mate", tools.cxTwoPoint)
        toolbox.register("mutate", tools.mutGaussian, mu=0, sigma=0.5, indpb=0.2)
        toolbox.register("select", tools.selTournament, tournsize=3)
        
        # Create population
        pop = toolbox.population(n=20)
        
        # Stats
        stats = tools.Statistics(lambda ind: ind.fitness.values)
        stats.register("avg", np.mean)
        stats.register("max", np.max)
        
        # Run
        print("Starting GA optimization (test mode)...")
        pop, log = algorithms.eaSimple(pop, toolbox, 
                                       cxpb=0.7, mutpb=0.2, 
                                       ngen=10, stats=stats, 
                                       verbose=True)
        
        best = tools.selBest(pop, 1)[0]
        print(f"\nBest solution fitness: {best.fitness.values[0]:.3f}")
        print(f"Best chromosome (first 20 genes): {best[:20]}")
        
        return best

if __name__ == "__main__":
    ga = SimpleBufferGA()
    best = ga.run()
    print("\n[SUCCESS] GA test completed!")
