require "test_helper"

class SimulationControllerTest < ActionDispatch::IntegrationTest
  # POST /v1/simulation/case — creates a new simulation case
  test "POST case creates a new case and returns its external_id" do
    post "/v1/simulation/case", params: { byear: 1980, dyear: 2050, sex: 1 }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("external_id")
    assert body["external_id"].present?
  end

  test "POST case persists the case in the database" do
    assert_difference("Case.count", 1) do
      post "/v1/simulation/case", params: { byear: 1980, dyear: 2050, sex: 1 }
    end
  end

  # GET /v1/simulation/case/:case_id — shows an existing case
  test "GET case/:id returns 200 for an existing case" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}"
    assert_response :success
    case_obj.delete_all
  end

  test "GET case/:id response contains case and cvalues keys" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}"
    body = JSON.parse(response.body)
    assert body.key?("case")
    assert body.key?("cvalues")
    case_obj.delete_all
  end

  test "GET case/:id with non-existent id returns an error body" do
    get "/v1/simulation/case/00000000-0000-0000-0000-000000000000"
    body = JSON.parse(response.body)
    assert body.key?("error")
  end

  # PATCH /v1/simulation/case/:case_id — updates an existing case
  test "PATCH case/:id updates byear and returns the updated case" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    patch "/v1/simulation/case/#{case_obj.external_id}", params: { byear: 1985 }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1985, body["byear"]
    case_obj.delete_all
  end

  # DELETE /v1/simulation/case/:case_id — destroys a case and its associated data
  test "DELETE case/:id destroys the case" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    external_id = case_obj.external_id
    assert_difference("Case.count", -1) do
      delete "/v1/simulation/case/#{external_id}"
    end
  end

  test "DELETE case/:id returns a confirmation message" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    delete "/v1/simulation/case/#{case_obj.external_id}"
    body = JSON.parse(response.body)
    assert body.key?("message")
  end

  # GET /v1/simulation/case/:case_id/entries — returns entries for a case
  test "GET case/:id/entries returns 200" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}/entries"
    assert_response :success
    case_obj.delete_all
  end

  # POST /v1/simulation/case/:case_id/entry — creates a Cvalue entry
  test "POST case/:id/entry with type Cvalue creates a Cvalue" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    assert_difference("Cvalue.count", 1) do
      post "/v1/simulation/case/#{case_obj.external_id}/entry", params: {
        type: "Cvalue",
        cvalue: {
          cvaluetype: 1,
          label: "Salary",
          cto: 3000,
          ev: 0,
          t: 2025,
          fromt: 1980,
          tot: 2050,
          interest: 0,
          inflation: 0.02,
          cf_type: nil
        }
      }
    end
    case_obj.delete_all
  end

  test "POST case/:id/entry with type Cslice creates a Cslice" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    assert_difference("Cslice.count", 1) do
      post "/v1/simulation/case/#{case_obj.external_id}/entry", params: {
        type: "Cslice",
        cslice: {
          cvaluetype: 2,
          label: "Household",
          t: 2025,
          cvalues: [
            {
              cvaluetype: 2,
              label: "Rent",
              cto: 1200,
              ev: 0,
              t: 2025,
              fromt: 1980,
              tot: 2050,
              inflation: 0.02,
              interest: 0,
              cf_type: nil
            }
          ]
        }
      }
    end
    case_obj.delete_all
  end

  # GET /v1/simulation/case/:case_id/cslice/:cslice_id — shows a single cslice
  test "GET case/:case_id/cslice/:cslice_id returns 200" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    cslice = case_obj.cslices.create!(cvaluetype: 2, label: "Housing", t: 2025)
    get "/v1/simulation/case/#{case_obj.external_id}/cslice/#{cslice.id}"
    assert_response :success
    case_obj.delete_all
  end

  # DELETE /v1/simulation/case/:case_id/cvalue/:cvalue_id — destroys a standalone Cvalue
  test "DELETE cvalue/:id removes the Cvalue" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    cv = case_obj.cvalues.create!(
      cvaluetype: 1, label: "Salary", cto: 3000.to_d, ev: 0.to_d,
      t: 2025, fromt: 1980, tot: 2050, inflation: 0.to_d, interest: 0.to_d
    )
    assert_difference("Cvalue.count", -1) do
      delete "/v1/simulation/case/#{case_obj.external_id}/cvalue/#{cv.id}"
    end
    case_obj.delete_all
  end

  # DELETE /v1/simulation/case/:case_id/cslice/:cslice_id — destroys a Cslice
  test "DELETE cslice/:id removes the Cslice" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    cslice = case_obj.cslices.create!(cvaluetype: 2, label: "Housing", t: 2025)
    assert_difference("Cslice.count", -1) do
      delete "/v1/simulation/case/#{case_obj.external_id}/cslice/#{cslice.id}"
    end
    case_obj.delete_all
  end

  # GET /v1/simulation/case/:case_id/simulate — returns the timeline simulation
  test "GET simulate returns 200" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}/simulate"
    assert_response :success
    case_obj.delete_all
  end

  test "GET simulate returns a hash response" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}/simulate"
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
    case_obj.delete_all
  end

  test "GET simulate accepts a frequency param" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}/simulate", params: { frequency: 10 }
    assert_response :success
    case_obj.delete_all
  end

  # GET /v1/simulation/case/:case_id/simulate_detail — returns detail for a specific year
  test "GET simulate_detail with a valid year returns 200" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}/simulate_detail", params: { t: 2025 }
    assert_response :success
    case_obj.delete_all
  end

  test "GET simulate_detail without year param returns an informational message" do
    case_obj = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    get "/v1/simulation/case/#{case_obj.external_id}/simulate_detail"
    # Controller renders a plain JSON string when t is missing
    assert_match(/No year/, response.body)
    case_obj.delete_all
  end
end
