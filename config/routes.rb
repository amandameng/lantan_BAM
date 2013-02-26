LantanBAM::Application.routes.draw do
  resources :sales
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
    end
    resources :materials do
      collection do
        get "out","search","order","page_materials","search_head_orders","search_supplier_orders","alipay",
            "print","cuihuo","cancel_order","page_outs","page_ins","page_head_orders","page_supplier_orders","search_supplier_orders"
        post "out_order","material_order","add","alipay_complete"
      end
    end

    resources :staffs
    resources :violation_rewards
    resources :trains

    resources :suppliers do
      member do
        post "change"
      end
      collection do
        get "page_suppliers"
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
      get "get_act_count", "out","order_remark"
    end
  end

end
