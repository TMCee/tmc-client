require 'spec_helper'

describe TmcClient::Client do
  subject do 
    TmcClient::Client.new
  end

  before(:each) do
    subject.config = TmcClient::MyConfig.new
  end
  
  it "should print all course names when listing courses" do
    subject.courses = {"courses" =>  [{ "name" => "test_course1"}, {"name" => "test_course2" }] }
    output = double("output")
    output.expects(:puts).with("test_course1")
    output.expects(:puts).with("test_course2")
    subject.output = output
    subject.list_courses
  end

  it "should print all exercise names when listing exercises of a course" do
    subject.courses = {"courses" =>  [{ "name" => "test_course1", "exercises" => [{"name" => "test_ex1"}, {"name" => "test_ex2"}]}] }
    output = double("output")
    output.expects(:puts).with("test_ex1")
    output.expects(:puts).with("test_ex2")
    subject.output = output
    subject.list_exercises("test_course1")
  end
end