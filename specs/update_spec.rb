require_relative '../lib/tmc-client/client.rb'
require 'rspec'
require 'mocha/setup'

describe Client do
  subject do
    c = Client.new
  end

  after(:each) do
    `rm -r update_universal_ex`
    `rm -r update_ex`
  end

  it "should download all but contents of src folder with normal projects" do
    received_zip_data = mock("faraday_object")
    received_zip_data.expects(:body).returns(File.read(File.join(File.dirname(File.expand_path(__FILE__)), "update_ex.zip")))
    subject.expects(:fetch_zip).returns(received_zip_data)
    current_dir = subject.current_directory_name
    subject.courses = { "courses" => [{ "name" => current_dir, "exercises" => [{ "name" => "update_ex", "returnable" => true }, {"name" => "old", "returnable" => false}] }] }

    subject.update_exercise("update_ex")
    File.exists?("update_ex/included.txt").should == true
    File.exists?("update_ex/src/not_included.txt").should == false
  end

  it "should download all files when universal project" do
    received_zip_data = mock("faraday_object")
    received_zip_data.expects(:body).returns(File.read(File.join(File.dirname(File.expand_path(__FILE__)), "update_universal_ex.zip")))
    subject.expects(:fetch_zip).returns(received_zip_data)
    current_dir = subject.current_directory_name
    subject.courses = { "courses" => [{ "name" => current_dir, "exercises" => [{ "name" => "update_universal_ex", "returnable" => true }, {"name" => "old", "returnable" => false}] }] }

    subject.update_exercise("update_universal_ex")
    File.exists?("update_universal_ex/included.txt").should == true
    File.exists?("update_universal_ex/src/included.txt").should == true
  end
end