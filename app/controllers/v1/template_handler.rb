module V1::TemplateHandler
  # This is for simulations to manage the flow and provision of templates, that are stored in jsonlib.
  # Basically, there is a template for each planitem and a generic one. All is country based.

  TEMPLATE_DIR = Rails.root.join("jsonlib")
  TEMPLATE_SUFFIX = ".flow.json"

  # Response to GET /v1/simulation/case/:case_id/templates/planitems
  def template_planitems
    all_plan_types = Planitem.plan_types.map do |key, value|
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

  # GET /v1/simulation/case/:case_id/templates
  # Optional param: plan_type – filters results to a specific plan type
  def template_index
    country = @case.country || "OL"
    plan_type_filter = sanitize_template_key(params[:plan_type])

    files = Dir[TEMPLATE_DIR.join("#{country}_*#{TEMPLATE_SUFFIX}")].sort
    files = files.select { |f| File.basename(f).start_with?("#{country}_#{plan_type_filter}") } if plan_type_filter.present?

    templates = files.map do |file|
      plan_type_key = File.basename(file, TEMPLATE_SUFFIX).delete_prefix("#{country}_")
      {
        name: File.basename(file, TEMPLATE_SUFFIX),
        plan_type: plan_type_key,
        country: country
      }
    end

    render json: { case_id: params[:case_id], country: country, templates: templates }
  end

  # GET /v1/simulation/case/:case_id/templates/:plan_type
  def template_show
    country = @case.country || "OL"
    plan_type = sanitize_template_key(params[:plan_type])

    if plan_type.blank?
      render json: { error: "Invalid plan_type." }, status: :bad_request and return
    end

    file_path = TEMPLATE_DIR.join("#{country}_#{plan_type}#{TEMPLATE_SUFFIX}")

    if File.exist?(file_path)
      render json: JSON.parse(File.read(file_path))
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