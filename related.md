# Related Solutions

## Learning Optimal Decision Trees using Constraint Programming
Given a dataset in which all examples are binary, the problem is to find the decision tree that *optimizes prediction accuracy*, while enforcing a *constraint on the depth of the decision tree*.

> We suspect, as papers [3, 17, 26], that the problem of finding an optimal decision tree given a maximum depth is NP-complete even if *no formal proof is available yet*.


## Learning Optimal Classification Trees Using a Binary Linear Program Formulation

The optimization problem that we aim to solve is to find an optimal classification tree of *depth K* for a given dataset of R rows and F features, such that the *total classification error is minimized*.

## Learning Optimal Decision Trees with SAT

Learns tree with the minimum number of nodes suh that *total classification error is minimized*.
(I assume this even though this is not explicit).

## Learning Optimal Decision Trees Using Caching Branch-and-Bound Search

Proposes a formulation which is optimization-agnostic.
The paper is not precise on which is the target of minimization.

# Existing Optimality Results

Dataset | Optimal | Source
mux6 | 15 (# nodes) | Learning Optimal Decision Trees with SAT
corral | 13 (# nodes) | Learning Optimal Decision Trees with SAT

# How to call
```
time timeout 30 clingo encoding_improved_v2.lp datasets/mux6.lp --const size=7 --const max_depth=2
```

# Current Results
encoding_improved_v2.lp
dataset | n nodes | time
mux6 | 15 | 0.471
corral | 13 | 0.6