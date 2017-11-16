require 'rest-client'
require 'uri'

class Position
  TIME_PATTERN = "midnight-%Y-%j"
  WAIT_SECONDS = 10
  BASEDIR = "D:/OH2-Grow/CactusLapsImages"
  APISRV = "http://www.raibert.com:8085"
  CAMERA_PARAM = "camera=1"

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
    Position.log "Switching to #{@position}..."
    RestClient.get("#{APISRV}/axis-cgi/com/ptz.cgi?gotoserverpresetname=#{URI.escape(@position)}&#{CAMERA_PARAM}&speed=70")
  end

  def self.all
    presets = RestClient.get("#{APISRV}/axis-cgi/com/ptz.cgi?query=presetposcam&#{CAMERA_PARAM}")
    presets.body.split("\r\n").drop(1).map do |preset|
      Position.new(preset.split("=").last)
    end
  end

  def self.laps
    ["Sag_CU-focus", "Sag CU", "Sag arm3 CU", "Sag upper",
     "SpikeTop", "Spike-Organ-Clarence", "Spike middle", "Wilt CU",
     "E barard1", "E barard2", "Mammilaria", "Opuntia Village",
     "Golden Barrels", "Sputnik", "Hook",
     "Silver Torch", "OldMan", "Bullet", "BulletMiddle",
     "Pachypodium", "Quimilo", "Barrel town", "Santa Rita",
     "MF Top", "MF middle",
     "Old Man Jr", "Menorah Jr", "Stetsona", "Red beards",
     "E variegated", "O variegated", "Twins",
     "PolygonaGetto", "Soft Serve", "Ruffles",
     "OctoberPoly", "Miles", "PolygonaGroup",
     "Bishops Cap", "SpineyGuy_CU", "Silver Dollar",
     "PonyTailTop", "Aloe tree"].map do |lap|
      Position.new(lap)
    end
  end

  def get_image!
    response = RestClient.get("#{APISRV}/axis-cgi/jpg/image.cgi?#{CAMERA_PARAM}")

    IO.binwrite(filepath, response)
    Position.log "Wrote to file #{filepath}\n\n"
  end

  def exists?
    File.exists?(self.filepath)
  end

  def filepath
    filename = "#{@position.gsub(" ", "_")}-#{@created_at.strftime(TIME_PATTERN)}.jpg"
    filepath = File.join(BASEDIR, filename)
  end

  LOGFILE = File.join(BASEDIR, "cactus.log")

  def self.log(msg)
    puts(msg)
    File.open(LOGFILE, 'a+') { |f| f.write("#{Time.now.strftime('%Y-%m-%d %I:%M:%S%p')}: #{msg.strip}\n") } if !msg.nil?
  end
end

class Cactus
  def self.run!
    begin
      $stdout.sync = true

      Position.laps.each do |position|
        10.times do
          begin
            if !position.exists?
              position.snap!
            end
          rescue Errno::ECONNREFUSED => e
            Position.log "Failed to connect. Retrying... \n"
          rescue => e
            Position.log("uncaught #{e} exception while handling connection: #{e.message}")
            Position.log("Stack trace: #{backtrace.map { |l| "  #{l}\n" }.join}")
          end
        end
      end
    rescue => e
      Position.log("uncaught #{e} exception while handling connection: #{e.message}")
      Position.log("Stack trace: #{backtrace.map { |l| "  #{l}\n" }.join}")
    end
  end
end

