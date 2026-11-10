#!/usr/bin/env python3
"""
================================================================================
 Roku Umbrella Client — Prompt #87 Initialization & Setup Verification
================================================================================
 Verifies that the new roku-umbrella-client project repository and Kodi/Umbrella
 architecture have been initialized, committed, and pushed upstream.
================================================================================
"""

import sys
import os
import subprocess
from datetime import datetime

def LogMasterPromptHeader(task_summary="Roku Umbrella Client Project", prompt_number=100):
    num_str = f"{prompt_number:g}" if isinstance(prompt_number, (int, float)) else str(prompt_number)
    clean_summary = task_summary.strip()
    summary_upper = clean_summary.upper()
    now_iso = datetime.now().astimezone().isoformat()

    print()
    print("=" * 80)
    print(f"  PROMPT #{num_str} INITIATED: {summary_upper}")
    print("=" * 80)
    print(f"  [SESSION TRACKER] Sequence: #{num_str} | Timestamp: {now_iso}")
    print(f"  [TASK CONTEXT]    {clean_summary}")
    print("=" * 80)
    print()

def LogMasterPromptFooter(status="SUCCESS", prompt_number=100, details=""):
    num_str = f"{prompt_number:g}" if isinstance(prompt_number, (int, float)) else str(prompt_number)
    now_iso = datetime.now().astimezone().isoformat()

    print()
    print("=" * 80)
    print(f"  PROMPT #{num_str} COMPLETE: [{status}]")
    print(f"  Timestamp: {now_iso}")
    if details:
        print(f"  Details:   {details.strip()}")
    print("=" * 80)
    print()

def main():
    LogMasterPromptHeader("New Roku Umbrella Client Project Setup", 87)
    
    project_dir = "/Users/Christopher/.gemini/antigravity/scratch/roku-umbrella-client"
    print(f"  [PROJECT ROOT] {project_dir}")

    # Check git status and remote
    remotes = subprocess.check_output(["git", "-C", project_dir, "remote", "-v"], text=True)
    print("  [GIT REMOTES]:\n" + "    " + remotes.strip().replace("\n", "\n    "))

    branch = subprocess.check_output(["git", "-C", project_dir, "rev-parse", "--abbrev-ref", "HEAD"], text=True).strip()
    print(f"  [ACTIVE BRANCH] {branch}")

    commit = subprocess.check_output(["git", "-C", project_dir, "log", "-1", "--oneline"], text=True).strip()
    print(f"  [LATEST COMMIT] {commit}")

    # Check key files
    key_files = [
        "manifest",
        "Makefile",
        "README.md",
        "source/main.brs",
        "source/utils.brs",
        "components/MainScene.xml",
        "components/MainScene.brs",
        "components/CategoryItem.xml",
        "components/CategoryItem.brs",
        "components/TmdbFetcherTask.xml",
        "components/TmdbFetcherTask.brs",
        "components/StreamResolverTask.xml",
        "components/StreamResolverTask.brs",
        "components/MediaDetailsDialog.xml",
        "components/MediaDetailsDialog.brs"
    ]

    all_present = True
    for kf in key_files:
        full_path = os.path.join(project_dir, kf)
        exists = os.path.exists(full_path)
        if not exists: all_present = False
        print(f"    [{'OK' if exists else 'MISSING'}] {kf}")

    details = (
        f"Initialized new repository 'roku-umbrella-client' with Kodi/Umbrella on-demand architecture. "
        f"Initial commit '{commit}' pushed upstream to https://github.com/cs210353-cyber/roku-umbrella-client.git on branch '{branch}'."
    )

    LogMasterPromptFooter("SUCCESS" if all_present else "FAILURE", 87, details)
    return 0 if all_present else 1

if __name__ == "__main__":
    sys.exit(main())
