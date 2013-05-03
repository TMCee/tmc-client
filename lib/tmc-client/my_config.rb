class MyConfig
  attr_accessor :config

  def initialize
    @config = get_config
  end

  def get_config
    begin
      yaml = YAML::load(File.open(File.join(File.dirname(File.expand_path(__FILE__)), "config.yml")))
    rescue
      raise "Error loading config.yml"
    end
    if yaml then yaml else {} end
  end

  def save_config
    File.open(File.open(File.join(File.dirname(File.expand_path(__FILE__)), "config.yml")), "w") {|f| f.write(config.to_yaml) }
  end

  def server_url
    @config[:server_url] unless @config.nil?
  end

  def server_url=(url)
    @config[:server_url] = url
    save_config
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

  def auth=(auth)
    @config[:auth] = auth
    save_config
  end

  def auth
    @config[:auth] unless @config.nil?
  end
end