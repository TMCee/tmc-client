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
      faraday.request  :multipart
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

  def fetch_zip(zip_url)
    @conn.get(zip_url)
  end

  def get_course_name
    get_my_course['name']
  end

  def list(mode=:courses)
    mode = mode.to_sym
    case mode
      when :courses
         list_courses
      when :exercises
          list_exercises
      else
    end
  end

  def list_exercises(course_dir_name=nil)
    course_dir_name = current_directory_name if course_dir_name.nil?
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    course["exercises"].each do |ex|
      puts "#{ex['name']} #{ex['deadline']}" if ex["returnable"]
    end
  end

  def list_courses
    @courses['courses'].each do |course|
      puts "#{course['id']} #{course['name']}"
    end
  end

  def current_directory_name
    path = File.basename(Dir.getwd)
  end

  def previous_directory_name
    path = Dir.getwd
    directories = path.split("/")
    directories[directories.count - 2]
  end

  def download_new_exercises(exercise_dir_name=nil)
    # Initialize course and exercise names to identify exercise to submit (from json)
    if exercise_dir_name.nil?
      exercise_dir_name = current_directory_name
      course_dir_name = previous_directory_name
    else
      course_dir_name = current_directory_name
    end

    exercise_dir_name.chomp("/")
    exercise_id = 0
    # Find course and exercise ids
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    exercise = course["exercises"].select { |ex| ex["name"] == exercise_dir_name }.first
    raise "Invalid exercise name" if exercise.nil?

    raise "Exercise already downloaded" if File.exists? exercise['name']
    zip = fetch_zip(exercise['zip_url'])
    File.open("tmp.zip", 'wb') {|file| file.write(zip.body)}
    `unzip -n tmp.zip && rm tmp.zip`
  end

  # Filepath can be either relative or absolute
  def zip_file_content(filepath)
    `zip -r -q tmp_submit.zip #{filepath}`
    `zip -r -q - #{filepath}`
  end

  # Call in exercise root
  # Zipping to stdout zip -r -q - tmc
  def submit_exercise(exercise_dir_name=nil)
    # Initialize course and exercise names to identify exercise to submit (from json)
    if exercise_dir_name.nil?
      exercise_dir_name = current_directory_name
      course_dir_name = previous_directory_name
      zipped = zip_file_content(".")
    else
      course_dir_name = current_directory_name
      zipped = zip_file_content(exercise_dir_name)
    end

    exercise_dir_name.chomp("/")
    exercise_id = 0
    # Find course and exercise ids
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    exercise = course["exercises"].select { |ex| ex["name"] == exercise_dir_name }.first
    raise "Invalid exercise name" if exercise.nil?

    # Submit
    payload={:submission => {}}
    payload[:submission][:file] = Faraday::UploadIO.new('tmp_submit.zip', 'application/zip')
    #payload = {:submission => {:file => zipped}}
    @conn.post "/exercises/#{exercise['id']}/submissions.json?api_version=5&client=netbeans_plugin&client_version=1", payload
    Fileutils.rm 'tmp_submit.zip'
    payload
  end

  # May require rewrite
  #Call in exercise root
  # Zipping to stdout zip -r -q - tmc
  def update_exercise(exercise_dir_name=nil)

    # Initialize course and exercise names to identify exercise to submit (from json)
    if exercise_dir_name.nil?
      exercise_dir_name = current_directory_name
      course_dir_name = previous_directory_name
    else
      course_dir_name = current_directory_name
    end

    exercise_dir_name.chomp("/")
    # Find course and exercise ids
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    exercise = course["exercises"].select { |ex| ex["name"] == exercise_dir_name }.first
    raise "Invalid exercise name" if exercise.nil?
    zip = fetch_zip(exercise['zip_url'])
    work_dir = Dir.pwd
    to_dir = if Dir.pwd.chomp("/").split("/").last == exercise_dir_name 
      work_dir 
    else
      File.join(work_dir, exercise_dir_name) 
    end
    Dir.mktmpdir do |tmpdir|
      Dir.chdir tmpdir do
        File.open("tmp.zip", 'wb') {|file| file.write(zip.body)}
        `unzip -n tmp.zip && rm tmp.zip`
        files = Dir.glob('**/*')
        files.each do |file|
          next if file == exercise_dir_name
          puts "Want to update #{file}? Yn"
          input = STDIN.gets.chomp.strip.downcase
          if input == "" or input == "y"
            begin
              to = File.join(to_dir,file.split("/")[1..-1].join("/"))
              puts "copying #{file} to #{to}"
              if to.split("/")[-1].include? "."
                FileUtils.mkdir_p(to.split("/")[0..-2].join("/"))
              else
                FileUtils.mkdir_p(to)
              end
              FileUtils.cp_r(file, to)
            rescue ArgumentError => e
             puts "An error occurred #{e}"
            end
          elsif input == "b"
            binding.pry
          else
            puts "Skipping file #{file}"
          end
        end
      end
    end
  end


end