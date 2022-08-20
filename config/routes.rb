Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # Rswag engine
  mount Rswag::Ui::Engine => '/api-docs'
  namespace :v1 do
    # If this deviating route is in namespace, then
    get 'public/timeslice', to: 'public#get_timeslice', format: :json
    get 'public/summary_report', to: 'public#get_envelope', format: :json
    namespace :scheme do
      match 'listschemes', via: :get
    end
    namespace :public do
      # This namespace ignores the "to" element and looks for target within the controller with the exact name, therefore deviating functions are called above.
      match 'summary_report', to: 'summary_report', via: :post
      match 'timeslice' , via: :post
      #match 'timemorph' , via: :post
      #match 'timeslice_sample2', via: :get
      #match 'timeslice_get' , via: :post
      #match 'timeslice_series' , via: :post
      #match 'valueflow_complete', via: :post
      #match 'summary_report', via: :post
    end
    namespace :beta, defaults: { format: :json }  do
      #match 'timeslice', to: 'public#get_timeslice', via: :get
    end

  end
  
end
