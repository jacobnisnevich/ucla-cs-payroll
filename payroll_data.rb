require 'httparty'
require 'open-uri'
require 'nokogiri'

year = 2014

professor_page = Nokogiri::HTML(open("http://www.cs.ucla.edu/faculty/"))
professor_profiles = professor_page.css("#post-538 .entry-content p")
professors = []

2.upto(professor_profiles.length - 1) do |professor_id|
  professor_profile = professor_profiles[professor_id].text.strip.split("\n")
  if !professor_profile.empty? && !professor_profile[0].split(",")[1].nil?
    professor_details = professor_profile[0].split(",")
    professor_name = professor_details[0].strip
    professor_title = professor_details[1].strip

    professors.push({
      :name => professor_name,
      :title => professor_title
    })
  end
end

professors_data = []

professors.each do |professor|
  professor_names = professor[:name].split(" ")

  response = HTTParty.get("https://ucannualwage.ucop.edu/wage/search.action?firstname=#{professor_names[0]}&"\
                          "lastname=#{professor_names[professor_names.length - 1]}&"\
                          "year=#{year}&"\
                          "location=Los+Angeles&"\
                          "title=&"\
                          "startSal=&"\
                          "endSal=&"\
                          "sort=asc&"\
                          "page=1&"\
                          "rows=20&"\
                          "sidx=EAW_LST_NAM&"\
                          "nd=1449437177748")
  parsed_response = JSON.parse(response.body.gsub("\n", "").gsub(" : ", ":").gsub(/'/,'"'))

  if parsed_response["records"].to_i > 0
    professors_data.push({
      :name => professor[:name],
      :title => professor[:title],
      :gross_pay => parsed_response["rows"][0]["cell"][6],
      :regular_pay => parsed_response["rows"][0]["cell"][7],
      :overtime_pay => parsed_response["rows"][0]["cell"][8],
      :other_pay => parsed_response["rows"][0]["cell"][9],
    })
  else 
    professors_data.push({
      :name => professor[:name],
      :title => professor[:title],
      :gross_pay => "-",
      :regular_pay => "-",
      :overtime_pay => "-",
      :other_pay => "-",
    })
  end
end

File.open("professors_data.json", 'w') do |file| 
  file.write("var data = " + professors_data.to_json)
end
