Rails.application.routes.draw do
  unless Rails.env.production?
    resources :locales do
      resources :translations
    end
    match '/translations' => 'translations#translations', :as => 'translations'
    match '/asset_translations' => 'translations#asset_translations', :as => 'asset_translations'
  end
end
