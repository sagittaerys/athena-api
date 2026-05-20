class Rack::Attack
  throttle("auth/register", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  throttle("auth/login", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  throttle("auth/refresh", limit: 30, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/refresh" && req.post?
  end

  self.throttled_responder = lambda do |_env|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Too many requests. Please try again later." }.to_json ]
    ]
  end
end