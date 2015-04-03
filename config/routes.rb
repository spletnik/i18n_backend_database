Rails.application.routes.draw do
  unless Rails.env.production?
    resources :locales do
      resources :translations
    end
    resources :translations
    resources :asset_translations
    #get '/translations' => 'translations#translations', :as => 'translations'
    #get '/asset_translations' => 'translations#asset_translations', :as => 'asset_translations'
  end
end
