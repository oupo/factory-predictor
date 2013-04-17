require "webrick"
require "fileutils"
require_relative "compile.rb"

srv = WEBrick::HTTPServer.new(DocumentRoot: "./",
                              BindAddress: "127.0.0.1",
                              Port: 20080)
srv.mount_proc("/compiled") do |req, res|
  dest_path = req.path.sub(/^\//, "")
  src_path = File.basename(path).sub(".compiled", "")
  compile src_path
  res.body = IO.binread(dest_path)
  res.content_type = "text/javascript"
end
trap("INT"){ srv.shutdown }
srv.start
