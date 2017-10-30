$stdout.sync = true

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

class Position
  TIME_PATTERN = "%Y-%m-%d-%H-%M-%S"
  WAIT_SECONDS = 2

  def initialize(position)
    @position = position
    @created_at = Time.now
  end

  def snap!
    goto!
    WAIT_SECONDS.times { print '#'; sleep(1) }
    print "\n"
    get_image!
  end

  def goto!
    puts "Switching to #{@position}..."
    RestClient.get("http://www.raibert.com:8085/axis-cgi/com/ptz.cgi?gotoserverpresetname=#{URI.escape(@position)}&camera=1&speed=100")
  end

  def get_image!
    response = RestClient.get("http://www.raibert.com:8085/axis-cgi/jpg/image.cgi?camera=1")

    File.write(filepath, response)
    puts "Wrote to file #{filepath}.\n\n"
  end

  def exists?
    File.exists?(self.filepath)
  end

  def filepath
    filename = "#{@position.gsub(" ", "_")}-#{@created_at.strftime(TIME_PATTERN)}.jpg"
    filepath = File.join("/code/images", filename)
  end
end

positions.each do |position|
  p = Position.new(position)
  10.times do
    begin
      if !p.exists?
        p.snap!
      end
    rescue Errno::ECONNREFUSED => e
      puts "Failed to connect. Retrying... \n"    
    end
  end
end
