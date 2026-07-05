#!/usr/bin/env python3

import argparse
import os
import shutil
import subprocess
import sys
import yaml


def run(command, cwd=None):
    """Run shell command."""
    print(f"\n>>> {command}")
    subprocess.run(command, shell=True, cwd=cwd, check=True)


def clone_repo(repo_url, branch, directory):

    if os.path.exists(directory):
        shutil.rmtree(directory)

    run(f"git clone -b {branch} {repo_url} {directory}")


def update_values_yaml(values_file, image_repo, image_tag):

    print(f"Updating {values_file}")

    with open(values_file, "r") as f:
        values = yaml.safe_load(f)

    values["image"]["repository"] = image_repo
    values["image"]["tag"] = str(image_tag)

    with open(values_file, "w") as f:
        yaml.safe_dump(values, f, default_flow_style=False)

    print("Updated successfully.")


def git_commit_push(repo_dir, tag):

    run('git config user.name "narendra7306"', cwd=repo_dir)
    run('git config user.email "narendrareddy0a3@gmail.com"', cwd=repo_dir)

    run("git add .", cwd=repo_dir)

    status = subprocess.run(
        "git diff --cached --quiet",
        shell=True,
        cwd=repo_dir
    )

    if status.returncode == 0:
        print("No changes detected.")
        return

    run(
        f'git commit -m "Update image tags to {tag}"',
        cwd=repo_dir
    )

    run("git push origin master", cwd=repo_dir)


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument("--repo-url", required=True)
    parser.add_argument("--branch", default="master")

    parser.add_argument("--php-image", required=True)
    parser.add_argument("--mysql-image", required=True)

    parser.add_argument("--tag", required=True)

    parser.add_argument(
        "--frontend-values",
        default="frontend/values.yaml"
    )

    parser.add_argument(
        "--backend-values",
        default="backend/values.yaml"
    )

    args = parser.parse_args()

    repo_dir = "helm-repo"

    clone_repo(
        args.repo_url,
        args.branch,
        repo_dir
    )

    frontend_file = os.path.join(
        repo_dir,
        args.frontend_values
    )

    backend_file = os.path.join(
        repo_dir,
        args.backend_values
    )

    update_values_yaml(
        frontend_file,
        args.php_image,
        args.tag
    )

    update_values_yaml(
        backend_file,
        args.mysql_image,
        args.tag
    )

    git_commit_push(
        repo_dir,
        args.tag
    )

    print("\nHelm repository updated successfully.")


if __name__ == "__main__":
    main()

