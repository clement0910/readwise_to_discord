require 'httparty'
require 'json'
require 'time'

readwise_token = 'YOUR_READWISE_TOKEN'
discord_webhook_url = 'YOUR_DISCORD_WEBHOOK_URL'

def last_10_minutes
  current_time = Time.now
  rounded_minutes = current_time.min - current_time.min % 10
  rounded_time = Time.new(current_time.year, current_time.month, current_time.day, current_time.hour, rounded_minutes, 0)
  ten_minutes_before_rounded = rounded_time - 600
  ten_minutes_before_rounded.iso8601
end

def fetch_highlights(token)
  response = HTTParty.get("https://readwise.io/api/v2/export/",
                          query: { updatedAfter: last_10_minutes },
                          headers: {"Authorization" => "Token #{token}"})
  JSON.parse(response.body)['results']
end

def discord_message(article)
  { "embeds":
    article['highlights'].map do |highlight|
      {
        "title": article['title'],
        "url": article['source_url'],
        "color": 5814783,
        "fields": [
          {
            "name": "Author",
            "value": article['author'],
            "inline": true
          },
          {
            "name": "Category",
            "value": article['category'],
            "inline": true
          },
          {
            "name": "Note",
            "value": highlight['note'],
            "inline": false
          },
          {
            "name": "Highlight",
            "value": highlight['text'],
            "inline": false
          },
          {
            "name": "Highlighted At",
            "value": Time.parse(highlight['highlighted_at']).strftime("%d/%m/%Y %H:%M"),
            "inline": false
          }
        ],
        "image": {
          "url": article['cover_image_url']
        },
        "footer": {
          "text": "Partagé par Clément",
        }
      }
    end
  }
end

def send_discord_notification(webhook_url, message)
  HTTParty.post(webhook_url,
                body: discord_message(message).to_json,
                headers: {'Content-Type' => 'application/json'})
end

highlights = fetch_highlights(readwise_token)

highlights.each do |article|
  send_discord_notification(discord_webhook_url, article)
end
