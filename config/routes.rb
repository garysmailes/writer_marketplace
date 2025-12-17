Rails.application.routes.draw do
  # -------------------------------------------------
  # Health check
  # -------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check

  # -------------------------------------------------
  # Authentication (Rails 8 built-in)
  # -------------------------------------------------
  # Sessions:
  # - sign in
  # - sign out
  resource :session

  # Password reset (token-based)
  resources :passwords, param: :token

  # -------------------------------------------------
  # Registration (sign-up)
  # -------------------------------------------------
  # Accounts are created immediately and sessions start immediately.
  # Email verification is required to unlock active marketplace actions.
  get  "/sign_up", to: "registrations#new"
  post "/sign_up", to: "registrations#create"

  # -------------------------------------------------
  # Email verification
  # -------------------------------------------------
  # One-time token sent via email.
  get  "/verify_email/:token", to: "email_verifications#show", as: :verify_email
  post "/email_verification/resend", to: "email_verifications#create", as: :resend_email_verification

  # -------------------------------------------------
  # Account lifecycle (namespaced)
  # -------------------------------------------------
  # Signed-in account area.
  # Some pages require verification, some explicitly allow unverified users.
  namespace :account do
    # Verified-only account home
    get  "/",          to: "overview#show",       as: :overview

    # Self-serve deactivation (immediate + logout)
    post "/deactivate", to: "deactivations#create", as: :deactivate
  end

  # Activation page (signed in, may be unverified)
  # Kept as /activate for clarity and UX
  get "/activate", to: "account/activations#show"

  # -----------------
  # Account reactivation (signed-out)
  # -----------------
  # Deactivated users cannot sign in, but can request reactivation by email.
  get  "/reactivate",        to: "account/reactivations#new",    as: :reactivate_account
  post "/reactivate",        to: "account/reactivations#create", as: :request_reactivation
  get  "/reactivate/:token", to: "account/reactivations#show",   as: :reactivate_token


  # -------------------------------------------------
  # Development-only email inbox
  # -------------------------------------------------
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # -------------------------------------------------
  # Root
  # -------------------------------------------------
  root "pages#home"
end
