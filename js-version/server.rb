require "webrick"
require "fileutils"
srv = WEBrick::HTTPServer.new(DocumentRoot: "./",
                              BindAddress: "127.0.0.1",
                              Port: 20080)
srv.mount_proc("/compiled") do |req, res|
  p req.path
  fname = req.path.sub(/^\//, "")
  src_fname = File.basename(fname).sub(".compiled", "")
  FileUtils.mkdir_p File.dirname(fname)
  system "traceur --experimental --out #{fname} util.js prng.js factory-helper.js rough.js judge.js #{src_fname}" or abort "failed to compile"
  res.body = IO.binread(fname)
  res.content_type = "text/javascript"
end
trap("INT"){ srv.shutdown }
srv.start
