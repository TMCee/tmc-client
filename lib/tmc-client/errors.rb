module TmcClient
  module Errors
    class Error < StandardError; end
    class ConnectionError < Error; end
    class AuthFaildedError < Error; end
  end
end