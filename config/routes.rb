LantanBAM::Application.routes.draw do
  resources :sales do
    collection do
      post :delete_sale,:public_sale
    end
  end
  resources :package_cards do
    member do
      post :delete_pcard
    end
  end
  resources :products do
    collection do

    end
    member do
      post "show_prod","show_serv"
    end
  end
  resources :stations
  # The priority is based upon order of creation:
  # first created -> highest priority.
  root :to => 'logins#index'
  resources :logins
  resources :stores do
    resources :sales do 
      collection do
        post "load_types"
      end
      member do
        post "update_sale"
      end
    end
    resources :package_cards do
      collection do
        post "pcard_types","add_pcard"
        get "sale_records"
      end
      member do
        post "edit_pcard","update_pcard"
      end
    end
    resources :products do
      collection do
        post "edit_prod","add_prod","add_serv","serv_create","load_material"
        get "prod_services"
      end
      member do
        post "edit_prod","update_prod","serv_update","edit_serv"
      end
    end
    resources :materials do
      collection do
        get "out","search","order"
        post "out_order","material_order","add"
      end
    end

    resources :staffs
    resources :violation_rewards
    resources :trains

    resources :suppliers do
      member do
        post "change"
      end
    end
    resources :welcomes
    resources :customers do
      collection do
        post "search", "customer_mark", "single_send_message"
        get "search_list"
      end
    end
    resources :revisits do
      collection do
        post "search"
        get "search_list"
      end
    end
    resources :messages do
      collection do
        post "search"
        get "search_list"
      end
    end
  end

  resources :materials do
    member do
      get "remark","check"
    end
    collection do
      get "get_act_count", "out"
    end
  end

end
