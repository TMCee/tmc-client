require 'rubygems'
require 'highline/import'
require 'json'
require 'yaml'
require 'fileutils'
require 'tempfile'
require 'pp'
require 'tmc-client/my_config'
require 'tmc-client/errors'
require 'tmc-client/tmc_server_connection'
require 'tmc-client/zipper'

module TmcClient

  class Client

    include TmcClient::Zipper
    include TmcClient::TmcServerConnection

    attr_accessor :courses, :config, :output, :input
    def initialize(output=$stdout, input=$stdin)
      @config = MyConfig.new
      @output = output
      @input = input
      setup_client
    end

    # stupid name - this should create connection, but not fetch courses.json!

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

    # Path can be relative or absolute
    def is_universal_project?(path)
      File.exists? File.join(path, ".universal")
    end

    def get_password(prompt="Enter Password")
       ask(prompt) {|q| q.echo = false}
    end
    def request_server_url
      output.print "Server url: "
      @config.server_url = @input.gets.chomp.strip
    end

    def get_real_name(headers)
      name = headers['content-disposition']
      name.split("\"").compact[-1]
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
end