import sys

from pmlb import fetch_data
from sklearn.tree import DecisionTreeClassifier, export_text
from sklearn.datasets import make_classification
import pandas as pd
from sklearn.datasets import fetch_openml

# mode = "skl"
mode = "pmlb"

# Returns NumPy arrays
if mode == "pmlb":
    # X, y = fetch_data('mux6', return_X_y=True, local_cache_dir='./')
    # X, y = fetch_data('irish', return_X_y=True, local_cache_dir='./')
    # https://epistasislab.github.io/pmlb/
    # X, y = fetch_data('corral', return_X_y=True, local_cache_dir='./')
    X, y = fetch_data('mofn_3_7_10', return_X_y=True, local_cache_dir='./')
    # print(X)
    # print(y)
elif mode == "synth":
    X, y = make_classification(random_state=42, n_informative=5)
    # convert X into a 01 vector
    X = (X > 0).astype(int)
elif mode == "skl":

    # # 1. SPECT Heart Dataset (Native Binary Features)
    # spect = fetch_openml('spect', version=1, as_frame=True)
    # X, y = spect.data, spect.target

    # dataset = fetch_openml('kr-vs-kp', version=1, as_frame=True)
    dataset = fetch_openml('monks-problems-1', version=1, as_frame=True)
    # convert categorical board conditions to boolean
    X = pd.get_dummies(dataset.data, drop_first=True)
    y = dataset.target

    # make X and y such that the below works
    X = X.values
    y = y.values

    # # 2. Chess End-Game Dataset (Convert categorical board conditions to boolean)
    # chess = fetch_openml('chess-krvskp', version=1, as_frame=True)
    # X_chess = pd.get_dummies(chess.data, drop_first=True)
    # y_chess = chess.target

# print(X)
# print(y)
# for v in y:
#     print(v)

print_facts = True

if print_facts:
    # read the X and y and print the the format
    # example(e1,f1,class)
    # where e1 is the example, f1 is the feature, and class is the class label (positive or negative)
    for i in range(len(X)):
        for j in range(len(X[i])):
            # print(X[i][j])
            print(f"example(e{i+1},f{j+1},{'positive' if int(X[i][j]) == 1 else 'negative'}).")
    # read the y and print the class labels in the format
    # target(e1,class)
    for i in range(len(y)):
        # print(y[i])
        print(f"target(e{i+1},{'positive' if int(y[i]) == 1 else 'negative'}).")

    # print the features in the format
    # feature(f1 ; f2 ; f3 ; ...).
    features = [f"f{i+1}" for i in range(len(X[0]))]
    print(f"feature({'; '.join(features)}).")

# sys.exit(0)

# fit a decision tree classifier to the data and print the tree

clf = DecisionTreeClassifier(random_state=0) #, criterion='entropy', max_depth=1)
clf.fit(X, y)
tree_rules = export_text(clf, feature_names=[f"f{i+1}" for i in range(len(X[0]))])
# append % before each line of the tree rules
tree_rules = "\n".join([f"% {line}" for line in tree_rules.splitlines()])
print(tree_rules)
# compute accuracy of the decision tree classifier on the training data
accuracy = clf.score(X, y)
print(f"% Accuracy of the decision tree classifier on the training data: {accuracy:.2f}")
print(f"% Depth of the decision tree classifier: {clf.get_depth()}")
# print the number of nodes in the decision tree classifier
print(f"% Number of nodes in the decision tree classifier: {clf.tree_.node_count}")
# print the number of leaf nodes in the decision tree classifier
print(f"% Number of leaf nodes in the decision tree classifier: {clf.get_n_leaves()}")
# # count the number of examples in each leaf node of the decision tree classifier
# leaf_counts = clf.tree_.n_node_samples[clf.tree_.children_left == -1]
# print(f"% Number of examples in each leaf node of the decision tree classifier: {str(leaf_counts)}")
