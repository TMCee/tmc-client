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
  
  after(:each) do
    `rm -r update_universal_ex 2>&1 /dev/null`
    `rm -r update_ex 2>&1 /dev/null`
  end

  it "should download all but contents of src folder with normal projects" do
    received_zip_data = double("faraday_object")
    received_zip_data.expects(:body).returns(File.read(File.join(File.dirname(File.expand_path(__FILE__)), "update_ex.zip")))
    subject.expects(:fetch_zip).returns(received_zip_data)
    current_dir = subject.current_directory_name
    subject.courses = { "courses" => [{ "name" => current_dir, "exercises" => [{ "name" => "update_ex", "returnable" => true }, {"name" => "old", "returnable" => false}] }] }

    subject.update_exercise("update_ex")
    File.exists?("update_ex/included.txt").should == true
    File.exists?("update_ex/src/not_included.txt").should == false
  end

  it "should download all files when universal project" do
    FileUtils.mkdir_p(File.join("update_universal_ex", ".universal"))

    received_zip_data = double("faraday_object")
    received_zip_data.expects(:body).returns(File.read(File.join(File.dirname(File.expand_path(__FILE__)), "update_universal_ex.zip")))
    input = double("input")
    input.expects(:gets).returns("A")
    subject.input = input
    subject.expects(:fetch_zip).returns(received_zip_data)
    current_dir = subject.current_directory_name
    subject.courses = { "courses" => [{ "name" => current_dir, "exercises" => [{ "name" => "update_universal_ex", "returnable" => true }, {"name" => "old", "returnable" => false}] }] }

    subject.update_exercise("update_universal_ex")
    File.exists?("update_universal_ex/included.txt").should == true
    File.exists?("update_universal_ex/src/included.txt").should == true
  end
end