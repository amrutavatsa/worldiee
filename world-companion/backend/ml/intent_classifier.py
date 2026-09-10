"""
intent_classifier.py — Phase 1 intent classification.

Implements FR02: classify transcribed user text into an intent category
(navigation, food, safety, general_info).

Uses TF-IDF + Logistic Regression as the Phase 1 baseline model — trainable
in seconds on a small labelled dataset, with the same predict() interface
a transformer-based classifier (e.g. fine-tuned DistilBERT, as specified in
the IEEE paper) would expose. This lets the team ship a working, testable
classifier now and swap in a transformer later (see train.py docstring)
without changing any calling code.
"""

import csv
import joblib
from pathlib import Path
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

MODEL_PATH = Path(__file__).parent.parent / "data" / "intent_model.joblib"
DATA_PATH = Path(__file__).parent.parent / "data" / "intent_training_data.csv"


def load_dataset(path=DATA_PATH):
    texts, labels = [], []
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            texts.append(row["text"])
            labels.append(row["intent"])
    return texts, labels


def train(data_path=DATA_PATH, model_path=MODEL_PATH, test_size=0.25, random_state=42):
    texts, labels = load_dataset(data_path)

    X_train, X_test, y_train, y_test = train_test_split(
        texts, labels, test_size=test_size, random_state=random_state, stratify=labels
    )

    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=1)),
        ("clf", LogisticRegression(max_iter=1000)),
    ])
    pipeline.fit(X_train, y_train)

    preds = pipeline.predict(X_test)
    acc = accuracy_score(y_test, preds)
    report = classification_report(y_test, preds, zero_division=0)

    joblib.dump(pipeline, model_path)

    return {
        "accuracy": acc,
        "report": report,
        "n_train": len(X_train),
        "n_test": len(X_test),
        "model_path": str(model_path),
    }


class IntentClassifier:
    """Loads the trained model once and serves predictions."""

    _pipeline = None

    @classmethod
    def load(cls, model_path=MODEL_PATH):
        if cls._pipeline is None:
            cls._pipeline = joblib.load(model_path)
        return cls._pipeline

    @classmethod
    def predict(cls, text: str):
        pipeline = cls.load()
        intent = pipeline.predict([text])[0]
        proba = pipeline.predict_proba([text])[0]
        confidence = float(max(proba))
        return {"intent": intent, "confidence": round(confidence, 3)}


if __name__ == "__main__":
    result = train()
    print(f"Trained on {result['n_train']} examples, tested on {result['n_test']}")
    print(f"Accuracy: {result['accuracy']:.2%}")
    print(result["report"])
