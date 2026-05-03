class SimTemplate 
  include ActiveModel::Model
  TEMPLATE_DIR = Rails.root.join("jsonlib")
  TEMPLATE_SUFFIX = ".flow.json"

  # This model class is a helper for jsonlib files that are templates. It should follow a similar logic like the calchscheme.rb.
  def get_template(country, plan_type)
    file_path = TEMPLATE_DIR.join("#{country}_#{plan_type}#{TEMPLATE_SUFFIX}")
    if File.exist?(file_path)
      JSON.parse(File.read(file_path))
    else
      nil
    end
  end
  def create_checklist(country, plan_type, case_id, planitem_id)
    template = get_template(country, plan_type)
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
