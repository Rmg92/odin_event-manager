require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  formatted_number = phone_number.gsub(/\D/, '')
  if formatted_number.length < 10 || formatted_number.length > 11
    'Wrong Number!'
  elsif formatted_number.length == 11
    formatted_number[0] == '1' ? formatted_number.slice(1, formatted_number.length - 1) : 'Wrong Number!'
  else
    formatted_number
  end
end

def strip_hours(datetime)
  Time.strptime(datetime, '%m/%d/%Y %k:%M').strftime('%H')
end

def strip_days(datetime)
  Time.strptime(datetime, '%m/%d/%Y %k:%M').strftime('%A')
end

def best_hour(reg_hours)
  reg_hours.tally.max { |pair1, pair2| pair1[1] <=> pair2[1] }[0]
end

def best_day(reg_days)
  reg_days.tally.max { |pair1, pair2| pair1[1] <=> pair2[1] }[0]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_hours = []
reg_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  reg_hours << strip_hours(row[:regdate])
  reg_days << strip_days(row[:regdate])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "The best hours to advertise are #{best_hour(reg_hours)}h"
puts "The best days to advertise are: #{best_day(reg_days)}"

puts 'EventManager finalized.'
