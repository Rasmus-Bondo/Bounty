#!/usr/bin/env python3
"""Update the .graph knowledge graph from the Obsidian vault.

Parses structured vault markdown files deterministically (no LLM needed),
merges into the existing graph, clusters, labels communities, and regenerates
graph.json, graph.html, and GRAPH_REPORT.md.

Usage:
    python update_graph.py              # incremental (changed files only)
    python update_graph.py --full       # full rebuild from all vault files
    python update_graph.py --force      # allow the node count to shrink (after deleting vault files)
"""

import json
import re
import sys
from collections import Counter
from pathlib import Path

from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.report import generate
from graphify.export import to_json, to_html
from networkx.readwrite import json_graph

ROOT = Path(__file__).parent
BABGRAPH_DIR = ROOT / "LocalRedwaterCanyon"
GRAPH_DIR = ROOT / "graphs" / "RedwaterCanyonGraph"
MANIFEST_PATH = GRAPH_DIR / ".manifest.json"

CATEGORY_KEYWORDS = {
    "Combat": ["combat", "revolver", "shoot", "damage", "hit", "ammo", "reload", "gun", "bullet", "weapon"],
    "High Noon Ultimate": ["highnoon", "high noon", "ultimate", "charge", "targeting"],
    "Chrono Networking": ["chrono", "replicate", "entity", "networking"],
    "Player Data": ["data", "profile", "save", "persist", "leaderstats", "cash", "level", "xp"],
    "Round System": ["round", "lobby", "spawn", "zone", "intermission", "bandit"],
    "Movement": ["dash", "sprint", "crouch", "stamina", "movement"],
    "UI & HUD": ["gui", "hud", "ui", "healthbar", "health bar", "button", "overlay"],
    "Visual Effects": ["vfx", "effect", "particle", "laser", "beam", "muzzle", "impact", "dust"],
    "Audio": ["sound", "sfx", "audio", "footstep"],
    "Camera & ViewModel": ["camera", "viewmodel", "view model", "fov", "recoil", "sway", "bob"],
    "Server Bootstrap": ["main", "bootstrap", "start", "initialize"],
    "Ragdoll": ["ragdoll"],
    "Input": ["input", "keyboard", "mouse", "touch", "mobile"],
    "Testing": ["bot", "spawner", "test"],
}


def parse_frontmatter(text: str) -> dict:
    m = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        line = line.strip()
        if line.startswith("- "):
            continue
        if ":" in line:
            key, val = line.split(":", 1)
            fm[key.strip()] = val.strip()
    return fm


def extract_wikilinks(text: str) -> list[str]:
    return re.findall(r"\[\[([^\]|]+?)(?:\|[^\]]*?)?\]\]", text)


def parse_babgraph_file(filepath: Path) -> dict:
    text = filepath.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)

    script_name = filepath.stem
    node_id = script_name.lower().replace(" ", "_")
    label = script_name
    script_path = fm.get("path", "")
    script_type = fm.get("type", "unknown")

    side = "server"
    if "client" in text.lower()[:200] or "localscript" in script_type.lower():
        side = "client"
    elif "modulescript" in script_type.lower():
        side = "shared"

    file_type = "code"
    rel_path = str(filepath.relative_to(ROOT)).replace("\\", "/")

    node = {
        "id": node_id,
        "label": label,
        "file_type": file_type,
        "source_file": rel_path,
        "source_location": script_path,
        "script_type": script_type,
        "side": side,
    }

    edges = []
    wikilinks = extract_wikilinks(text)
    seen_targets = set()
    for link in wikilinks:
        target_id = link.lower().replace(" ", "_")
        if target_id == node_id or target_id in seen_targets:
            continue
        seen_targets.add(target_id)

        relation = "references"
        confidence = "EXTRACTED"
        score = 1.0

        lower_text = text.lower()
        link_lower = link.lower()
        if f"require" in lower_text and link_lower in lower_text:
            relation = "calls"
        elif "remoteevent" in lower_text or "bindableevent" in lower_text:
            relation = "communicates_with"

        edges.append({
            "source": node_id,
            "target": target_id,
            "relation": relation,
            "confidence": confidence,
            "confidence_score": score,
            "source_file": rel_path,
            "weight": 1.0,
        })

    return {"node": node, "edges": edges}


def load_manifest() -> dict:
    if MANIFEST_PATH.exists():
        return json.loads(MANIFEST_PATH.read_text())
    return {}


