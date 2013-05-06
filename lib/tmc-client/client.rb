require 'rubygems'
require 'highline/import'
require 'json'
require 'faraday'
require 'yaml'
require 'fileutils'
require 'tempfile'
require 'pp'
require 'zip/zip'
require_relative 'my_config'

class Client
  attr_accessor :courses, :config, :conn, :output, :input
  def initialize(output=$stdout, input=$stdin)
    @config = MyConfig.new
    @output = output
    @input = input
    setup_client
  end

  # stupid name - this should create connection, but not fetch courses.json!
  def init_connection()
    @conn = Faraday.new(:url => @config.server_url) do |faraday|
      faraday.request  :multipart
      faraday.request  :url_encoded             # form-encode POST params
      #faraday.response :logger                  # log requests to STDOUT We dont want to do this in production!
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    if @config.auth
      @conn.headers[Faraday::Request::Authorization::KEY] = @config.auth
    else
      auth
      @conn.headers[Faraday::Request::Authorization::KEY] = @config.auth
    end

  end

  def get(*args)
    target = args.first
    case target
      when 'url' then output.puts @config.server_url
      else output.puts "No property selected"
    end
  end

  def set(*args)
    target = args.first
    case target
      when "url"
        @config.server_url = args[1] if args.count >= 2
      else output.puts "No property selected"
    end
  end

  def check
    output.puts get_courses_json
  end

  def get_courses_json
    data = @conn.get('courses.json', {api_version: 5}).body
    raise "Error with autentikation" if data['error']
    data
  end

  # Path can be relative or absolute
  def is_universal_project?(path)
    File.exists? File.join(path, ".universal")
  end

  def get_password(prompt="Enter Password")
     ask(prompt) {|q| q.echo = false}
  end

  def auth
    output.print "Username: "
    username = @input.gets.chomp.strip
    password = get_password("Password (typing is hidden): ")
    @config.auth = nil
    @conn.basic_auth(username, password)
    @config.auth = @conn.headers[Faraday::Request::Authorization::KEY]
  end

  def request_server_url
    output.print "Server url: "
    @config.server_url = @input.gets.chomp.strip
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
      output.puts "#{ex['name']} #{ex['deadline']}" if ex["returnable"]
    end
  end

  def list_courses
    output.puts "No courses available. Make sure your server url is correct and that you have authenticated." if @courses.nil? or @courses["courses"].nil?
    @courses['courses'].each do |course|
      output.puts "#{course['name']}"
    end
  end

  def current_directory_name
    File.basename(Dir.getwd)
  end

  def previous_directory_name
    path = Dir.getwd
    directories = path.split("/")
    directories[directories.count - 2]
  end

  def init_course(course_name)
    FileUtils.mkdir_p(course_name)
    output.print "Would you like to download all available exercises? Yn"
    if ["", "y", "Y"].include? @input.gets.strip.chomp
      Dir.chdir(course_name) do
        download_new_exercises
      end
    end
  end

  def download(*args)
    if args.include? "all" or args.include? "-a" or args.include? "--all"
      download_new_exercises
    else
      download_new_exercise(*args)
    end
  end

  def solution(exercise_dir_name=nil)
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
    
    update_from_zip(exercise['solution_zip_url'], exercise_dir_name, course_dir_name, exercise, course)
  end

  def update_from_zip(zip_url, exercise_dir_name, course_dir_name, exercise, course)
    zip = fetch_zip(zip_url)
    output.puts "URL: #{zip_url}"
    work_dir = Dir.pwd
    to_dir = if Dir.pwd.chomp("/").split("/").last == exercise_dir_name
      work_dir
    else
      File.join(work_dir, exercise_dir_name)
    end
    Dir.mktmpdir do |tmpdir|
      Dir.chdir tmpdir do
        File.open("tmp.zip", 'wb') {|file| file.write(zip.body)}
        #`unzip -n tmp.zip && rm tmp.zip`
        full_path = File.join(Dir.pwd, 'tmp.zip')
        unzip_file(full_path, Dir.pwd, exercise_dir_name)
        `rm tmp.zip`
        files = Dir.glob('**/*')
        all_selected = false
        files.each do |file|
          next if file == exercise_dir_name or File.directory? file
          output.puts "Want to update #{file}? Yn[A]" unless all_selected
          input = @input.gets.chomp.strip unless all_selected
          all_selected = true if input == "A" or input == "a"
          if all_selected or (["", "y", "Y"].include? input)
            begin
              to = File.join(to_dir,file.split("/")[1..-1].join("/"))
              output.puts "copying #{file} to #{to}"
              unless File.directory? to
                FileUtils.mkdir_p(to.split("/")[0..-2].join("/"))
              else
                FileUtils.mkdir_p(to)
              end
              FileUtils.cp_r(file, to)
            rescue ArgumentError => e
             output.puts "An error occurred #{e}"
            end
          else
            output.puts "Skipping file #{file}"
          end
        end
      end
    end
  end

  def update_automatically_detected_project_from_zip(zip_url, exercise_dir_name, course_dir_name, exercise, course)
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
        # `unzip -n tmp.zip && rm tmp.zip`
        full_path = File.join(Dir.pwd, 'tmp.zip')
        unzip_file(full_path, Dir.pwd, exercise_dir_name)
        `rm tmp.zip`
        files = Dir.glob('**/*')

        files.each do |file|
          next if file == exercise_dir_name or file.to_s.include? "src" or File.directory? file
          begin
            to = File.join(to_dir,file.split("/")[1..-1].join("/"))
            output.puts "copying #{file} to #{to}"
            unless File.directory? to
              FileUtils.mkdir_p(to.split("/")[0..-2].join("/"))
            else
              FileUtils.mkdir_p(to)
            end
            FileUtils.cp_r(file, to)
          rescue ArgumentError => e
           output.puts "An error occurred #{e}"
          end
        end
      end
    end
  end

  def filter_returnable(exercises)
    exercises.collect { |ex| ex['name'] if ex['returnable'] }.compact
  end

  def download_new_exercises(course_dir_name=nil)
    course_dir_name = current_directory_name if course_dir_name.nil?
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    filter_returnable(course['exercises']).each do |ex_name|
      begin
        download_new_exercise(ex_name)
      rescue
      end
    end
  end

  def download_new_exercise(exercise_dir_name=nil)
    # Initialize course and exercise names to identify exercise to submit (from json)
    course_dir_name = current_directory_name
    exercise_dir_name.chomp("/")
    # Find course and exercise ids
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    exercise = course["exercises"].select { |ex| ex["name"] == exercise_dir_name }.first
    raise "Invalid exercise name" if exercise.nil?

    raise "Exercise already downloaded" if File.exists? exercise['name']
    zip = fetch_zip(exercise['zip_url'])
    File.open("tmp.zip", 'wb') {|file| file.write(zip.body)}
    full_path = File.join(Dir.pwd, 'tmp.zip')
    unzip_file(full_path, Dir.pwd, exercise_dir_name)
    #`unzip -n tmp.zip && rm tmp.zip`
    `rm tmp.zip`
  end

  def unzip_file (file, destination, exercise_dir_name)
    Zip::ZipFile.open(file) do |zip_file|
      zip_file.each do |f|
        merged_path = f.name.sub(exercise_dir_name.gsub("-", "/"), "")
        f_path=File.join(destination, exercise_dir_name, merged_path)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
  end

  # Filepath can be either relative or absolute
  def zip_file_content(filepath)
    `zip -r -q tmp_submit.zip #{filepath}`
    #`zip -r -q - #{filepath}`
  end

  # Call in exercise root
  # Zipping to stdout zip -r -q - tmc
  def submit_exercise(*args)
    # Initialize course and exercise names to identify exercise to submit (from json)
    if args.count == 0 or args.all? { |arg| arg.start_with? "-" }
      exercise_dir_name = current_directory_name
      course_dir_name = previous_directory_name
      zip_file_content(".")
    else
      exercise_dir_name = args.first
      course_dir_name = current_directory_name
      zip_file_content(exercise_dir_name)
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
    payload[:request_review] = true if args.include? "--request-review" or args.include? "-r" or args.include? "--review"
    payload[:paste] = true if args.include? "--paste" or args.include? "-p" or args.include? "--public"
    payload[:submission][:file] = Faraday::UploadIO.new('tmp_submit.zip', 'application/zip')
    tmp_conn = Faraday.new(:url => exercise['return_url']) do |faraday|
      faraday.request  :multipart
      faraday.request  :url_encoded             # form-encode POST params
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    tmp_conn.headers[Faraday::Request::Authorization::KEY] = @config.auth

    response = tmp_conn.post "?api_version=5&client=netbeans_plugin&client_version=1", payload
    submission_url = JSON.parse(response.body)['submission_url']
    puts "Submission url: #{submission_url}"

    if (args & %w{-q --quiet -s --silent}).empty?
      while status(submission_url) == "processing"
        sleep(1)
      end
    end
    
    FileUtils.rm 'tmp_submit.zip'
    payload
  end

  def status(submission_id_or_url)
    url = (submission_id_or_url.include? "submissions") ? submission_id_or_url : "/submissions/#{submission_id_or_url}.json?api_version=5"
    json = JSON.parse(@conn.get(url).body)
    if json['status'] != 'processing'
      puts "Status: #{json['status']}"
      puts "Points: #{json['points'].inspect}"
      puts "Tests:"
      json['test_cases'].each do |test|
        puts "#{test['name']} : #{(test['successful']) ? 'Ok' : 'Fail'}#{(test['message'].nil?) ? '' : (' : ' + test['message'])}"
      end
    end
    json['status']
  end

  def update_exercise(exercise_dir_name=nil)
    # Initialize course and exercise names to identify exercise to submit (from json)
    is_universal = false
    if exercise_dir_name.nil?
      exercise_dir_name = current_directory_name
      course_dir_name = previous_directory_name
      is_universal = true if File.exists? ".universal"
    else
      course_dir_name = current_directory_name
      is_universal = true if File.exists?(File.join("#{exercise_dir_name}", ".universal"))
    end

    exercise_dir_name.chomp("/")
    # Find course and exercise ids
    course = @courses['courses'].select { |course| course['name'] == course_dir_name }.first
    raise "Invalid course name" if course.nil?
    exercise = course["exercises"].select { |ex| ex["name"] == exercise_dir_name }.first
    raise "Invalid exercise name" if exercise.nil?

    if is_universal
      update_from_zip(exercise['zip_url'], exercise_dir_name, course_dir_name, exercise, course)
    else
      update_automatically_detected_project_from_zip(exercise['zip_url'], exercise_dir_name, course_dir_name, exercise, course)
    end
  end

  protected
  def setup_client
    begin
      @config.server_url ||= request_server_url
    rescue
      request_server_url
    end
    init_connection()
    if @config.auth
      begin
        @courses = JSON.parse get_courses_json
      rescue => e
        auth
      end
    else
      output.puts "No username/password. run tmc auth"
    end
  end
end