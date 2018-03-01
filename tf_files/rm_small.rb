`rsync -av  ~/Google\ Drive/Training\ Cactus/ ./data`
`find . -iname Icon* | xargs rm`
not_enough_photos = Dir[?*].map {|d| [d,Dir.chdir(d) { Dir[?*].count }] }.select {|k,v| v < 20 }.map(&:first)
