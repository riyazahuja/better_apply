"""
Given a list of tactics and a prompt string, find the tactics that are most relevant to the prompt.

Embed the tactics and the prompt and sort tactics by their cosine similarity to the prompt.
"""

from sklearn.metrics.pairwise import cosine_similarity
from typing import List
import ollama
import sys

def embed_text(text: str, model) -> List[float]:
    emb = ollama.embeddings(model=model, prompt=text)
    return emb.embedding

def find_relevant_tactics(tactics: List[str], prompt: str, model) -> List[str]:
    """
    Given a list of tactics and a prompt string, find the tactics that are most relevant to the prompt.
    """
    # Embed the prompt
    prompt_embedding = embed_text(prompt, model=model)

    # Embed each tactic
    tactic_embeddings = [embed_text(tactic, model=model) for tactic in tactics]

    # Compute cosine similarity between the prompt and each tactic
    similarities = cosine_similarity([prompt_embedding], tactic_embeddings)[0]

    # Sort tactics by similarity and get the indices
    sorted_indices = sorted(range(len(similarities)), key=lambda i: similarities[i], reverse=True)
    
    # Use the indices to sort the tactics
    sorted_tactics = [tactics[i] for i in sorted_indices]

    return sorted_tactics, sorted_indices

def main():
    """
    Usage: `python sort_tactics.py 'comm of add' 'add_assoc' 'mul_comm' 'add_comm'`
    """
    if len(sys.argv) < 3:
        print("Usage: python sort_tactics.py 'prompt' 'tactic1' 'tactic2' ...")
        sys.exit(1)
    
    # Get prompt from the first argument
    prompt = sys.argv[1]
    
    # Get tactics from the rest of the arguments
    tactics = sys.argv[2:]
    
    # Default model
    model = 'nomic-embed-text'
    
    # Find relevant tactics
    sorted_tactics, sorted_indices = find_relevant_tactics(tactics, prompt, model)
    
    # Display results
    for i, tactic in zip(sorted_indices, sorted_tactics):
        print(f"{i + 1} {tactic}")

if __name__ == "__main__":
    main()