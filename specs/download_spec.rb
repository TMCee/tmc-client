require_relative '../lib/tmc-client/client.rb'
require 'rspec'
require 'mocha/setup'

describe Client do
  subject do
    c = Client.new
  end

  it "should be able to download a zip" do
    received_zip_data = mock("faraday_object")
    received_zip_data.expects(:body).returns(File.read(File.join(File.dirname(File.expand_path(__FILE__)), "ex.zip")))
    subject.expects(:fetch_zip).returns(received_zip_data)
    current_dir = subject.current_directory_name
    subject.courses = { "courses" => [{ "name" => current_dir, "exercises" => [{ "name" => "ex", "returnable" => true }, {"name" => "old", "returnable" => false}] }] }

    subject.download_new_exercise("ex")
    file_content = File.read("ex.rb")
    file_content.include?("def method").should == true
    `rm ex.rb`
  end

  it "should not download unreturnable exercises" do
    filtered = subject.filter_returnable([{ "name" => "true", "returnable" => true}, {"name" => "false", "returnable" => false }])
    filtered.count.should == 1
    filtered.first.should == "true"
  end
end