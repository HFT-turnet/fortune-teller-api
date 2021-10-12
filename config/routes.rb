Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :v1 do
    #resources :accounts, only: [:index, :show, :create, :update]
    #namespace :calcs do
    #  match 'discount', via: :get
    #  match 'tv_model', via: :get
    #  match 'tv_get' , via: :post
    #end
    namespace :public, defaults: { format: :json }  do
      #match 'discount', via: :get
      #match 'tv_model', via: :get
      match 'get_envelope', via: :get
      match 'get_expenses', via: :get
      match 'get_incomes', via: :get
      match 'timemorph' , via: :post
      match 'timeslice_sample', via: :get
      match 'timeslice_sample2', via: :get
      match 'timeslice_get' , via: :post
      match 'timeslice_series' , via: :post
      match 'valueflow_complete', via: :post
      match 'summary_report', via: :post
    end
  end
  
end
