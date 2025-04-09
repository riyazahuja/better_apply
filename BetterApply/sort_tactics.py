"""
Given a list of tactics and a prompt string, find the tactics that are most relevant to the prompt.
Embed the tactics and the prompt and sort tactics by their cosine similarity to the prompt.
"""

from sklearn.metrics.pairwise import cosine_similarity
import ollama
import sys

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
    model = 'nomic-embed-text'
    sorted_tactics, sorted_indices = find_relevant_tactics(tactics, prompt, model)
    for i, tactic in zip(sorted_indices, sorted_tactics):
        print(f"{i} {tactic}")

if __name__ == "__main__":
    main()