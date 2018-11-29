require 'sinatra' # gem 'sinatra'
require 'line/bot' # gem 'line-bot-api'
require 'cloudinary'
require './lib/file_uploader'

def client
  @client ||= Line::Bot::Client.new {|config|
    config.channel_secret = '9c4a7983d05e6ea5a17bedce37603b5d'
    config.channel_token = 'tzUqqWp1OH8+yxclC7wjMmM2W76oeINaetuKnFS23JHF5qm7YQ5/Jnp/3hL4qAm5OAKrBC5p+u72aaimiEqffLicic1LE1a0EE/hLX4MlwHt3eHd8dqEewcRSsKwE8XpTcMYimaGlQ9sY+xCau49SwdB04t89/1O/w1cDnyilFU='
  }
end

get '/image/:id' do
  id = params['id']
  img = File.binread("/tmp/" + id)
  content_type "image/jpeg"
  img
end

post '/' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do
      'Bad Request'
    end
  end

  events = client.parse_events_from(body)

  events.each {|event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        text = event.message['text']

        case text
        when '一覧' then
          message = {
              type: 'text',
              text: 'ちょっと待ってね'
          }
          client.push_message(event['source']['userId'], message)
          google_drive_uploader = FileUploader::GoogleDriveUploader.new
          result = google_drive_uploader.list(3)
        else
          return 0
        end

        message = {
            type: 'text',
            text: result
        }
        client.reply_message(event['replyToken'], message)

      when Line::Bot::Event::MessageType::Image
        message = {
            type: 'text',
            text: 'ちょっと待ってね'
        }
        client.push_message(event['source']['userId'], message)

        id = event.message["id"]
        response = client.get_message_content(id)
        File.binwrite("tmp/" + id.to_s, response.body)

        cloudinary_uploader = FileUploader::CloudinaryUploader.new
        google_drive_uploader = FileUploader::GoogleDriveUploader.new

        cloudinary_url = cloudinary_uploader.upload("tmp/#{id}")
        google_drive_url = google_drive_uploader.upload("tmp/#{id}")
        message = {
            type: 'text',
            text: "Cloudinary:#{cloudinary_url}\nGoogleDrive:#{google_drive_url}"
        }
        client.reply_message(event['replyToken'], message)
      end
    end
  }

  "OK"
end
