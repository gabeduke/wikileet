workflow "automerge" {
  resolves = ["Merge pull requests"]
  on = "push"
}

action "Merge pull requests" {
  uses = "pascalgn/automerge-action@v0.1.1"
  secrets = ["GITHUB_TOKEN"]
}

workflow "preview-app" {
  resolves = ["Build and Deploy"]
  on = "pull_request"
}

action "Checkout repository" {
  uses = "actions/checkout@v2"
}

action "Set up Flutter" {
  uses = "subosito/flutter-action@v2"
  with = {
    flutter-version = "3.5.4"
  }
}

action "Install dependencies" {
  runs = "flutter pub get"
}

action "Build Flutter web app" {
  runs = "flutter build web"
}

action "Deploy to Firebase Hosting" {
  env = {
    FIREBASE_TOKEN = "${{ secrets.FIREBASE_TOKEN }}"
  }
  runs = """
    firebase use --add ${{ secrets.FIREBASE_PROJECT_ID }}
    firebase deploy --only hosting --project ${{ secrets.FIREBASE_PROJECT_ID }} --message "Deploying preview for PR #${{ github.event.number }}"
  """
}
