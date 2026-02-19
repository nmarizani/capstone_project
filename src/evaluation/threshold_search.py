import numpy as np
from sklearn.metrics import f1_score

def optimize_threshold(y_true, y_prob):

    thresholds = np.linspace(0.1, 0.9, 100)
    scores = []

    for t in thresholds:
        preds = (y_prob >= t).astype(int)
        scores.append(f1_score(y_true, preds))

    best_idx = np.argmax(scores)
    return thresholds[best_idx]