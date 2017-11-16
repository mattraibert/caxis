require 'rest-client'
require 'uri'

class Position
  TIME_PATTERN = "midnight-%Y-%j"
  RETRIES = 10
  RETRY_WAIT = 10
  WAIT_SECONDS = 10
  BASEDIR = "D:/OH2-Grow/CactusLapsImages"
  APISRV = "http://www.raibert.com:8085"
  CAMERA_PARAM = "camera=1"
  LOGFILE = File.join(BASEDIR, "cactus.log")

  def initialize(position)
    @position = position
    @created_at = Time.now
  end

  def snap!
    goto!
    Position.log("Waiting #{WAIT_SECONDS} seconds")
    sleep(WAIT_SECONDS)
    print "\n"
    get_image!
  end

  def goto!
    Position.log "Switching to #{@position}..."
    Position.axis_get("com/ptz.cgi?gotoserverpresetname=#{URI.escape(@position)}&#{CAMERA_PARAM}&speed=70")
  end

  def self.all
    presets = Position.axis_get("com/ptz.cgi?query=presetposcam&#{CAMERA_PARAM}")
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
    response = Position.axis_get("jpg/image.cgi?#{CAMERA_PARAM}")

    IO.binwrite(filepath, response)
    Position.log "Wrote to file #{filepath}\n\n"
  end

  def exists?
    File.exists?(self.filepath)
  end

  def filepath
    filename = "#{@position.gsub(" ", "_")}-#{@created_at.strftime(TIME_PATTERN)}.jpg"
    File.join(BASEDIR, filename)
  end

  def self.log(msg)
    File.open(LOGFILE, 'a+') { |f| f.write("#{Time.now.strftime('%Y-%m-%d %I:%M:%S%p')}: #{msg.strip}\n") } if !msg.nil?
  end

  def self.axis_get(axis_request)
    Position.log(axis_request)
    RestClient.get("#{APISRV}/axis-cgi/"+axis_request)
  end
end

def safely
  if block_given?
    begin
      yield
    rescue => e
      Position.log("uncaught exception: #{e}")
      Position.log("Stack trace:\n#{e.backtrace.map { |l| "  #{l}\n" }.join}")
      Position.log("Waiting #{Position::RETRY_WAIT} seconds.")
      sleep(Position::RETRY_WAIT)
    end
  else
    raise "no block"
  end
end

class Cactus
  def self.run!
    $stdout.sync = true
    safely do
      Position.laps.each do |position|
        Position::RETRIES.times do
          safely do
            if !position.exists?
              position.snap!
            end
          end
        end
      end
    end
  end
end

