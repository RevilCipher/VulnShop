Rails.application.routes.draw do
  root "home#index"

  # === Auth ===
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  get    "logout", to: "sessions#destroy"
  delete "logout", to: "sessions#destroy"

  # === Users (IDOR) ===
  get "profile",     to: "users#me",  as: :my_profile
  get "profile/:id", to: "users#show", as: :profile
  get "users",       to: "users#index"

  # === Products (SQLi Search + XSS Komentar) ===
  resources :products, only: [:index, :show]
  post   "products/:product_id/comments", to: "comments#create", as: :product_comments
  delete "comments/:id",                  to: "comments#destroy", as: :comment

  # === Orders (Price Manipulation + Negative Qty) ===
  post "orders", to: "orders#create"
  get  "orders", to: "orders#index"

  # === Upload (Unrestricted File Upload) ===
  get  "upload", to: "uploads#index"
  post "upload", to: "uploads#create"

  # === Security Level ===
  get  "security", to: "security#index"
  post "security", to: "security#update"

  # === HTML Injection ===
  get  "guestbook", to: "guestbook#index"
  post "guestbook", to: "guestbook#create"

  # === CSRF ===
  get  "csrf-lab",          to: "csrf#index"
  post "csrf-lab/transfer", to: "csrf#transfer"

  # === LFI ===
  get "pages", to: "pages#show"

  # === RFI ===
  get "fetch", to: "fetch#index"

  # === Command Injection ===
  get  "ping", to: "ping#index"
  post "ping", to: "ping#run"

  # === Open Redirect ===
  get "redirect", to: "redirect#go"

  # === XXE ===
  get  "xml", to: "xml#index"
  post "xml", to: "xml#parse"
  get "/pages", to: "pages#index"
  get "/pages/:page", to: "pages#show", as: :page
end
