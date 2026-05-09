class SimTemplate 
  include ActiveModel::Model
  TEMPLATE_DIR = Rails.root.join("jsonlib")
  TEMPLATE_SUFFIX = ".flow.json"

  # This model class is a helper for jsonlib files that are templates. It should follow a similar logic like the calchscheme.rb.
  def list_templates(country, plan_type_filter = nil)
    files = Dir[TEMPLATE_DIR.join("#{country}_*#{TEMPLATE_SUFFIX}")].sort
    files = files.select { |f| File.basename(f).start_with?("#{country}_#{plan_type_filter}") } if plan_type_filter.present?

    files.map do |file|
      basename = File.basename(file, TEMPLATE_SUFFIX).delete_prefix("#{country}_")
      match = basename.match(/^(\d+)_(.+)$/)
      {
        name: File.basename(file, TEMPLATE_SUFFIX),
        plan_type: match ? match[1].to_i : basename,
        plan_type_key: match ? match[2] : basename,
        country: country
      }
    end
  end

  # plan_type_value: integer enum value (e.g. 1)
  # Resolves the key from Planitem enum and builds the correct filename: {country}_{value}_{key}.flow.json
  def get_template(country, plan_type_value)
    plan_type_key = Planitem.plan_types.key(plan_type_value.to_i)
    return nil if plan_type_key.blank?

    file_path = TEMPLATE_DIR.join("#{country}_#{plan_type_value}_#{plan_type_key}#{TEMPLATE_SUFFIX}")
    if File.exist?(file_path)
      JSON.parse(File.read(file_path))
    else
      nil
    end
  end

  def create_checklist(country, plan_type_value, case_id, planitem_id)
    template = get_template(country, plan_type_value)
    return nil unless template

    flow      = template["flow"]
    flow_ref  = flow["id"]
    items     = flow["items"] || {}

    items.each_value do |item|
      next unless item.is_a?(Hash) && item["checklist_entry"].present?

      Checklist.create!(
        case_id:     case_id,
        planitem_id: planitem_id,
        text:        item["checklist_entry"],
        flow_ref:    flow_ref,
        status:      1
      )
    end
  end
end
