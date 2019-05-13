workflow "automerge" {
  resolves = ["Merge pull requests"]
  on = "push"
}

action "Merge pull requests" {
  uses = "pascalgn/automerge-action@v0.1.1"
  secrets = ["GITHUB_TOKEN"]
}
