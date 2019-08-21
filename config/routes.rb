# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'welcome#index'
  post '/callback' => 'line_bot#callback'
  get '/callback' => 'line_bot#callback'
end
