module V1::TemplateHandler
  # This is for simulations to manage the flow and provision of templates, that are stored in jsonlib.
  # Basically, there is a template for each planitem and a generic one. All is country based.

  TEMPLATE_DIR = Rails.root.join("jsonlib")
  TEMPLATE_SUFFIX = ".flow.json"

  # Response to GET /v1/simulation/templates/planitems
  def template_planitems
    all_plan_types = Planitem::PLAN_TYPES.map do |key, value|
      {
        key: key,
        value: value,
        label: Planitem::PLANTYPE_LABELS[key],
        icon: Planitem::PLANTYPE_ICONS[key]
      }
    end

    result = Planitem.categories.map do |cat_key, cat_value|
      {
        key: cat_key,
        value: cat_value,
        label: Planitem::CATEGORY_LABELS[cat_key],
        plan_types: all_plan_types.select { |pt| cat_value == 1 ? pt[:value] <= 9 : pt[:value] > 9 }
      }
    end

    render json: result
  end

  # GET /v1/simulation/templates/(:country)
  # Optional param: plan_type – filters results to a specific plan type
  def template_index
    country = sanitize_template_key(params[:country]) || "DE"
    plan_type_filter = sanitize_template_key(params[:plan_type])

    templates = SimTemplate.new.list_templates(country, plan_type_filter)
    render json: { country: country, templates: templates }
  end

  # GET /v1/simulation/templates/(:country)/(:plan_type)/flows
  # Returns only the flow items (key, label, icon, description) for a given template.
  def template_flows
    country = sanitize_template_key(params[:country]) || "DE"
    plan_type_value = params[:plan_type].to_i

    if Planitem::PLAN_TYPES.key(plan_type_value).blank?
      render json: { error: "Unknown plan_type." }, status: :bad_request and return
    end

    flows = SimTemplate.new.list_flows(country, plan_type_value)
    if flows
      render json: { country: country, plan_type: plan_type_value, flows: flows }
    else
      render json: { error: "Template not found." }, status: :not_found
    end
  end

  # GET /v1/simulation/templates/(:country)/(:plan_type)
  # :plan_type is the numeric enum value (e.g. 1 for ausbildung)
  def template_show
    country = sanitize_template_key(params[:country]) || "DE"
    plan_type_value = params[:plan_type].to_i

    if Planitem::PLAN_TYPES.key(plan_type_value).blank?
      render json: { error: "Unknown plan_type." }, status: :bad_request and return
    end

    template = SimTemplate.new.get_template(country, plan_type_value)
    if template
      render json: template
    else
      render json: { error: "Template not found." }, status: :not_found
    end
  end

  private

  # Only allow alphanumeric characters and underscores to prevent path traversal.
  def sanitize_template_key(value)
    return nil if value.nil?
    value.gsub(/[^a-zA-Z0-9_]/, "")
  end
end