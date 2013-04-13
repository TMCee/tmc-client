require 'rubygems'
require 'json'
require 'faraday'
require 'yaml'
require 'pry'
require 'fileutils'
require 'tempfile'
require 'pp'
require_relative 'my_config'

class Client
  attr_accessor :courses, :config, :conn
  def initialize()
    @config = MyConfig.new
    response = get_connection(@config.username,@config.password)
    @courses = JSON.parse response.body
  end

  # stupid name - this should create connection, but not fetch courses.json!
  def get_connection(username, password)
    @conn = Faraday.new(:url => @config.server_url) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT We dont want to do this in production!
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    @conn.basic_auth(username, password) # )
    @conn.get 'courses.json', {api_version: 5}
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

  def fetch_zip(zip_url)
    @conn.get(zip_url)
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

  def get_my_course(course_name=config.course_id)
    list = @courses['courses'].select {|course| course['id'] == config.course_id}
    list[0]
  end

  def current_directory_name
    path = File.basename(Dir.getwd)
  end

  def previous_directory_name
    path = Dir.getwd
    directories = path.split("/")
    directories[directories.count - 2]
  end

  def list(mode=nil)
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
    list = get_my_course['exercises']
    ask_course_id if list.empty?
    list.each do |ex|
      download_file(ex['zip_url'])
    end
  end

  # Filepath can be either relative or absolute
  def zip_file_content(filepath)
    `zip -r -q - #{filepath}`
  end

  # Call in exercise root
  # Zipping to stdout zip -r -q - tmc
  def update_exercise(exercise_dir_name=nil)
    # Initialize course and exercise names to identify exercise to submit (from json)
    if exercise_dir_name.nil?
      exercise_dir_name = get_current_directory_name
      course_dir_name = get_previous_directory_name
    else
      course_dir_name = get_current_directory_name
    end

    exercise_dir_name.chomp("/")
    exercise_id = 0
    zip_url=""
    # Find course and exercise ids
    @courses["courses"].each do |course|
      if course["name"] == course_dir_name
        course["exercises"].each do |exercise|
          if exercise["name"] == exercise_dir_name
            exercise_id = exercise["id"]
            zip_url = exercise["zip_url"]
          end
        end
      end
    end
    raise "UrlNotFound" if zip_url.empty?
    # and now download the zip file and extract it into a tmpdir.
    # Then copy all files except in src to this dir
    zip = fetch_zip(zip_url)
    Dir.mktmpdir do |dir|
      begin
        File.open("#{dir}/tmp.zip", 'wb') {|file| file.write(zip.body)} #unless File.exists? file_path
      rescue Errno::EISDIR
        binding.pry
      end
      result = `unzip -o #{dir}/tmp.zip -d #{dir}/`
      #now its in #{dir}/#{exercise_dir_name}
      from_dir = "#{dir}/#{exercise_dir_name}/"
      to_dir = "#{exercise_dir_name}/"
      copy_updateable_files(from_dir, to_dir)
    end
  end

  def copy_updateable_files(from_dir, to_dir)
    to_dir = "." if get_current_directory_name == to_dir.chomp("/")
    do_not_update = %w(src)
    Dir.glob("#{from_dir}**") do |file|
      filename = file.split("/")[-1]
      next if do_not_update.include? filename
      FileUtils.rm_rf("#{to_dir}/file")
      FileUtils.cp_r(file,"#{to_dir}/")
    end
  end

  # Call in exercise root
>>>>>>> update-action
  def submit_exercise(exercise_dir_name=nil)
    # Initialize course and exercise names to identify exercise to submit (from json)
    if exercise_dir_name.nil?
      exercise_dir_name = current_directory_name 
      course_dir_name = previous_directory_name
      zipped = zip_file_content(".")
    else
#<<<<<<< HEAD
#      course_dir_name = current_directory_name
#      zipped = zip_file_content(exercise_dir_name)
#=======
      course_dir_name = get_current_directory_name
      # Zip folder
      `zip -r zipped.zip #{exercise_dir_name}`
    end

    exercise_dir_name.chomp("/")
    exercise_id = 0
    # Find course and exercise ids
    @courses["courses"].each do |course|
      if course["name"] == course_dir_name
        course["exercises"].each do |exercise|
          if exercise["name"] == exercise_dir_name
            exercise_id = exercise["id"]
          end
        end
      end
    end

    # Submit
    payload = {:submission => zipped}
    @conn.post do |req|
      req.url "/exercises/#{exercise_id}/submissions"
      req.headers["Content-Type"] = "application/zip"
      req.body = "#{payload}"
    end
    payload
  end

end