#!/usr/bin/env ruby
require 'instagram'
require './config.rb'

def usage
  puts 'instagram image printer example:'
  puts "#{__FILE__} love 60"
  exit
end

$search_tag = ARGV[0] || usage
$update_interval = (ARGV[1] || 60).to_i

Instagram.configure do |config|
  config.client_id = $client_id
  config.access_token = $access_token
end

def image_path(file)
  "images/#{Digest::MD5.hexdigest(file.to_s)}.jpg"
end


def download_image (url)
  puts "Downloading #{url}"
  image = Net::HTTP.get(URI(url))
  filename = image_path(url)

  File.open(filename, 'wb') do |save_file|
    save_file.write(image)
  end
  filename
end

def print_file(file_name)
  puts "Printing #{file_name}"
  system('lp', file_name)
end

def fetch_images
  puts "Fetching images for hashtag \##{$search_tag}"
  images =  Instagram.tag_recent_media($search_tag)
  images.each do |image|
    created_time = image[:created_time].to_i
    if created_time > $check_time && image[:type] == 'image'
      image_url = image[:images][:standard_resolution][:url]
      image_path = download_image(image_url)
      add_file_to_queue(image_path)
    end
  end
end

def current_time
  Time.now.getutc.to_i
end

def add_file_to_queue(file)
  @queue ||= []
  @queue.push(file)
  puts "Add #{file} to queue, length #{@queue.count}"
  if @queue.count == $images_per_page
    result_file = concat_images(@queue)
    @queue = []
    print_file(result_file)
  end
end

def concat_images(queue)
  out_file = image_path(current_time)
  cmd = %w[montage]
  cmd.concat(queue)
  cmd.push('-geometry')
  cmd.push('612x612+2+2')
  cmd.push(out_file)
  system(cmd.join(' '))
  out_file
end


$check_time = current_time
loop do
  puts 'time to fetch'
  fetch_images
  $check_time =  current_time
  print 'sleep '
  1.upto($update_interval) do |t|
    sleep 1;
    print $update_interval - t;
  end
  puts "\n"
end
