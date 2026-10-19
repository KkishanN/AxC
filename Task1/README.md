# Lab Module 1: Approximate Computing for Deep Neural Networks (LeNet-5)

**Domain:** Approximate Computing (AxC)  
**Author:** Kishan Nadageri  

---

## Overview

This module evaluates the resilience of convolutional neural networks (CNNs) to algorithmic approximations. We implement and benchmark weight pruning and data compression strategies on **LeNet-5** trained on the **MNIST** handwritten digit dataset.

---

## Network Architecture (LeNet-5)
- **Conv1**: $1 \to 6$ feature maps ($5\times 5$ kernel, padding=2) $\to$ ReLU $\to$ MaxPool ($2\times 2$)
- **Conv2**: $6 \to 16$ feature maps ($5\times 5$ kernel) $\to$ ReLU $\to$ MaxPool ($2\times 2$)
- **FC1**: $400 \to 120$ neurons $\to$ ReLU
- **FC2**: $120 \to 100$ neurons $\to$ ReLU
- **FC3 (Output)**: $100 \to 10$ neurons $\to$ Softmax

---

## Approximation Tasks & Methodology

### 1. Weight Pruning (Task 1)
Applied across all fully connected layers (`fc1`, `fc2`, `fc3`) at pruning rates of **10%, 20%, 30%, 40%, and 50%**:
- **Random Pruning**: Uniformly zeroes out weights at random.
- **Magnitude-Based Pruning**: Prunes weights with the smallest absolute values $|w| \le \theta$, preserving dominant synaptic connections.
- Evaluated both before retraining (zero-shot degradation) and after retraining (fine-tuning recovery).

### 2. PCA Data Compression (Task 2)
- Flattens 2D MNIST input images ($28\times 28 \to 784$ dimensions).
- Performs Principal Component Analysis (PCA) to project data onto principal eigenvectors.
- Truncates **20%** and **40%** of the least significant components and reconstructs images back to $28\times 28$.
- Retrains LeNet-5 on reconstructed images to measure classification resilience.

### 3. Pixel Variance Filtering (Task 3)
- Calculates per-pixel variance across the entire 60,000-image MNIST training set.
- Zeros out the **20%** and **40%** lowest-variance pixels (identifying non-informative border/background regions).
- Retrains and measures test set accuracy and F1-score.

### 4. Combined Approximation Pipeline (Task 4)
- Combines input PCA data compression (20% components removed) with magnitude-based weight pruning.
- Demonstrates compound energy and memory footprint reduction while retaining competitive classification fidelity.

---

## Key Experimental Results

| Configuration | Pruning / Comp. Rate | Train F1-Score | Test F1-Score | Parameter / FLOP Savings |
|:---|:---:|:---:|:---:|:---:|
| **Baseline (Exact LeNet-5)** | 0% | **0.992** | **0.988** | 0% |
| **Magnitude Pruning (Retrained)** | 10% | 0.991 | 0.987 | 10% FC Weights |
| **Magnitude Pruning (Retrained)** | 20% | 0.990 | 0.986 | 20% FC Weights |
| **Magnitude Pruning (Retrained)** | 30% | 0.988 | 0.984 | 30% FC Weights |
| **Magnitude Pruning (Retrained)** | 40% | 0.985 | 0.981 | 40% FC Weights |
| **Magnitude Pruning (Retrained)** | 50% | 0.981 | 0.976 | 50% FC Weights |
| **Random Pruning (Retrained)** | 50% | 0.942 | 0.938 | High degradation |
| **PCA Compression** | 20% components | 0.987 | 0.983 | 20% Input Dimension |
| **PCA Compression** | 40% components | 0.979 | 0.974 | 40% Input Dimension |
| **Combined (PCA 20% + Mag 30%)** | Combined | 0.983 | 0.979 | ~44% Compound Footprint |

### Key Insights:
1. **Magnitude vs. Random Pruning**: Magnitude-based pruning retains $>97.6\%$ test F1-score even with 50% of FC weights pruned, whereas random pruning experiences severe degradation at 50% due to loss of critical feature representations.
2. **PCA Robustness**: 20% PCA component removal yields virtually indistinguishable test F1 scores ($0.983$ vs $0.988$ baseline), confirming substantial dimensional redundancy in MNIST digit bitmaps.

---

## Running the Experiments
All experiments and interactive figures are self-contained in Jupyter Notebooks:
```bash
# Launch interactive notebook
jupyter notebook lab1_sol.ipynb
```
