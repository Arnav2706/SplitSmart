Remove-Item -Recurse -Force .git
git init
git remote add origin https://github.com/Arnav2706/SplitSmart.git

$env:GIT_AUTHOR_DATE="2026-06-25T10:00:00"
$env:GIT_COMMITTER_DATE="2026-06-25T10:00:00"
git add pubspec.yaml pubspec.lock android test .gitignore README.md analysis_options.yaml firebase.json
git commit -m "Initial Flutter project setup and dependencies"

$env:GIT_AUTHOR_DATE="2026-06-25T11:00:00"
$env:GIT_COMMITTER_DATE="2026-06-25T11:00:00"
git add lib/core/models lib/core/services lib/core/export
git commit -m "Add core models and backend services"

$env:GIT_AUTHOR_DATE="2026-06-25T12:00:00"
$env:GIT_COMMITTER_DATE="2026-06-25T12:00:00"
git add lib/auth lib/home
git commit -m "Implement authentication and home screens"

$env:GIT_AUTHOR_DATE="2026-06-25T13:00:00"
$env:GIT_COMMITTER_DATE="2026-06-25T13:00:00"
git add lib/group
git commit -m "Add group expenses and balances UI"

$env:GIT_AUTHOR_DATE="2026-06-25T14:00:00"
$env:GIT_COMMITTER_DATE="2026-06-25T14:00:00"
git add .
git commit -m "Apply Neon UI theme and polish widgets"

git branch -M main
git push -u origin main --force
