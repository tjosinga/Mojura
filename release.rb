#!/usr/bin/ruby
# Author: Taco Jan Osinga


# This script requires highline. Do you get an error? Install it using 'gem install highline'
require 'highline/import'
require 'json'


# Check if there are unstaged files.
puts '----- Validating local repository -----'
status = `git status`
if !(status =~ /^On branch master$/)
	puts '[ERROR] Cannot release because you only release the master branch.'
	exit(1)
elsif !(status =~ /^nothing to commit, working directory clean$/)
	puts '[ERROR] Cannot release because you have local modifications.'
	exit(2)
end


# Get version information
puts '----- Gathering version information -----'
version_pattern = /^(\s*s\.version\s*=\s*')(\d+\.\d+\.\d+[\w-]*)(')\s*$/
release_date_pattern = /^(\s+s\.date\s+=\s+')(\d+-\d+-\d+)(')\s*$/
gemspec = File.read('mojura.gemspec');
current_version = gemspec.to_s.scan(version_pattern)[0][1]
expected_release_version = current_version.delete('-SNAPSHOT')
expected_release_version.delete!('-SNAPSHOT')

release_version = ask("What is the version of this release (#{expected_release_version}): ")
release_version = expected_release_version if release_version.to_s.empty?

expected_version_tag = 'v' + release_version
version_tag = ask("What is the scm tag for this release (#{expected_version_tag}): ")
version_tag = expected_version_tag if version_tag.to_s.empty?

parts = release_version.split('.', 4)
parts[2] = (parts[2].to_i + 1).to_s
parts.delete(3)
expected_snapshot_version =  parts.join('.') + '-SNAPSHOT'
snapshot_version = ask("What is the scm tag for this release (#{expected_snapshot_version}): ")
snapshot_version = expected_snapshot_version if snapshot_version.to_s.empty?


puts '----- Updating gemspec for this release -----'
gemspec.gsub!(version_pattern, "\\1#{release_version}\\3")
gemspec.gsub!(release_date_pattern, "\\1#{Date.today.iso8601.to_s}\\3")
File.write('mojura.gemspec', gemspec)


puts '----- Updating changelog for this release -----'
new_change_log = "##Version #{release_version}\n"
logs = `git log --oneline`.split(/\n/)
logs.each { | line |
	line.gsub!(/^\w+\s/, '')
	break if ((line.to_s.include?('[release tool]')) || (line == 'New version.'))
	new_change_log += "- #{line}\n"
}
new_change_log += "\n"

changelog = File.read('CHANGELOG.md')
insert_position = changelog.index('##')
changelog.insert(insert_position, new_change_log)
File.write('CHANGELOG.md', changelog)
system('vim CHANGELOG.md')


puts '----- Committing release version -----'

`git commit -a -m "[release tool] Releasing version #{version_tag}."`
`git tag #{version_tag}`


puts '----- Committing snapshot version -----'

gemspec.gsub!(version_pattern, "\\1#{snapshot_version}\\3")
File.write('mojura.gemspec', gemspec)
`git commit -a -m "[release tool] Perpare for next development iteration."`


puts '----- Pushing commits to the repository -----'
`git push`


puts '----- Building the gem -----'
`gem build mojura.gemspec`


puts '----- Store the gem at gems.mojura.nl. -----'
`gem push --host http://mojura:mojuragems@gems.mojura.nl`


puts '----- Update mojura locally. -----'
`gem install mojura --no-ri --no-rdoc`


puts "\n----- You successfully released version #{version_tag}. Happy coding. -----"
