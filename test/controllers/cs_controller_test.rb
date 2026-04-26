require "test_helper"

class CsControllerTest < ActionDispatch::IntegrationTest
  # GET /v1/cs/:countrycode/listschemes
  test "GET listschemes with valid countrycode returns 200" do
    get "/v1/cs/DE/listschemes"
    assert_response :success
  end

  test "GET listschemes returns a hash of schemes" do
    get "/v1/cs/DE/listschemes"
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
  end

  test "GET listschemes without countrycode returns error message" do
    # Route has optional countrycode, omitting it sends blank
    get "/v1/cs//listschemes"
    assert_response :success
    #body = JSON.parse(response.body)
    assert_match(/countrycode/, response.body)
  end

  # GET /v1/cs/:countrycode/listmeta
  test "GET listmeta with valid countrycode returns 200" do
    get "/v1/cs/DE/listmeta"
    assert_response :success
  end

  # GET /v1/cs/:countrycode/:schemetype
  test "GET get_schemetype for a valid schemetype returns 200" do
    get "/v1/cs/DE/tax"
    assert_response :success
  end

  test "GET get_schemetype response contains title and input keys" do
    get "/v1/cs/DE/tax"
    body = JSON.parse(response.body)
    assert body.key?("title")
    assert body.key?("input")
    assert body.key?("versions")
  end

  test "GET get_schemetype for an invalid schemetype returns error" do
    get "/v1/cs/DE/nonexistent_scheme"
    assert_response :success
    #body = JSON.parse(response.body)
    assert_match(/Error/, response.body)
  end

  test "GET get_schemetype for an invalid countrycode returns error" do
    get "/v1/cs/ZZ/tax"
    assert_response :success
    #body = JSON.parse(response.body)
    assert_match(/Error/, response.body)
  end

  # POST /v1/cs/:countrycode/:schemetype/:scheme/:version — runs a scheme calculation
  test "POST run_scheme without input payload returns error" do
    post "/v1/cs/DE/tax/estTarif/2024"
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("error")
  end

  test "POST run_scheme with valid inputs returns 200 with result" do
    post "/v1/cs/DE/tax/estTarif/2024",
         params: { c: { zv_einkommen: 50000 } }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
    assert body.key?("zv_einkommen")
  end

  test "POST run_scheme with an invalid schemetype returns error" do
    post "/v1/cs/DE/nonexistent/estTarif/2024",
         params: { c: { zv_einkommen: 50000 } }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("error")
  end

  # GET /v1/cs/:countrycode/meta/:metaschemetype
  test "GET get_metaschemetype for a valid meta schemetype returns 200" do
    get "/v1/cs/DE/meta/tax"
    assert_response :success
  end

  test "GET get_metaschemetype response contains versions key" do
    get "/v1/cs/DE/meta/tax"
    body = JSON.parse(response.body)
    assert body.key?("versions")
  end

  # GET /v1/cs/:countrycode/meta/:metaschemetype/:metascheme/:version
  test "GET get_metascheme with valid params returns 200" do
    get "/v1/cs/DE/meta/tax/income/2024"
    assert_response :success
  end

  test "GET get_metascheme response contains input key" do
    get "/v1/cs/DE/meta/tax/income/2024"
    body = JSON.parse(response.body)
    assert body.key?("input")
  end

  # POST /v1/cs/:countrycode/meta/:metaschemetype/:metascheme/:version — runs a meta scheme
  test "POST run_metascheme with valid inputs returns 200" do
    post "/v1/cs/DE/meta/tax/income/2024",
         params: { c: { zv_einkommen: 50000 } }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
  end

  test "POST run_metascheme without input returns error" do
    post "/v1/cs/DE/meta/tax/income/2024"
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("error")
  end
end
