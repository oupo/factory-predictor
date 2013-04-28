require "fileutils"
require_relative "../compile.rb"

def sys(cmd) puts cmd; system(cmd) or abort end

html_files = ["simple.html", "index.html"]
other_files = ["entries.csv", "pokemon-names.txt", "icons.png"]
dir = 'c:\users\user\repos\oupo.github.com\factory-predictor'

epoch = Time.now.to_i

html_files.each do |file|
  js_file = "#{file}.js"
  compile js_file
  FileUtils.copy file, dir
  FileUtils.copy compiled_path(js_file), "#{dir}/compiled"
  data = File.binread("#{dir}/#{file}")
  open("#{dir}/#{file}", "wb") do |f|
    f.write data.sub(/<script src="compiled\/([^"]+)">/) {
      "<script src=\"compiled/#{$1}?#{epoch}\">"
    }
  end

  Dir.chdir dir do
    sys "git add #{file}"
    sys "git add compiled/#{File.basename(compiled_path(js_file))}"
  end
end

other_files.each do |file|
  FileUtils.copy file, dir
  Dir.chdir dir do
    sys "git add #{file}"
  end
end

Dir.chdir dir do
  sys 'git commit -m "update factory-predictor"'
  sys "git push origin master"
end

