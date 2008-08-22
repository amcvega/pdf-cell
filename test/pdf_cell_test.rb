#!/usr/bin/env ruby
require 'rubygems'
require 'pdf/writer'
require '../lib/pdf_cell'
require 'active_support'

pdf = PDF::Writer.new
biodata = PDF::Cell::Base.new(pdf)

biodata.build :width => 500, :font_size => 8 do
  header "Crew File #245: Jack Black (2/M of MV Nautilus)", :shaded => true, 
                                                            :font_size => 15 
  
  desc "The Context"
  cell :width => 375 do
    cell :width => 125 do
      text "<b>Given Name</b>"
      text "Jack"
    end
    cell :width => 125 do
      text "<b>Middle Name</b>"
      text "James"
    end
    cell :width => 125 do
      text "<b>Family Name</b>"
      text "Black"
    end
    cell :width => 250 do
      text "<b>Address</b>"
      text "#124 Main Street"
    end
    cell :width => 125 do
      text "<b>Contact No</b>"
      text "123-456-789"
    end
    cell :width => 125 do
      text "<b>Date of Birth</b> 1985-01-01"
    end
    cell :width => 125 do
      text "<b>Age</b> 22"
    end
    cell :width => 125 do
      text "<b>Birthplace</b> New Jersey"
    end
    cell :width => 125 do
      text "<b>Nationality</b> English"
    end
    cell :width => 125 do
      text "<b>Civil Status</b>  Married"
    end
    cell :width => 125 do
      text "<b>Eye Color</b> Blue"
    end
    cell :width => 125 do
      text "<b>Weight</b> 125"
    end
    cell :width => 125 do
      text "<b>Height</b> 123"
    end
    cell :width => 125 do
      text "<b>SSS No.</b> asdfa"
    end
    cell :width => 125 do
      text "<b>TIN</b>  asdfa"
    end
    cell :width => 125 do
      text "<b>Shoe Size</b> aasdf"
    end
    cell :width => 375 do
      text "<b>Name of Spouse</b> Gina Black"
    end
    cell :width => 375, :height => 50 do
      text "<b>Spouse's Contact No / Address</b>"
      text "123-9876"
    end
  end
  cell :width => 125, :height => 125 do
    text "Photo Here"
  end
end

pdf.save_as("biodata_result.pdf")
