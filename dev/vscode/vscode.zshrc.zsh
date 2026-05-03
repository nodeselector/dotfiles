alias code="code-insiders"

open_repo_vscode() {
    repo_path_for_repo $@ | fzf --query="$LBUFFER" | xargs code-insiders
}