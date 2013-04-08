require "webrick"
srv = WEBrick::HTTPServer.new(DocumentRoot: "./",
                              BindAddress: "127.0.0.1",
                              Port: 20080)
srv.mount_proc("/compiled.js") do |req, res|
  system "traceur --experimental --out compiled.js util.js prng.js factory-helper.js rough.js judge.js web.js" or abort "failed to compile"
  res.body = IO.binread("compiled.js")
  res.content_type = "text/javascript"
end
trap("INT"){ srv.shutdown }
srv.start
