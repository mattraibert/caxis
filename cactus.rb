require 'rest-client'
require 'uri'
require 'csv'

class Position
  TIME_PATTERN = "night-Cam6-%Y-%j-%m-%s"
  RETRIES = 10
  RETRY_WAIT = 10
  WAIT_SECONDS = 5
  BASEDIR = "/Users/mattraibert/Downloads"
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
    Position.ptz!(to_query_params)
  end

  def self.all
    data = CSV.read("./shotlist.csv", headers: true)
    data.map do |row|
      Position.new(row)
    end
  end

  def to_query_params
    @position.to_hash.slice(*%w(focus tilt pan iris zoom)).map {|k, v| "#{k}=#{v}" }.join "&"
  end

  def self.ptz!(params)
    Position.axis_get("com/ptz.cgi?#{params}&#{CAMERA_PARAM}&speed=70")
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
    filename = "#{@position["Plant Name"].gsub(" ", "_")}-#{@created_at.strftime(TIME_PATTERN)}.jpg"
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
      Position.all.each do |position|
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

Cactus.run!
