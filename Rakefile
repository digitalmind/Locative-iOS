desc "Setup dev environment"
tas :setup do
  sh "carthage build --platform iOS"
end

desc "Start dev environment"
task :dev do
  sh "open Locative.xcworkspace"
end

desc "Generate changelog"
task :changelog do
  sh "github_changelog_generator -u LocativeHQ -p Locative-iOS"
end
