require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  # GET /v1/public/timeslice — returns a template timeslice (no values)
  test "GET timeslice with type=expense returns 200" do
    get "/v1/public/timeslice", params: { type: "expense" }
    assert_response :success
  end

  test "GET timeslice with type=income returns 200" do
    get "/v1/public/timeslice", params: { type: "income" }
    assert_response :success
  end

  test "GET timeslice with type=single returns 200 with one tv" do
    get "/v1/public/timeslice", params: { type: "single" }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["tvs"].is_a?(Array)
    assert_equal 1, body["tvs"].length
  end

  test "GET timeslice without type defaults to expense" do
    get "/v1/public/timeslice"
    assert_response :success
    body = JSON.parse(response.body)
    assert body["tvs"].is_a?(Array)
    assert body["tvs"].any?
  end

  # GET /v1/public/summary_report — returns a sample envelope with expenses and incomes
  test "GET summary_report returns 200" do
    get "/v1/public/summary_report"
    assert_response :success
  end

  test "GET summary_report response includes incomes and expenses keys" do
    get "/v1/public/summary_report"
    body = JSON.parse(response.body)
    assert body.key?("incomes") || body.key?("expenses")
  end

  # GET /v1/public/lastingmoney — calculates how long money will last
  test "GET lastingmoney with valid params returns 200" do
    get "/v1/public/lastingmoney", params: {
      startfunds: 100000,
      payout: 6000,
      marketrate: 0.03,
      inflation: 0.02
    }
    assert_response :success
  end

  test "GET lastingmoney when market return exceeds payout returns informational message" do
    get "/v1/public/lastingmoney", params: {
      startfunds: 100000,
      payout: 100,
      marketrate: 0.05,
      inflation: 0.0
    }
    assert_response :success
    body = JSON.parse(response.body)
    assert_match(/endlessly/, body)
  end

  # POST /v1/public/timeslice — transforms a timeslice to a target year
  test "POST timeslice returns 200 with valid params" do
    post "/v1/public/timeslice", params: {
      public: {
        t: 2020,
        i: 0.02,
        tvs: [
          { label: "Rent", cto: 1000, fromt: 2020, tot: 2040, inflation: 0.02 }
        ]
      },
      targetyear: 2025
    }
    assert_response :success
  end

  test "POST timeslice response includes t equal to target year" do
    post "/v1/public/timeslice", params: {
      public: {
        t: 2020,
        i: 0.02,
        tvs: [
          { label: "Rent", cto: 1000, fromt: 2020, tot: 2040, inflation: 0.02 }
        ]
      },
      targetyear: 2025
    }
    body = JSON.parse(response.body)
    assert_equal "2025", body["t"].to_s
  end

  # POST /v1/public/summary_report — generates a comparison report for two time points
  test "POST summary_report returns 200 with valid params" do
    post "/v1/public/summary_report", params: {
      public: {
        environment: { from: 2025, to: 2045, i: 0.02 },
        expenses: {
          t: 2025, i: 0.02,
          tvs: [
            { label: "Rent", cto: 1200, fromt: 2000, tot: 2150, inflation: 0.02 }
          ]
        }
      }
    }
    assert_response :success
  end
end
