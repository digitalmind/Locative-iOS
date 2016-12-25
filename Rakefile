desc "Setup dev environment"
task :setup do
  sh "carthage bootstrap --platform iOS --no-use-binaries"
end

desc "Start dev environment"
task :dev do
  sh "open Locative.xcworkspace"
end

desc "Generate changelog"
task :changelog do
  sh "github_changelog_generator -u LocativeHQ -p Locative-iOS"
end
