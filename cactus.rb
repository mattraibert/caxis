require 'rest-client'
require 'uri'

positions = ["Old Man Jr", "Wilt CU", "Overview", "Sag CU", "SW", "West", "Spike-Organ-Clarence",
             "Spike middle", "Opuntia Village", "E barard1", "Mammilaria", "Quimilo",
             "E barard2", "Stetsona", "MF middle", "Santa Rita", "Silver Torch", "PonyTailTop",
             "North", "MF Top", "Red beards", "PolygonaGetto", "Soft Serve", "Spike top",
             "Pachypodium", "Golden Barrels", "Sag_CU-focus", "OldMan", "Hook", "Sag arm3 CU",
             "Scarpa-Polygona", "Sputnik", "Barrel town", "E variegated", "O variegated",
             "Ruffles", "SpineyGuy_CU", "Bishops Cap", "South", "Sag upper", "Bullet",
             "OctoberPoly", "PolygonaGroup", "Silver Dollar", "Twins", "Menorah Jr", "Aloe tree"]

wait_seconds = 5

time_pattern = "%Y-%m-%d-%H-%M-%S"


positions.each do |position|
  puts "Switching to #{position}..."
  RestClient.get("http://www.raibert.com:8085/axis-cgi/com/ptz.cgi?gotoserverpresetname=#{URI.escape(position)}&camera=1&speed=100")
  wait_seconds.times { sleep(1); print ?# }
  puts ?#

  response = RestClient.get("http://www.raibert.com:8085/axis-cgi/jpg/image.cgi?camera=1")

  filename = "#{position.gsub(" ", "_")}-#{Time.now.strftime(time_pattern)}.jpg"
  filepath = File.join("/code/images", filename)
  File.write(filepath, response)
  puts "Wrote to file #{filename}."
  puts "\n"
end

