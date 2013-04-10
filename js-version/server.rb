require "webrick"
require "fileutils"
srv = WEBrick::HTTPServer.new(DocumentRoot: "./",
                              BindAddress: "127.0.0.1",
                              Port: 20080)
srv.mount_proc("/compiled") do |req, res|
  p req.path
  path = req.path.sub(/^\//, "")
  src_path = File.basename(path).sub(".compiled", "")
  # 出力先パスが違うディレクトリだとimportがうまくいかないので
  # まず今のディレクトリに出力してから後で移動する
  system "traceur --experimental --out #{File.basename(path)} #{src_path}" or abort "failed to compile"
  FileUtils.mkdir_p File.dirname(path)
  File.rename File.basename(path), path

  res.body = IO.binread(path)
  res.content_type = "text/javascript"
end
trap("INT"){ srv.shutdown }
srv.start
