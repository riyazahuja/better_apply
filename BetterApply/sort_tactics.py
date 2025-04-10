"""
Given a list of tactics and a prompt string, find the tactics that are most relevant to the prompt.
Embed the tactics and the prompt and sort tactics by their cosine similarity to the prompt.
"""

import subprocess
import sys

# Check if scikit-learn is installed
try:
    import sklearn
except ImportError:
    print("scikit-learn is not installed. Installing it now...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "scikit-learn"])
        print("scikit-learn installed successfully.")
    except Exception as e:
        print(f"Error installing scikit-learn: {e}")
        sys.exit(1)

from sklearn.metrics.pairwise import cosine_similarity

# Check if Ollama is installed
try:
    import ollama
    ollama.list()
except Exception:
    print("Error: Ollama is not installed or not running.")
    print("Please install Ollama from https://ollama.com/download")
    print("After installing, make sure the Ollama service is running.")
    sys.exit(1)

# Check if the model exists, if not pull it
model = 'nomic-embed-text'
try:
    models = ollama.list()
    if model not in [m['name'] for m in models['models']]:
        print(f"Model {model} not found in Ollama. Pulling it now...")
        ollama.pull(model)
        print(f"Successfully pulled model {model}")
except Exception as e:
    print(f"Error checking/pulling model: {e}")
    sys.exit(1)

def embed_text(text: str, model: str):
    emb = ollama.embeddings(model=model, prompt=text)
    return emb.embedding

def find_relevant_tactics(tactics: list[str], prompt: str, model: str):
    prompt_embedding = embed_text(prompt, model=model)
    tactic_embeddings = [embed_text(tactic, model=model) for tactic in tactics]
    similarities = cosine_similarity([prompt_embedding], tactic_embeddings)[0]
    sorted_indices = sorted(range(len(similarities)), key=lambda i: similarities[i], reverse=True)
    sorted_tactics = [tactics[i] for i in sorted_indices]
    return sorted_tactics, sorted_indices

def main():
    "Usage: `python sort_tactics.py 'comm of add' 'add_assoc' 'mul_comm' 'add_comm'`"
    
    if len(sys.argv) < 3:
        print("Usage: python sort_tactics.py 'prompt' 'tactic1' 'tactic2' ...")
        sys.exit(1)
    
    prompt = sys.argv[1]
    tactics = sys.argv[2:]
    sorted_tactics, sorted_indices = find_relevant_tactics(tactics, prompt, model)
    for i, tactic in zip(sorted_indices, sorted_tactics):
        print(f"{i}")

if __name__ == "__main__":
    main()