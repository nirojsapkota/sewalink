require_relative 'config/environment'

puts "Testing Gemini Live Service directly..."
user = User.first || User.new(id: 1)

service = Gemini::LiveService.new(
  user: user,
  on_message: ->(msg) { puts "\n=== MESSAGE FROM GEMINI ===\n#{msg}\n===========================\n" }
)

service.connect

puts "Waiting 2 seconds for connection to open..."
sleep 2

puts "Sending text message..."
payload = {
  clientContent: {
    turns: [
      {
        role: "user",
        parts: [{ text: "Hello, what is your name?" }]
      }
    ],
    turnComplete: true
  }
}

service.instance_variable_get(:@ws).send(payload.to_json)

puts "Waiting 5 seconds for a response..."
sleep 5

puts "Closing..."
service.close
