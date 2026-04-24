require "test_helper"

class PensionControllerTest < ActionDispatch::IntegrationTest
  # GET /v1/pension/sample — returns sample input structure
  test "GET sample returns 200" do
    get "/v1/pension/sample"
    assert_response :success
  end

  test "GET sample response contains person and pensionplan keys" do
    get "/v1/pension/sample"
    body = JSON.parse(response.body)
    assert body.key?("person")
    assert body.key?("pensionplan")
  end

  # POST /v1/pension/:ptype/payout — routes to the appropriate pension calculator
  test "POST unknown ptype returns bad_request" do
    post "/v1/pension/unknown_type/payout", params: {
      person: { birthyear: 1970 },
      pensionplan: { provider: "drv-west", startsaving: 2000,
                     endsaving: 2035, startpayout: 2035 }
    }
    assert_response :bad_request
  end

  test "POST unknown ptype response body contains error key" do
    post "/v1/pension/unknown_type/payout", params: {
      person: { birthyear: 1970 },
      pensionplan: { provider: "drv-west", startsaving: 2000,
                     endsaving: 2035, startpayout: 2035 }
    }
    body = JSON.parse(response.body)
    assert body.key?("error")
  end

  test "POST drv payout without person params returns error" do
    post "/v1/pension/drv/payout", params: {
      pensionplan: { provider: "drv-west", startpayout: 2037 }
    }
    assert_response :success
    body = JSON.parse(response.body)
    # Response is a plain error string (rendered as json)
    assert body.present?
  end

  test "POST drv payout without pensionplan params returns error" do
    post "/v1/pension/drv/payout", params: {
      person: { birthyear: 1970 }
    }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.present?
  end

  test "POST drv payout with valid params returns 200" do
    post "/v1/pension/drv/payout", params: {
      person: { birthyear: 1970 },
      pensionplan: {
        provider: "drv-west",
        startsaving: 2000,
        endsaving: 2035,
        startpayout: 2035
      },
      drv: {
        annahmen: { rentenanpassung: 0.01, extrapolation: "typ" }
      }
    }
    assert_response :success
  end

  test "POST drv payout response contains pension_simulation key" do
    post "/v1/pension/drv/payout", params: {
      person: { birthyear: 1970 },
      pensionplan: {
        provider: "drv-west",
        startsaving: 2000,
        endsaving: 2035,
        startpayout: 2035
      }
    }
    body = JSON.parse(response.body)
    # The jbuilder view wraps the response in pension_simulation
    assert body.key?("pension_simulation")
  end

  test "POST wpv payout with valid params returns 200" do
    post "/v1/pension/wpv/payout", params: {
      person: { birthyear: 1970 },
      pensionplan: {
        provider: "sample-provider",
        startsaving: 2000,
        endsaving: 2035,
        startpayout: 2035
      }
    }
    assert_response :success
  end

  test "POST wpv payout response contains pension_simulation key" do
    post "/v1/pension/wpv/payout", params: {
      person: { birthyear: 1970 },
      pensionplan: {
        provider: "sample-provider",
        startsaving: 2000,
        endsaving: 2035,
        startpayout: 2035
      }
    }
    body = JSON.parse(response.body)
    assert body.key?("pension_simulation")
  end
end
