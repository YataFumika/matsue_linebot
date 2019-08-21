# frozen_string_literal: true

class LineBotController < ApplicationController
  require 'line/bot' # gem 'line-bot-api'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery except: [:callback]

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    head :bad_request unless client.validate_signature(body, signature)

    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text # もし文字を送ってきたら
          message = event.message['text']
          if message.match(/(不昧公)|(ふーまいこー)|(ふまいこう)|(ふー！まいこー！)/)
            client.reply_message(event['replyToken'], [replay_text('ふー！まいこー！'), voice])
          elsif message.match(/(おすすめのお店)/)
            client.reply_message(event['replyToken'], replay_images)
          else
            client.reply_message(event['replyToken'], replay_text('なんじゃ？申してみよ。'))
          end
        when Line::Bot::Event::MessageType::Location # もし位置情報を送ってきたら
          store = nearest_store(event.message)
          client.reply_message(event['replyToken'], [reply_button(store), replay_location(store), replay_text(store[:comment])])
        end
      end
    end

    head :ok
  end

  private

  def nearest_store(message)
    result_stores = stores.map do |store|
      response = GoogleMapApi.new(message['latitude'], message['longitude'], store[:ido], store[:keido]).response
      store[:dist] = response['routes'][0]['legs'][0]['distance']['value']
      store
    end

    Rails.logger.info(result_stores)

    result_stores.min { |a, b| a[:dist].to_i <=> b[:dist] }
  end

  def voice
    {
      "type": 'audio',
      "originalContentUrl": "#{ENV['HEROKU_URL']}/humaiko.m4a",
      "duration": 60_000
    }
  end

  def replay_images
    columns = stores.map do |store|
      {
        "imageUrl": store[:photo],
        "action": {
          "type": 'uri',
          "label": store[:name],
          "uri": store[:url]
        }
      }
    end

    {
      "type": 'template',
      "altText": 'this is a image carousel template',
      "template": {
        "type": 'image_carousel',
        "columns": columns
      }
    }
  end

  def replay_text(message)
    {
      type: 'text',
      text: message
    }
  end

  def replay_location(store)
    {
      "type": 'location',
      "title": store[:name],
      "address": store[:name],
      "latitude": store[:ido],
      "longitude": store[:keido]
    }
  end

  def reply_button(store)
    {
      "type": 'template',
      "altText": 'This is a buttons template',
      "template": {
        "type": 'buttons',
        "thumbnailImageUrl": store[:photo],
        "imageAspectRatio": 'rectangle',
        "imageSize": 'cover',
        "imageBackgroundColor": '#FFFFFF',
        "text": store[:name],
        "actions": [
          {
            "type": 'uri',
            "label": 'サイトを開く',
            "uri": store[:url]
          }
        ]
      }
    }
  end

  def stores
    [
      { name: '彩雲堂', ido: '35.463788', keido: '133.056385', url: 'https://www.saiundo.co.jp/', comment: 'ここのお店はなんと言っても「若草」。これがまた抹茶に合ってのぉ。シンプルイズザベストというやつじゃな。', photo: "#{ENV['HEROKU_URL']}/saiundo.png" },
      { name: '三英堂', ido: '35.464277', keido: '133.056574', url: 'https://www.3eido.jp/', comment: '最近の流行りは、「バエ」らしいな。このお店は、若者に新しい茶の湯の文化広めてくるはずじゃ。わしもバエを求めて参ろう。', photo: "#{ENV['HEROKU_URL']}/saneido.jpg" },
      { name: '中村茶舗', ido: '35.46443', keido: '133.055694', url: 'https://www.nippon-tea.co.jp/', comment: '宇治の茶問屋中村藤吉本店から分家した伝統あるお茶屋さんじゃ。挽きたての抹茶は格別なのじゃ〜♡', photo: "#{ENV['HEROKU_URL']}/kengau.jpg" },
      { name: '富田茶舗', ido: '35.464045', keido: '133.059227', url: 'https://www.tomita-ocha.jp/', comment: '深い味わいと香り、後味のスッキリしたお茶。撚りのかかった、しっかりした形状のお茶が特徴じゃ。', photo: "#{ENV['HEROKU_URL']}/tomita.png" },
      { name: '桂月堂', ido: '35.462652', keido: '133.056491', url: 'https://www.keigetsudo.jp', comment: '200年の歴史を持つ、ワシ好みのお菓子なんじゃよ。食べて欲しいのぉ。', photo: "#{ENV['HEROKU_URL']}/keigetu.png" },
      { name: '加島茶舗', ido: '35.469417', keido: '133.049785', url: 'http://www.e-ocha.jp/', comment: '店頭で淹れたての日本茶をテイクアウトできる「日本茶スタンド」が地元で評判のお店じゃ。余談じゃが、この店の店主は落語をしているそうじゃぞ〜', photo: "#{ENV['HEROKU_URL']}/katori.jpg" }
    ]
   end
end
