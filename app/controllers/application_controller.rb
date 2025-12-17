class ApplicationController < ActionController::Base
  include Authentication

  # AccessControl centralises capability gates (verified email, active account, etc.)
  # so marketplace rules remain consistent across controllers.
  include AccessControl

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
