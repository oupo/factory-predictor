require "fileutils"
require_relative "../js-version/compile.rb"

def sys(cmd) puts cmd; system(cmd) or abort end

files = ["simple.html.js"]
dir = 'c:\users\user\repos\oupo.github.com\factory-predictor'

files.each do |file|
  compile file
  FileUtils.copy compiled_path(file), "#{dir}/compiled"
  Dir.chdir dir do
    sys "git add compiled/#{File.basename(compiled_path(file))}"
  end
end

Dir.chdir dir do
  sys 'git commit -m "update factory-predictor"'
  sys "git push origin master"
end

