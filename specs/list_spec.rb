require_relative '../lib/tmc-client/client.rb'
require 'rspec'
require 'mocha'

describe Client do
  subject do 
    Client.new
  end

  it "should print all course names when listing courses" do
    subject.courses = {"courses" =>  [{ "name" => "test_course1"}, {"name" => "test_course2" }] }
    output = mock("output")
    output.expects(:puts).with("test_course1")
    output.expects(:puts).with("test_course2")
    subject.output = output
    subject.list_courses
  end
end