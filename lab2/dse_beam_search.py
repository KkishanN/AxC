"""
Design Space Exploration (DSE) via Beam Search for 10-Stage Approximate FIR Filter
Paderborn University - Approximate Computing (AxC 2026) - Lab Module 2
Lecturers: Dr. Muhammad Awais, Prof. Dr. Marco Platzner

Specifications:
- Input circuit: 10-stage FIR filter
- Coefficients: b0=b9=3, b1=b8=25, b2=b7=96, b3=b6=384, b4=b5=3073
- Input data: 10,000 uniform random numbers in [0, 255] without repetition
- Quality metric: Mean Squared Error (MSE) <= 5.0%
- Optimization goal: Minimize circuit area using approximate components
- Algorithm: Beam Search with beam size = 3
- Output: Top 10 candidate architectures sorted by estimated area, Pareto frontier analysis
"""

import json
import csv
import copy
import numpy as np

# FIR Filter Specifications
COEFFS = [3, 25, 96, 384, 3073, 3073, 384, 96, 25, 3]
NUM_STAGES = 10
NUM_ADDERS = 9
BEAM_SIZE = 3
MAX_MSE_THRESHOLD_PCT = 5.0

# Hardware Standard-Cell Area Model (in um^2, Nangate 45nm / 65nm baseline)
# Exact 32-bit Adder: 120.0 um^2 (~3.75 um^2 per bit)
# Exact 32-bit Multiplier: 1250.0 um^2 (~39.0 um^2 per bit column)
# Truncating LSB/MSB bits removes partial product gates / full adder cells
EXACT_ADDER_AREA = 120.0
EXACT_MUL_AREA = 1250.0
ADDER_BIT_SAVING = 3.75
MUL_BIT_SAVING = 39.0

BASELINE_AREA = (NUM_STAGES * EXACT_MUL_AREA) + (NUM_ADDERS * EXACT_ADDER_AREA)


def generate_test_vectors(num_samples=10000, seed=42):
    """
    Generate 10,000 random numbers from uniform distribution [0, 255] without repetition.
    """
    np.random.seed(seed)
    # Generate unique values
    unique_samples = set()
    while len(unique_samples) < num_samples:
        batch = np.random.uniform(0.0, 255.0, num_samples - len(unique_samples) + 500)
        for val in batch:
            # Round to 4 decimal places to ensure uniqueness while covering continuous range
            r_val = round(float(val), 4)
            unique_samples.add(r_val)
            if len(unique_samples) == num_samples:
                break
    
    samples = np.array(list(unique_samples), dtype=np.float64)
    np.random.shuffle(samples)
    return samples


def compute_exact_fir(inputs):
    """
    Compute exact golden reference output y[n] = sum_{k=0}^9 b_k * x[n-k]
    """
    return np.convolve(inputs, COEFFS, mode='full')[:len(inputs)]


def estimate_circuit_area(mul_trunc_lsb, mul_trunc_msb, add_trunc_lsb, add_trunc_msb):
    """
    Estimate total circuit area as sum of component areas.
    """
    total_area = 0.0
    for k in range(NUM_STAGES):
        mul_savings = (mul_trunc_lsb[k] + mul_trunc_msb[k]) * MUL_BIT_SAVING
        mul_area = max(200.0, EXACT_MUL_AREA - mul_savings)
        total_area += mul_area

    for i in range(NUM_ADDERS):
        add_savings = (add_trunc_lsb[i] + add_trunc_msb[i]) * ADDER_BIT_SAVING
        add_area = max(25.0, EXACT_ADDER_AREA - add_savings)
        total_area += add_area

    return total_area


def simulate_approx_fir(inputs, exact_y, norm_denom,
                        mul_trunc_lsb, mul_trunc_msb,
                        add_trunc_lsb, add_trunc_msb):
    """
    Simulate FIR filter with approximate arithmetic components.
    Computes Normalized Mean Squared Error (%):
      NMSE = sum((y_exact - y_approx)^2) / sum(y_exact^2) * 100.0
    """
    N = len(inputs)
    y_approx = np.zeros(N, dtype=np.float64)

    # Pre-scale factor for bit truncations: 1 LSB bit = step of 1.0 in normalized int scale
    for n in range(N):
        acc = 0.0
        for k in range(NUM_STAGES):
            x_val = inputs[n - k] if n - k >= 0 else 0.0
            prod = COEFFS[k] * x_val

            # Apply multiplier truncation
            t_lsb = mul_trunc_lsb[k]
            t_msb = mul_trunc_msb[k]
            if t_lsb > 0:
                step = float(1 << t_lsb)
                prod = np.floor(prod / step) * step
            if t_msb > 0:
                # MSB saturation/clamping threshold
                max_val = float(1 << (32 - t_msb))
                if prod > max_val:
                    prod = max_val

            acc += prod

            # Apply adder truncation
            if k > 0:
                a_idx = k - 1
                at_lsb = add_trunc_lsb[a_idx]
                at_msb = add_trunc_msb[a_idx]
                if at_lsb > 0:
                    astep = float(1 << at_lsb)
                    acc = np.floor(acc / astep) * astep
                if at_msb > 0:
                    amax = float(1 << (32 - at_msb))
                    if acc > amax:
                        acc = amax

        y_approx[n] = acc

    mse = np.mean((exact_y - y_approx) ** 2)
    nmse_pct = (np.sum((exact_y - y_approx) ** 2) / norm_denom) * 100.0
    return nmse_pct, mse, y_approx


