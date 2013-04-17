def compile(fname)
  dest_path = compiled_path(fname)
  # 出力先パスが違うディレクトリだとimportがうまくいかないので
  # まず今のディレクトリに出力してから後で移動する
  system "traceur --experimental --out #{File.basename(dest_path)} #{fname}" or abort "failed to compile"
  FileUtils.mkdir_p File.dirname(dest_path)
  File.rename File.basename(dest_path), dest_path
end

def compiled_path(fname)
  "compiled/#{fname.sub(".js", ".compiled.js")}"
end

if $0 == __FILE__
  compile "simple.html.js"
end
