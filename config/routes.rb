Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :v1 do
    # If this deviating route is in namespace, then
    get 'public/timeslice', to: 'public#get_timeslice', format: :json
    get 'public/summary_report', to: 'public#get_envelope', format: :json
    namespace :public, defaults: { format: :json }  do
      post 'summary_report', to: 'summary_report'
      #match 'timemorph' , via: :post
      #match 'timeslice_sample2', via: :get
      #match 'timeslice_get' , via: :post
      #match 'timeslice_series' , via: :post
      #match 'valueflow_complete', via: :post
      #match 'summary_report', via: :post
    end
  end
  
end
