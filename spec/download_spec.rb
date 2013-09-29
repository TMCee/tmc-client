require 'spec_helper'

TmcClient::Client.class_eval do
  def setup_client
  end
end

describe TmcClient::Client do
  subject do
    c = TmcClient::Client.new
  end

  before(:each) do
    subject.config = TmcClient::MyConfig.new
  end

  it "should be able to download a zip" do
    received_zip_data = double("faraday_object")
    received_zip_data.expects(:body).returns(File.read(File.join(File.dirname(File.expand_path(__FILE__)), "ex.zip")))
    subject.expects(:fetch_zip).returns(received_zip_data)
    current_dir = subject.current_directory_name
    subject.courses = { "courses" => [{ "name" => current_dir, "exercises" => [{ "name" => "ex", "returnable" => true }, {"name" => "old", "returnable" => false}] }] }

    subject.download_new_exercise("ex")
    file_content = File.read("ex.rb")
    file_content.include?("def method").should == true
    `rm -r ex 2&>1 /dev/null`
  end

  it "should not download unreturnable exercises" do
    filtered = subject.filter_returnable([{ "name" => "true", "returnable" => true}, {"name" => "false", "returnable" => false }])
    filtered.count.should == 1
    filtered.first.should == "true"
  end
end