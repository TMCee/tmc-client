require 'rubygems'
require 'json'
require 'faraday'
require 'yaml'
require 'pry'
require 'fileutils'
require_relative 'my_config'

class Client
  attr_accessor :courses, :config, :conn
  def initialize
    @config = MyConfig.new
    response = get_connection(@config.username,@config.password)
    @courses = JSON.parse response.body
  end


  def get_connection(username, password)
    @conn = Faraday.new(:url => @config.server_url) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    @conn.basic_auth(username, password) # )
    response = @conn.get 'courses.json', {api_version: 5}
  end

  def get_real_name(headers)
    name = headers['content-disposition']
    name.split("\"").compact[-1]
  end

  def download_file(path)
    ask_course_path unless @config.save_course_path
    loaded_file = @conn.get(path)
    real_name = get_real_name(loaded_file.headers)
    fname= path.split("/")[-1]
    course_name = get_course_name
    path = "#{config.save_course_path}#{course_name}/"
    begin
      FileUtils.mkdir_p(path) unless File.exists? path
    rescue Errno::EISDIR
      binding.pry
    end
    file_path = "#{path}#{real_name}"
    begin
      File.open(file_path, 'wb') {|file| file.write(loaded_file.body)} #unless File.exists? file_path
    rescue Errno::EISDIR
      binding.pry
    end
    result = `unzip -o #{file_path} -d #{path}`
    FileUtils.rm file_path
  end

  def ask_course_path
    puts "where to download?"
    @config.save_course_path=gets.chomp
  end

  def get_course_name
    get_my_course['name']
  end

  def list_courses
    @courses['courses'].each do |course|
      puts "#{course['id']} #{course['name']}"
    end
  end

  def get_my_course
    list = @courses['courses'].select {|course| course['id'] == config.course_id}
    list[0]
  end

  def get_my_exercise_name
    path = File.basename(Dir.getwd)
  end

  def get_my_course_name
    path = Dir.getwd
    directories = path.split("/")
    directories[directories.count - 2]
  end

  def list(mode)
    if mode.nil?
      puts "What would you like to list? Perhaps exercises with list exercises, or active projects with list active?"
      return
    end

    send("list_#{mode}")
  end

  def list_exercises
    list = get_my_course['exercises'].map {|ex| ex['name']}
    print_exercises(list)
  end

  def print_exercises(hash)
    list = hash.each {|ex| puts ex['name']}
  end

  def list_active
    list = get_my_course['exercises'].select {|ex| ex['returnable'] == true and ex['completed']==false}
    print_exercises(list)
  end

  def ask_for_course_id
    list_courses
    @config.course_id= gets.chomp
  end

  def download_all_available
    list = get_my_course['exercises'].each do |ex|
      download_file(ex['zip_url'])
    end
  end

  # Call in exercise root
  def submit_exercise
    exercise_id = 0
    # Find course and exercise ids
    @courses["courses"].each do |course|
      if course["name"] == get_my_course_name
        course["exercises"].each do |exercise|
          if exercise["name"] == get_my_exercise_name
            exercise_id = exercise["id"]
          end
        end
      end
    end

    # Zip folder
    `zip -r zipped.zip .`

    # Submit
    payload = {:submission => Faraday::UploadIO.new("zipped.zip", "application/zip")}
    @conn.post "/exercises/#{exercise_id}/submissions", payload

    # Delete zip
    `rm zipped.zip`
  end

end