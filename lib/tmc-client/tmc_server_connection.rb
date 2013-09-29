require 'faraday'
require 'tmc-client/errors'
module TmcClient
  module TmcServerConnection
    include TmcClient::Errors

    def get_connection(options = {})
      @conn ||= init_connection()
    end

    def init_connection()
      conn = Faraday.new(:url => @config.server_url) do |faraday|
        faraday.request  :multipart
        faraday.request  :url_encoded             # form-encode POST params
        #faraday.response :logger                  # log requests to STDOUT We dont want to do this in production!
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      if @config.auth
        get_connection.headers[Faraday::Request::Authorization::KEY] = @config.auth
      else
        auth
        get_connection.headers[Faraday::Request::Authorization::KEY] = @config.auth
      end
    end

    def get_courses_json
      data = get_connection.get('courses.json', {api_version: 5}).body
      raise AuthFailedError if data['error']
      data
    end

    def auth
      output.print "Username: "
      username = @input.gets.chomp.strip
      password = get_password("Password (typing is hidden): ")
      @config.auth = nil
      get_connection.basic_auth(username, password)
      @config.auth = get_connection.headers[Faraday::Request::Authorization::KEY]
    end

    def fetch_zip(zip_url)
      get_connection.get(zip_url)
    end

    def status(submission_id_or_url)
      url = (submission_id_or_url.include? "submissions") ? submission_id_or_url : "/submissions/#{submission_id_or_url}.json?api_version=5"
      json = JSON.parse(get_connection.get(url).body)
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
  end
end