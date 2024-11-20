Rack::Attack.throttle('requests/ip', limit: 100, period: 60) do |req|
  req.ip
end
