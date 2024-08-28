Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # Rswag engine
  # out of date: mount Rswag::Ui::Engine => '/api-docs'
  get "/documentation" => redirect("https://documenter.getpostman.com/view/2458761/2s9Y5cuLP2")
  namespace :v1, :defaults => { :format => 'json' } do
    # If this deviating route is in namespace, then
    get 'public/timeslice', to: 'public#get_timeslice' #, format: :json
    get 'public/summary_report', to: 'public#get_envelope' #, format: :json
    namespace :public do
      # This namespace ignores the "to" element and looks for target within the controller with the exact name, therefore deviating functions are called above.
      match 'summary_report', via: :post
      match 'timeslice' , via: :post
      match 'lastingmoney', via: :get
    end
    
    # CalcSchemes
    match 'cs/(:countrycode)/listschemes', to: 'cs#listschemes', via: :get
    match 'cs/(:countrycode)/listmeta', to: 'cs#listmeta', via: :get
    match 'cs/(:countrycode)/meta/(:metaschemetype)', to: 'cs#get_metaschemetype', via: :get
    match 'cs/(:countrycode)/meta/(:metaschemetype)/(:metascheme)/(:version)', to: 'cs#get_metascheme', via: :get
    match 'cs/(:countrycode)/meta/(:metaschemetype)/(:metascheme)/(:version)', to: 'cs#run_metascheme', via: :post
    match 'cs/(:countrycode)/(:schemetype)', to: 'cs#get_schemetype', via: :get
    match 'cs/(:countrycode)/(:schemetype)/(:scheme)/(:version)', to: 'cs#run_scheme', via: :post
	
	  # Temporary: CalcSchemes Admin
	  match 'csadmin/(:countrycode)/(:schemetype)', to: 'csadmin#get_schemetype', via: :get

    # Pension Calculator
    namespace :pension do
        get 'sample', action: 'sample_input'
        post '(:ptype)/payout', action: 'route_payout'
    end

    # Simulation
    namespace :simulation do
        # Case Management
        post 'case', action: "case_create"
        get 'case/(:case_id)', action: "case_show"
        patch 'case/(:case_id)', action: "case_update"
        delete 'case/(:case_id)', action: "case_destroy"
        get 'case/(:case_id)/entries', action: "case_entries"
        post 'case/(:case_id)/entry', action: "entry_create"
        get 'case/(:case_id)/cslice/(:cslice_id)', action: "cslice_show"
        delete 'case/(:case_id)/cvalue/(:cvalue_id)', action: "cvalue_destroy"
        delete 'case/(:case_id)/cslice/(:cslice_id)', action: "cslice_destroy"
        #match 'case/(:id)', to: :case_update, via: :post
        #match 'case/(:id)', to: :case_destroy, via: :delete
        # Assumptions (CValues, CSlices, CFlows, CPensionFlows)
        # Simulation Results and details
        get 'case/(:case_id)/simulate', action: "simulate"
        get 'case/(:case_id)/simulate_detail', action: "simulate_detail"
        #match 'case/(:id)/simulate', to: :simulate, via: :get
        #match 'case/(:id)/simulate_cashbalance', to: :simulate_cashbalance, via: :get
    end

    # Manage APIKeys
    # Currently there is no need to manage API-Keys, the function is deactivated.
    #post '/persist/api-keys', to: 'api_keys#create'
    #delete '/persist/api-keys', to: 'api_keys#destroy'
    #get '/persist/api-keys', to: 'api_keys#index'
    
    #resources :api_keys, path: '/persist/api-keys', only: %i[index create destroy]
    
    #namespace :beta, defaults: { format: :json }  do
      #match 'timeslice', to: 'public#get_timeslice', via: :get
    #end
  end
end