def save_manifest(files: list[Path]):
    manifest = {}
    for f in files:
        manifest[str(f)] = f.stat().st_mtime
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2))


def detect_changed(all_files: list[Path], full: bool) -> list[Path]:
    if full:
        return all_files
    manifest = load_manifest()
    changed = []
    for f in all_files:
        key = str(f)
        mtime = f.stat().st_mtime
        if key not in manifest or manifest[key] < mtime:
            changed.append(f)
    return changed


def label_community(node_ids: list[str], all_nodes: dict) -> str:
    text_blob = " ".join(node_ids).lower()
    for nid in node_ids:
        if nid in all_nodes:
            n = all_nodes[nid]
            text_blob += " " + n.get("label", "").lower()
            text_blob += " " + n.get("source_file", "").lower()

    scores = {}
    for cat, keywords in CATEGORY_KEYWORDS.items():
        scores[cat] = sum(text_blob.count(kw) for kw in keywords)

    best = max(scores, key=scores.get)
    if scores[best] == 0:
        if len(node_ids) == 1:
            return all_nodes.get(node_ids[0], {}).get("label", f"Cluster {node_ids[0]}")
        return "Miscellaneous"
    return best


def main():
    full = "--full" in sys.argv
    force = "--force" in sys.argv

    GRAPH_DIR.mkdir(exist_ok=True)

    all_files = sorted(BABGRAPH_DIR.rglob("*.md"))
    if not all_files:
        print("No markdown files found in LocalRedwaterCanyon/")
        return

    changed = detect_changed(all_files, full)
    mode = "full rebuild" if full else "incremental"
    print(f"[update_graph] {mode}: {len(changed)} changed / {len(all_files)} total files")

    if not changed and not full:
        print("[update_graph] Nothing changed. Use --full to force rebuild.")
        return

    # Parse ALL files (we need the full node set for edge resolution)
    nodes = []
    edges = []
    for f in all_files:
        result = parse_babgraph_file(f)
        nodes.append(result["node"])
        edges.extend(result["edges"])

    # Filter edges to only reference existing nodes
    node_ids = {n["id"] for n in nodes}
    valid_edges = [e for e in edges if e["source"] in node_ids and e["target"] in node_ids]
    orphan_count = len(edges) - len(valid_edges)

    extraction = {
        "nodes": nodes,
        "edges": valid_edges,
        "hyperedges": [],
        "input_tokens": 0,
        "output_tokens": 0,
    }

    print(f"[update_graph] Extracted {len(nodes)} nodes, {len(valid_edges)} edges ({orphan_count} orphan edges skipped)")

    # Build graph
    G = build_from_json(extraction)
    communities = cluster(G)
    cohesion = score_all(G, communities)
    gods = god_nodes(G)
    surprises = surprising_connections(G, communities)

    # Label communities
    all_nodes_map = {n["id"]: n for n in nodes}
    labels = {}
    for cid, members in communities.items():
        labels[cid] = label_community(members, all_nodes_map)

    # Deduplicate labels
    label_counts = Counter(labels.values())
    for cid, lbl in labels.items():
        if label_counts[lbl] > 1:
            members = communities[cid]
            if len(members) == 1:
                labels[cid] = all_nodes_map.get(members[0], {}).get("label", lbl)

    questions = suggest_questions(G, communities, labels)

    detection = {
        "total_files": len(all_files),
        "total_words": sum(f.stat().st_size // 5 for f in all_files),
        "needs_graph": True,
        "warning": None,
        "files": {"code": [], "document": [str(f) for f in all_files], "paper": []},
        "skipped_sensitive": [],
    }
    tokens = {"input": 0, "output": 0}

    report = generate(G, communities, cohesion, labels, gods, surprises, detection, tokens, "LocalRedwaterCanyon", suggested_questions=questions)
    (GRAPH_DIR / "GRAPH_REPORT.md").write_text(report, encoding="utf-8")
    to_json(G, communities, str(GRAPH_DIR / "graph.json"), force=force)

    if G.number_of_nodes() <= 5000:
        to_html(G, communities, str(GRAPH_DIR / "graph.html"), community_labels=labels)
        print(f"[update_graph] graph.html written")

    save_manifest(all_files)

    print(f"[update_graph] Done: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges, {len(communities)} communities")
    print(f"[update_graph] Outputs: {GRAPH_DIR}/graph.json, {GRAPH_DIR}/graph.html, {GRAPH_DIR}/GRAPH_REPORT.md")


if __name__ == "__main__":
    main()
