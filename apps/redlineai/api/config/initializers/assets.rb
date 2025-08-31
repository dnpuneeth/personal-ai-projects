# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w(
  application.js
  application.css
  tailwind.css
  theme_toggle.js
  profile_picture.js
)

# Enable the asset pipeline
Rails.application.config.assets.enabled = true

# Add the app/assets folder to the asset load path
Rails.application.config.assets.paths << Rails.root.join("app", "assets")
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "builds")
