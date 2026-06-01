class Rack::Attack
  Rack::Attack.enabled = !Rails.env.test?
  Rack::Attack.cache.store = Rails.cache

  safelist("allow-localhost") do |req|
    ["127.0.0.1", "::1"].include?(req.ip)
  end

  # Broad baseline limit for all incoming requests per source IP.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Public endpoints are easy to probe and should be stricter.
  throttle("public/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/v1/public")
  end

  # CPU-heavy calculator and simulation routes are throttled harder.
  throttle("compute/ip", limit: 20, period: 1.minute) do |req|
    next unless req.post?

    if req.path.start_with?("/v1/cs/") ||
       req.path.start_with?("/v1/simulation/") ||
       req.path.start_with?("/v1/agentdriver/")
      req.ip
    end
  end

  # If a token is provided, apply an additional per-token limit.
  throttle("api/token", limit: 120, period: 1.minute) do |req|
    auth_header = req.get_header("HTTP_AUTHORIZATION").to_s
    token = auth_header[/\AToken\s+(.+)\z/i, 1]
    token&.strip
  end

  self.throttled_responder = lambda do |_request|
    body = {
      error: "Rate limit exceeded",
      code: "rate_limited"
    }.to_json

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => "60"
      },
      [body]
    ]
  end
end
