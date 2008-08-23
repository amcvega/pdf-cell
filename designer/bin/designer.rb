#!/usr/bin/env ruby
#File.join(File.dirname(__FILE__), '..')
require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'pdf_cell')
root_path = File.join(File.dirname(__FILE__), '..')
file_name = ARGV[0]
directory = Dir.pwd

file_location  = File.join(directory, file_name)
puts "File location: #{file_location}"
file = File.new(file_location, "r")
result = ""
while(line = file.gets)
  result << line
end
pdf = PDF::Writer.new
result << "\npdf.compressed = true\npdf.render"    
eval(result)
output_path = File.join(root_path,"files/output.pdf")
pdf.save_as(output_path)
system("evince #{output_path}")
