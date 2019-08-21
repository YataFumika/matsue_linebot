# frozen_string_literal: true

require 'json'
require 'net/http'

class GoogleMapApi
  BASE_URL = 'https://maps.googleapis.com/maps/api/directions/json?'

  attr_reader :now_x, :now_y, :go_x, :go_y, :response

  def initialize(now_x, now_y, go_x, go_y)
    @now_x = now_x
    @now_y = now_y
    @go_x = go_x
    @go_y = go_y

    @response = call
  end

  def call
    url = "#{BASE_URL}origin=#{now_x},#{now_y}&destination=#{go_x},#{go_y}&key=#{ENV['GOOGLE_MAP_API_KEY']}"
    JSON.load(Net::HTTP.get(URI.parse(url)))
  end
end
