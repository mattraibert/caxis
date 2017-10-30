$stdout.sync = true

require 'rest-client'
require 'uri'

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

  def self.all
    presets = RestClient.get("http://www.raibert.com:8085/axis-cgi/com/ptz.cgi?query=presetposcam&camera=1")
    presets.body.split("\r\n").drop(1).map do |preset|
      Position.new(preset.split("=").last)
    end
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
    filepath = File.join("images", filename)
  end
end

Position.all.each do |position|
  10.times do
    begin
      if !position.exists?
        position.snap!
      end
    rescue Errno::ECONNREFUSED => e
      puts "Failed to connect. Retrying... \n"
    end
  end
end
