"""Refresh the public control-plane catalog from the current GitHub visibility."""

import argparse
import datetime as dt
import json
import pathlib
import subprocess


OWNER = "Juri-Halveth"
CATALOG = pathlib.Path(__file__).resolve().parents[1] / "constellation" / "REPOSITORIES.json"
FIELDS = "name,nameWithOwner,url,visibility,isArchived,defaultBranchRef"


def public_repositories():
    result = subprocess.run(
        ["gh", "repo", "list", OWNER, "--limit", "100", "--json", FIELDS],
        check=True,
        capture_output=True,
        text=True,
    )
    repositories = json.loads(result.stdout)
    if len(repositories) >= 100:
        raise RuntimeError("Repository list reached its limit; refuse a partial catalog")
    public = []
    for repo in repositories:
        if repo["visibility"] != "PUBLIC":
            continue
        if not repo["nameWithOwner"].startswith(OWNER + "/"):
            raise RuntimeError("Unexpected repository owner")
        if repo["url"] != "https://github.com/" + repo["nameWithOwner"]:
            raise RuntimeError("Unexpected repository URL")
        public.append(repo)
    return sorted(public, key=lambda repo: repo["nameWithOwner"].casefold())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Compare without writing")
    args = parser.parse_args()
    public = public_repositories()
    if args.check:
        saved = json.loads(CATALOG.read_text(encoding="utf-8"))
        if saved.get("value") != public:
            raise SystemExit("Public catalog differs from current GitHub visibility")
        print(f"Current public catalog: {len(public)} repositories")
        return
    payload = {
        "capturedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "scope": "Current public owner repositories only; historical Git commits are separate",
        "value": public,
    }
    CATALOG.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote current public catalog: {len(public)} repositories")


if __name__ == "__main__":
    main()
