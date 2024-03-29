Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # Rswag engine
  # out of date: mount Rswag::Ui::Engine => '/api-docs'
  get "/documentation" => redirect("https://documenter.getpostman.com/view/2458761/2s9Y5cuLP2")
  namespace :v1 do
    # If this deviating route is in namespace, then
    get 'public/timeslice', to: 'public#get_timeslice', format: :json
    get 'public/summary_report', to: 'public#get_envelope', format: :json
    namespace :public do
      # This namespace ignores the "to" element and looks for target within the controller with the exact name, therefore deviating functions are called above.
      match 'summary_report', to: 'summary_report', via: :post
      match 'timeslice' , via: :post
      match 'lastingmoney', via: :get
      #match 'timemorph' , via: :post
      #match 'timeslice_sample2', via: :get
      #match 'timeslice_get' , via: :post
      #match 'timeslice_series' , via: :post
      #match 'valueflow_complete', via: :post
      #match 'summary_report', via: :post
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
    
    # Manage APIKeys
    #post '/persist/api-keys', to: 'api_keys#create'
    #delete '/persist/api-keys', to: 'api_keys#destroy'
    #get '/persist/api-keys', to: 'api_keys#index'
    resources :api_keys, path: '/persist/api-keys', only: %i[index create destroy]
    namespace :beta, defaults: { format: :json }  do
      #match 'timeslice', to: 'public#get_timeslice', via: :get
    end

  end
  
end
