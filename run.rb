require "open-uri"
def prepare_traceur_js
  if not File.exists?("traceur.js")
    data = open("https://raw.github.com/google/traceur-compiler/master/bin/traceur.js").read
    File.binwrite "traceur.js", data
  end
end

def sys(cmd) system(cmd) or abort end

prepare_traceur_js
sys "traceur --experimental --out compiled.js hello.js"
sys "type traceur.js > compiled2.js"
sys "type compiled.js >> compiled2.js"
sys "node compiled2.js"
