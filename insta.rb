#!/usr/bin/env ruby
require 'instagram'
require './config.rb'

def usage
  puts 'instagram image printer example:'
  puts "#{__FILE__} love 60"
  exit
end

$search_tag = ARGV[0] || usage
$update_interval = ARGV[1].to_i || 60

Instagram.configure do |config|
  config.client_id = $client_id
  config.access_token = $access_token
end

def download_image (url)
  puts "Downloading #{url}"
  image = Net::HTTP.get(URI(url))
  filename = "images/#{Digest::MD5.hexdigest(url)}.jpg"

  File.open(filename, 'wb') do |save_file|
    save_file.write(image)
  end
  filename
end

def print_file(file_name)
  puts "Printing #{file_name}"
  system('lp', $print_params, file_name)
end

def fetch_images
  puts "Fetching images for hashtag \##{$search_tag}"
  images =  Instagram.tag_recent_media($search_tag)
  images.each do |image|
    created_time = image[:created_time].to_i
    if created_time > $check_time && image[:type] == 'image'
      image_url = image[:images][:standard_resolution][:url]
      image_path = download_image(image_url)
      print_file(image_path)
    end
  end
end

def current_time
  Time.now.getutc.to_i
end

def loop_fn
    puts 'time to fetch'
    fetch_images
    $check_time =  current_time
    sleep $update_interval
    loop_fn
end

$check_time = current_time
loop_fn
