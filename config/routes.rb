Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :v1 do
    #resources :accounts, only: [:index, :show, :create, :update]
    #namespace :calcs do
    #  match 'discount', via: :get
    #  match 'tv_model', via: :get
    #  match 'tv_get' , via: :post
    #end
    namespace :public do
      #match 'discount', via: :get
      #match 'tv_model', via: :get
      match 'timemorph' , via: :post
      match 'timeslice_get' , via: :post
      match 'timeslice_series' , via: :post
      match 'valueflow_complete', via: :post
    end
  end
  
end
