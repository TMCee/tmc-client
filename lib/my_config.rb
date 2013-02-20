class MyConfig
  attr_accessor :config

  def initialize
    @config = get_config
  end

  def get_config
    begin
      YAML::load(File.open(File.join(File.dirname(File.expand_path(__FILE__)), "config.yml")))
    rescue
      puts "There is no config.yml file in the lib directory of tmc-client. You can find the template in file config.default.yml"
    end
  end

  def save_config
    File.open("lib/config.yml", "w") {|f| f.write(config.to_yaml) }
  end

  def username
    @config[:username]
  end

  def username=(name)
    @config[:username] = name
    save_config
  end

  def password
    @config[:password]
  end

  def server_url
    @config[:server_url]
  end

  def password=(pwd)
    @config[:password] = pwd
    save_config
  end

  def server_url=(url)
    @config[:server_url] = url
  end

  def course_id
    @config[:course_id]
  end

  def course_id=(id)
    @config[:course_id] = id
  end

  def save_course_path
    @config[:save_course_path]
  end


  def save_course_path=(path)
    path= "#{path}/" unless path[-1] == "/"
    @config[:save_course_path]=path
    save_config
  end
end