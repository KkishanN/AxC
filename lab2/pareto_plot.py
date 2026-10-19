"""
Plot Pareto Space Graph (Area vs NMSE) for AxC Lab Module 2
Generates pareto_curve.png showing the tradeoff between circuit area and normalized mean squared error.
"""

import json
import matplotlib.pyplot as plt

def generate_pareto_plot():
    with open("pareto_results.json", "r") as f:
        data = json.load(f)

    ranks = [item["rank"] for item in data]
    areas = [item["estimated_area_um2"] for item in data]
    nmses = [item["nmse_pct"] * 1e4 for item in data] # Scale for visual clarity (10^-4 %)
    savings = [item["area_savings_pct"] for item in data]

    plt.figure(figsize=(9, 6), dpi=300)
    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')

    # Baseline point
    plt.scatter([0.0], [13580.0], color='red', s=120, zorder=5, label='Exact Baseline (13580 um^2, 0% NMSE)')

    # Top candidates
    scatter = plt.scatter(nmses, areas, c=savings, cmap='viridis', s=100, edgecolors='black', linewidth=1.2, zorder=4, label='Top 10 Pareto Candidates')
    cbar = plt.colorbar(scatter)
    cbar.set_label('Area Savings (%)', fontsize=11, fontweight='bold')

    for i, txt in enumerate(ranks):
        plt.annotate(f"Rank {txt}", (nmses[i], areas[i]), textcoords="offset points", xytext=(8, -4), fontsize=9)

    plt.title('AxC Lab 2: Pareto Frontier (Estimated Circuit Area vs Quality)', fontsize=13, fontweight='bold', pad=15)
    plt.xlabel('Normalized Mean Squared Error (x 10⁻⁴ %)', fontsize=11, fontweight='bold')
    plt.ylabel('Estimated Hardware Area (um²)', fontsize=11, fontweight='bold')
    plt.axhline(13580.0, color='red', linestyle='--', alpha=0.5)
    plt.axvline(5.0 * 1e4, color='gray', linestyle=':', label='5% Max Constraint Threshold')
    plt.legend(frameon=True, loc='upper right')
    plt.tight_layout()

    plt.savefig("pareto_curve.png")
    print("Pareto plot saved to pareto_curve.png successfully.")

if __name__ == "__main__":
    generate_pareto_plot()
