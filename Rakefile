def run(command, min_exit_status = 0)
  puts "Executing: `#{command}`"
  system(command)
  return $?.exitstatus
end

end

desc "Generate changelog"
task :changelog do
  run("github_changelog_generator -u LocativeHQ -p Locative-iOS")
end
