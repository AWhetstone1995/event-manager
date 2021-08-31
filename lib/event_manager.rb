require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry-byebug'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def save_time_target(name, time)
  # begin
  #   # binding.pry
  #   time_string = Date.strptime(time, '%y-%m-%d').to_s
  #   # time_string.strftime('%m/%d/%Y')
  #   Dir.mkdir('output/times') unless Dir.exist?('output/times')

  #   filename = "output/times/_#{name}.html"
  #   File.open(filename, 'w') do |file|
  #     file.puts "#{name} #{time_string}"
  #   end
  # rescue
  #   puts 'Invalid date'
  # end
end

def clean_numbers(name, number)
  number_string = number.to_s.gsub(/[^0-9]/, '')
  length = number_string.length
  case length
  when 10
    # do nothing
  when 11
    if number[0] == '1'
      number = number.to_s[1..-1].to_i
    else number = 'No Number'
    end
  else
    number = 'No Number'
  end
  Dir.mkdir('output/numbers') unless Dir.exist?('output/numbers')

  filename = "output/numbers/#{name}.txt"
  File.open(filename, 'w') do |file|
    file.puts number.to_s
  end
  number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_of_day = Array.new(CSV.read('event_attendees.csv').length - 1)
day_of_week = Array.new(CSV.read('event_attendees.csv').length - 1)
j = 0
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  number = clean_numbers(name, row[:homephone])
  # time = save_time_target(name, row[:regdate])
  legislators = legislators_by_zipcode(zipcode)

  date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
  hour_of_day[j] = date.hour
  day_of_week[j] = date.wday
  j += 1

  Dir.mkdir('output/times') unless Dir.exist?('output/times')

  filename = "output/times/_#{name}.txt"
  File.open(filename, 'w') do |file|
    file.puts "#{name}, #{date}"
  end

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

time_counts = Hash.new 0
day_counts = Hash.new 0

hour_of_day.each do |hour|
  time_counts[hour] += 1
end

day_of_week.each do |day|
  day_counts[day] += 1
end

time_counts = Hash[time_counts.sort_by { |hour, count| count }.reverse]
day_counts = Hash[day_counts.sort_by { |day, count| count }.reverse]

puts time_counts
puts day_counts
puts "Most Active Hour: #{hour_of_day.max_by { |a| hour_of_day.count(a) }}"
puts "Most Active Day: #{day_of_week.max_by { |a| day_of_week.count(a) }}"
