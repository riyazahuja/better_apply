"""
Given a list of tactics and a prompt string, find the tactics that are most relevant to the prompt.

Embed the tactics and the prompt and sort tactics by their cosine similarity to the prompt.
"""

from sklearn.metrics.pairwise import cosine_similarity
from typing import List
import ollama

def embed_text(text: str, model) -> List[float]:
    emb = ollama.embeddings(model=model, prompt=text)
    return emb.embedding

def find_relevant_tactics(tactics: List[str], prompt: str, model='nomic-embed-text') -> List[str]:
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

tactic_list = ['exact fun a b ↦ Nat.add_comm a b', 
               'exact fun a b ↦ Nat.add_assoc a b', 
               'exact fun a b ↦ Nat.add_zero a b', 
               'exact fun a b ↦ Nat.add_succ a b',
               'rw [Commute.add_left]']
prompt = 'addition is commutative'
# model = 'mxbai-embed-large'
model = 'nomic-embed-text'
# cosine_similarity([embed_text_ollama(prompt, model=model)], [embed_text_ollama(t, model=model) for t in tactic_list])

sorted_tactics, sorted_indices = find_relevant_tactics(tactic_list, prompt)
print("Sorted Tactics:")
for i, tactic in enumerate(sorted_tactics):
    print(f"{i + 1}: {tactic}")