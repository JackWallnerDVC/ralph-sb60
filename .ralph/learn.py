#!/usr/bin/env python3
"""
Ralph's Learning Module - Gets better over time
Analyzes published posts and updates strategies
"""

import json
import os
from pathlib import Path
from datetime import datetime

REPO_DIR = Path("/Users/jackwallner/clawd/ralph-sb60")
FEEDBACK_FILE = REPO_DIR / ".ralph" / "feedback.json"
POSTS_DIR = REPO_DIR / "_posts"

def load_feedback():
    """Load or create feedback file"""
    if FEEDBACK_FILE.exists():
        with open(FEEDBACK_FILE) as f:
            return json.load(f)
    return create_default_feedback()

def create_default_feedback():
    """Create default feedback structure"""
    return {
        "version": "1.0",
        "metrics": {"totalPublished": 0, "avgWordCount": 0},
        "persona_performance": {
            "insider": {"posts": 0, "avg_words": 0},
            "analyst": {"posts": 0, "avg_words": 0},
            "local": {"posts": 0, "avg_words": 0}
        },
        "improvements": {"changes": []}
    }

def analyze_post(filepath):
    """Analyze a single post for metrics"""
    content = filepath.read_text()
    lines = content.split('\n')
    
    # Extract YAML frontmatter
    in_yaml = False
    yaml_lines = []
    body_lines = []
    
    for line in lines:
        if line == '---':
            in_yaml = not in_yaml
            continue
        if in_yaml:
            yaml_lines.append(line)
        else:
            body_lines.append(line)
    
    # Parse YAML
    metadata = {}
    for line in yaml_lines:
        if ':' in line:
            key, val = line.split(':', 1)
            metadata[key.strip()] = val.strip()
    
    # Analyze body
    body = '\n'.join(body_lines)
    word_count = len(body.split())
    
    return {
        "persona": metadata.get("persona", "unknown"),
        "author": metadata.get("author", "unknown"),
        "word_count": word_count,
        "has_specific_facts": any(x in body.lower() for x in ['$', '%', 'mph', 'yards', '2026', 'february']),
        "ai_words_found": [w for w in ['additionally', 'moreover', 'furthermore', 'landscape', 'tapestry', 'delve'] if w in body.lower()]
    }

def update_feedback():
    """Main learning function - analyze all posts and update feedback"""
    feedback = load_feedback()
    
    posts = list(POSTS_DIR.glob("*.md"))
    if not posts:
        print("No posts to analyze")
        return
    
    print(f"📊 Analyzing {len(posts)} published posts...")
    
    # Reset counters
    persona_stats = {"insider": [], "analyst": [], "local": []}
    total_words = 0
    issues_found = []
    
    for post in posts:
        analysis = analyze_post(post)
        persona = analysis["persona"]
        
        if persona in persona_stats:
            persona_stats[persona].append(analysis["word_count"])
        
        total_words += analysis["word_count"]
        
        if analysis["ai_words_found"]:
            issues_found.append(f"{post.name}: AI words {analysis['ai_words_found']}")
    
    # Update feedback
    feedback["metrics"]["totalPublished"] = len(posts)
    feedback["metrics"]["avgWordCount"] = total_words // len(posts) if posts else 0
    
    for persona, word_counts in persona_stats.items():
        if word_counts:
            feedback["persona_performance"][persona]["posts"] = len(word_counts)
            feedback["persona_performance"][persona]["avg_words"] = sum(word_counts) // len(word_counts)
    
    # Log improvements
    feedback["improvements"]["last_updated"] = datetime.utcnow().isoformat() + "Z"
    if issues_found:
        feedback["improvements"]["changes"].append(f"Found issues in {len(issues_found)} posts")
    else:
        feedback["improvements"]["changes"].append(f"Clean analysis - {len(posts)} posts reviewed")
    
    # Save
    FEEDBACK_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(FEEDBACK_FILE, 'w') as f:
        json.dump(feedback, f, indent=2)
    
    print(f"✅ Learning complete:")
    print(f"   Total posts: {len(posts)}")
    print(f"   Avg words: {feedback['metrics']['avgWordCount']}")
    print(f"   Issues: {len(issues_found)}")
    
    return feedback

def get_writing_tips():
    """Get tips for next draft based on learning"""
    feedback = load_feedback()
    tips = []
    
    # Check persona balance
    persona_counts = {p: s["posts"] for p, s in feedback["persona_performance"].items()}
    min_persona = min(persona_counts, key=persona_counts.get)
    tips.append(f"Consider writing as '{min_persona}' persona (lowest count)")
    
    # Check word count
    avg = feedback["metrics"]["avgWordCount"]
    if avg < 400:
        tips.append(f"Posts are short (avg {avg} words). Target 500-600.")
    elif avg > 800:
        tips.append(f"Posts are long (avg {avg} words). Consider 500-600.")
    
    return tips

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "tips":
        for tip in get_writing_tips():
            print(f"💡 {tip}")
    else:
        update_feedback()