class ArchitectureNode:
    def __init__(self, mul_trunc_lsb, mul_trunc_msb, add_trunc_lsb, add_trunc_msb):
        self.mul_trunc_lsb = list(mul_trunc_lsb)
        self.mul_trunc_msb = list(mul_trunc_msb)
        self.add_trunc_lsb = list(add_trunc_lsb)
        self.add_trunc_msb = list(add_trunc_msb)
        self.area = estimate_circuit_area(self.mul_trunc_lsb, self.mul_trunc_msb,
                                          self.add_trunc_lsb, self.add_trunc_msb)
        self.area_savings_pct = ((BASELINE_AREA - self.area) / BASELINE_AREA) * 100.0
        self.nmse_pct = 0.0
        self.evaluated = False

    def key(self):
        return (tuple(self.mul_trunc_lsb), tuple(self.mul_trunc_msb),
                tuple(self.add_trunc_lsb), tuple(self.add_trunc_msb))


def run_beam_search_dse():
    print("=" * 70)
    print("  AxC Lab 2: FIR Filter Design Space Exploration (Beam Search)")
    print("  Paderborn University - Approximate Computing")
    print("=" * 70)

    print("\n1. Generating 10,000 uniform random inputs in [0, 255] without repetition...")
    test_vectors = generate_test_vectors(10000, seed=42)
    print(f"   Generated {len(test_vectors)} test vectors (min={test_vectors.min():.4f}, max={test_vectors.max():.4f})")

    print("\n2. Computing golden exact reference FIR output...")
    exact_y = compute_exact_fir(test_vectors)
    norm_denom = np.sum(exact_y ** 2)
    print(f"   Baseline circuit area: {BASELINE_AREA:.2f} um^2 (10x Mul={NUM_STAGES*EXACT_MUL_AREA} um^2, 9x Add={NUM_ADDERS*EXACT_ADDER_AREA} um^2)")
    print(f"   Energy & quality constraint: NMSE <= {MAX_MSE_THRESHOLD_PCT}%")

    # Initial exact node
    root = ArchitectureNode([0] * NUM_STAGES, [0] * NUM_STAGES, [0] * NUM_ADDERS, [0] * NUM_ADDERS)
    root.nmse_pct = 0.0
    root.evaluated = True

    current_beam = [root]
    visited = {root.key(): root}
    all_valid_candidates = [root]

    max_iterations = 18
    print(f"\n3. Running Beam Search (Beam Width = {BEAM_SIZE})...")

    for iteration in range(1, max_iterations + 1):
        successors = []

        for parent in current_beam:
            # Generate expansions: increase LSB or MSB truncation (1 to 8 bits)
            # Strategy: Explore multipliers with smaller coefficients first (b0, b1, b8, b9)
            # as they contribute less to output magnitude and yield high area savings.
            for k in range(NUM_STAGES):
                # Try increasing LSB truncation by 1..2 bits (up to 8)
                if parent.mul_trunc_lsb[k] < 8:
                    new_mul_lsb = list(parent.mul_trunc_lsb)
                    new_mul_lsb[k] = min(8, new_mul_lsb[k] + 2)
                    succ = ArchitectureNode(new_mul_lsb, parent.mul_trunc_msb,
                                            parent.add_trunc_lsb, parent.add_trunc_msb)
                    if succ.key() not in visited:
                        successors.append(succ)
                        visited[succ.key()] = succ

                # Try increasing MSB truncation by 1 bit (up to 4 for stability)
                if parent.mul_trunc_msb[k] < 4:
                    new_mul_msb = list(parent.mul_trunc_msb)
                    new_mul_msb[k] += 1
                    succ = ArchitectureNode(parent.mul_trunc_lsb, new_mul_msb,
                                            parent.add_trunc_lsb, parent.add_trunc_msb)
                    if succ.key() not in visited:
                        successors.append(succ)
                        visited[succ.key()] = succ

            for i in range(NUM_ADDERS):
                if parent.add_trunc_lsb[i] < 8:
                    new_add_lsb = list(parent.add_trunc_lsb)
                    new_add_lsb[i] = min(8, new_add_lsb[i] + 2)
                    succ = ArchitectureNode(parent.mul_trunc_lsb, parent.mul_trunc_msb,
                                            new_add_lsb, parent.add_trunc_msb)
                    if succ.key() not in visited:
                        successors.append(succ)
                        visited[succ.key()] = succ

        if not successors:
            print(f"   Iteration {iteration}: No further candidate expansions generated.")
            break

        # Evaluate candidate quality on 10,000 samples
        valid_successors = []
        for succ in successors:
            nmse, mse_val, _ = simulate_approx_fir(test_vectors, exact_y, norm_denom,
                                                   succ.mul_trunc_lsb, succ.mul_trunc_msb,
                                                   succ.add_trunc_lsb, succ.add_trunc_msb)
            succ.nmse_pct = nmse
            succ.evaluated = True

            # Prune candidates exceeding 5% MSE condition
            if nmse <= MAX_MSE_THRESHOLD_PCT:
                valid_successors.append(succ)
                all_valid_candidates.append(succ)

        if not valid_successors:
            print(f"   Iteration {iteration}: All generated candidates violated MSE <= 5% constraint.")
            break

        # Beam selection: pick top BEAM_SIZE candidates with lowest estimated area
        valid_successors.sort(key=lambda n: n.area)
        current_beam = valid_successors[:BEAM_SIZE]

        best_iter = current_beam[0]
        print(f"   Iteration {iteration:02d}: Evaluated {len(successors)} candidates -> {len(valid_successors)} valid. "
              f"Best Candidate Area: {best_iter.area:.1f} um^2 ({best_iter.area_savings_pct:.2f}% savings), MSE: {best_iter.nmse_pct:.4f}%")

    # Select Top 10 Candidates sorted by Estimated Area
    all_valid_candidates.sort(key=lambda n: (n.area, n.nmse_pct))
    top_10 = all_valid_candidates[:10]

    print("\n" + "=" * 70)
    print("  TOP 10 APPROXIMATE FIR ARCHITECTURES (AREA-OPTIMAL, MSE <= 5%)")
    print("=" * 70)
    print(f"{'Rank':<5} | {'Area (um^2)':<12} | {'Area Saving':<12} | {'NMSE (%)':<10} | {'Mul LSB Trunc':<20} | {'Add LSB Trunc':<18}")
    print("-" * 88)

    export_data = []
    for rank, cand in enumerate(top_10, 1):
        mul_str = ",".join(str(x) for x in cand.mul_trunc_lsb)
        add_str = ",".join(str(x) for x in cand.add_trunc_lsb)
        print(f"{rank:<5} | {cand.area:<12.1f} | {cand.area_savings_pct:<11.2f}% | {cand.nmse_pct:<10.6f} | [{mul_str:<18}] | [{add_str:<16}]")

        export_data.append({
            "rank": rank,
            "estimated_area_um2": round(cand.area, 2),
            "area_savings_pct": round(cand.area_savings_pct, 2),
            "nmse_pct": float(f"{cand.nmse_pct:.8f}"),
            "mul_trunc_lsb": cand.mul_trunc_lsb,
            "mul_trunc_msb": cand.mul_trunc_msb,
            "add_trunc_lsb": cand.add_trunc_lsb,
            "add_trunc_msb": cand.add_trunc_msb,
            "meets_constraint": True
        })

    # Save to JSON and CSV
    with open("pareto_results.json", "w") as f:
        json.dump(export_data, f, indent=2)

    with open("pareto_results.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Rank", "Estimated_Area_um2", "Area_Savings_pct", "NMSE_pct", "Mul_LSB_Trunc", "Add_LSB_Trunc"])
        for item in export_data:
            writer.writerow([
                item["rank"],
                item["estimated_area_um2"],
                item["area_savings_pct"],
                item["nmse_pct"],
                str(item["mul_trunc_lsb"]),
                str(item["add_trunc_lsb"])
            ])

    print("\nResults exported successfully to pareto_results.json and pareto_results.csv.")
    return export_data


if __name__ == "__main__":
    run_beam_search_dse()
