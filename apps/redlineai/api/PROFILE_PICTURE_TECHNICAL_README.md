# Profile Picture Upload System - Technical Documentation

## Overview

The profile picture upload system in RedlineAI provides a comprehensive solution for user profile image management, including file uploads, image processing, storage, and display. The system integrates with Rails Active Storage and provides both programmatic and user interface capabilities.

## Architecture

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend UI   │    │  Rails Backend   │    │ Active Storage  │
│                 │    │                  │    │                 │
│ • File Input    │───▶│ • User Model     │───▶│ • Local Disk    │
│ • Drag & Drop   │    │ • Controller     │    │ • S3 Compatible │
│ • Preview       │    │ • Validations    │    │ • Variants      │
│ • Modal View    │    │ • Routes         │    │ • Processing    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Technology Stack

- **Backend**: Ruby on Rails 8.0
- **File Storage**: Active Storage with local disk storage
- **Image Processing**: VIPS library via `image_processing` gem
- **Frontend**: HTML/ERB templates with Tailwind CSS
- **JavaScript**: Vanilla JS for interactivity and modals
- **Database**: PostgreSQL with Active Storage tables

## Implementation Details

### 1. Database Schema

#### Active Storage Tables

```sql
-- Automatically created by Active Storage
CREATE TABLE active_storage_attachments (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  record_type VARCHAR NOT NULL,
  record_id BIGINT NOT NULL,
  blob_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE active_storage_blobs (
  id BIGSERIAL PRIMARY KEY,
  key VARCHAR NOT NULL UNIQUE,
  filename VARCHAR NOT NULL,
  content_type VARCHAR,
  metadata TEXT,
  byte_size BIGINT NOT NULL,
  checksum VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE active_storage_variant_records (
  id BIGSERIAL PRIMARY KEY,
  blob_id BIGINT NOT NULL,
  variation_digest VARCHAR NOT NULL
);
```

#### User Model Integration

```ruby
class User < ApplicationRecord
  # Active Storage association
  has_one_attached :profile_picture

  # Custom validation
  validate :acceptable_profile_picture

  private

  def acceptable_profile_picture
    return unless profile_picture.attached?

    # File type validation
    unless profile_picture.content_type.in?(%w[image/png image/jpeg image/jpg image/gif])
      errors.add(:profile_picture, 'must be a valid image format (PNG, JPEG, JPG, or GIF)')
    end

    # File size validation (5MB limit)
    unless profile_picture.byte_size <= 5.megabytes
      errors.add(:profile_picture, 'must be less than 5MB')
    end
  end
end
```

### 2. Controller Implementation

#### Profiles Controller

```ruby
class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update]

  def update
    if @user.update(user_params)
      if user_params[:profile_picture].present?
        redirect_to profile_path, notice: 'Profile and picture updated successfully.'
      else
        redirect_to profile_path, notice: 'Profile updated successfully.'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Profile update error: #{e.message}"
    @user.errors.add(:base, "An error occurred while updating your profile. Please try again.")
    render :edit, status: :unprocessable_entity
  end

  def remove_profile_picture
    @user = current_user
    if @user.profile_picture.attached?
      begin
        @user.profile_picture.purge
        redirect_to edit_profile_path, notice: 'Profile picture removed successfully.'
      rescue => e
        Rails.logger.error "Profile picture removal error: #{e.message}"
        redirect_to edit_profile_path, alert: 'Failed to remove profile picture. Please try again.'
      end
    else
      redirect_to edit_profile_path, alert: 'No profile picture to remove.'
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :profile_picture)
  end
end
```

### 3. Routes Configuration

```ruby
Rails.application.routes.draw do
  # Profile management routes
  get '/profile', to: 'profiles#show'
  get '/profile/edit', to: 'profiles#edit'
  patch '/profile', to: 'profiles#update'
  put '/profile', to: 'profiles#update'
  delete '/profile/picture', to: 'profiles#remove_profile_picture', as: :remove_profile_picture
end
```

### 4. Model Methods

#### Profile Picture Helper Methods

```ruby
class User < ApplicationRecord
  # Get the best available profile picture URL
  def profile_picture_url
    if profile_picture.attached?
      profile_picture
    elsif avatar_url.present?
      avatar_url
    else
      nil
    end
  end

  # Check if user has any profile picture
  def has_profile_picture?
    profile_picture.attached? || avatar_url.present?
  end

  # Generate thumbnail variant
  def profile_picture_thumbnail
    if profile_picture.attached?
      profile_picture.variant(resize_to_fill: [100, 100]).processed
    else
      nil
    end
  end
end
```

### 5. Frontend Implementation

#### File Upload Form

```erb
<%= form_with model: @user, url: profile_path, method: :patch,
    html: { class: "space-y-8", multipart: true } do |f| %>

  <!-- File Input -->
  <input type="file"
         id="user_profile_picture"
         name="user[profile_picture]"
         accept="image/*"
         class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-blue-50 file:text-blue-700">

  <!-- Upload Button -->
  <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded-md">
    Upload
  </button>
<% end %>
```

#### Profile Picture Display

```erb
<% if @user.has_profile_picture? %>
  <div class="relative group">
    <% if @user.profile_picture.attached? %>
      <%= image_tag @user.profile_picture_thumbnail,
          class: "h-24 w-24 rounded-full object-cover cursor-pointer hover:scale-105",
          alt: @user.display_name,
          onclick: "openProfilePictureModal('#{url_for(@user.profile_picture)}', '#{@user.display_name}')" %>
    <% else %>
      <img class="h-24 w-24 rounded-full object-cover cursor-pointer hover:scale-105"
           src="<%= @user.avatar_url %>"
           alt="<%= @user.display_name %>"
           onclick: "openProfilePictureModal('#{@user.avatar_url}', '#{@user.display_name}')" %>
    <% end %>
  </div>
<% end %>
```

### 6. JavaScript Functionality

#### Modal Management

```javascript
// Open profile picture modal
function openProfilePictureModal(imageSrc, userName) {
  const modal = document.getElementById("profile-picture-modal");
  const modalImage = document.getElementById("modal-image");
  const modalTitle = document.getElementById("modal-title");

  if (modal && modalImage && modalTitle) {
    modalImage.src = imageSrc;
    modalImage.alt = `${userName}'s profile picture`;
    modalTitle.textContent = `${userName}'s Profile Picture`;
    modal.classList.remove("hidden");

    // Event listeners for closing
    modal.addEventListener("click", function (e) {
      if (e.target === modal) closeProfilePictureModal();
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeProfilePictureModal();
    });
  }
}

// Remove profile picture confirmation
function confirmRemoveProfilePicture() {
  const dialog = document.createElement("div");
  dialog.className =
    "fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center p-4";
  dialog.innerHTML = `
    <div class="bg-white rounded-lg max-w-md w-full p-6">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Remove Profile Picture</h3>
      <p class="text-sm text-gray-600 mb-6">Are you sure you want to remove your profile picture?</p>
      <div class="flex justify-end space-x-3">
        <button onclick="this.closest('.fixed').remove()" class="px-4 py-2 text-gray-700 bg-white border rounded-md">Cancel</button>
        <button onclick="removeProfilePicture()" class="px-4 py-2 text-white bg-red-600 rounded-md">Remove Picture</button>
      </div>
    </div>
  `;

  document.body.appendChild(dialog);
}
```

### 7. Image Processing

#### Active Storage Configuration

```ruby
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

# config/environments/development.rb
config.active_storage.service = :local
```

#### Variant Generation

```ruby
# Generate 100x100 thumbnail
profile_picture.variant(resize_to_fill: [100, 100]).processed

# Available transformation options
profile_picture.variant(
  resize_to_fill: [100, 100],     # Crop to exact dimensions
  resize_to_fit: [100, 100],      # Fit within dimensions
  resize_to_limit: [100, 100],    # Limit maximum dimensions
  format: :webp,                   # Convert format
  quality: 80                      # JPEG quality
).processed
```

### 8. Security Features

#### File Validation

- **Content Type**: Only PNG, JPEG, JPG, GIF allowed
- **File Size**: Maximum 5MB limit
- **File Sanitization**: Active Storage handles file security
- **CSRF Protection**: Rails built-in CSRF tokens

#### Access Control

```ruby
class ProfilesController < ApplicationController
  before_action :authenticate_user!  # Devise authentication
  before_action :set_user, only: [:show, :edit, :update]

  private

  def set_user
    @user = current_user  # Users can only access their own profile
  end
end
```

### 9. Error Handling

#### Validation Errors

```erb
<% if @user.errors[:profile_picture].any? %>
  <div class="text-sm text-red-600">
    <% @user.errors[:profile_picture].each do |error| %>
      <p><%= error %></p>
    <% end %>
  </div>
<% end %>
```

#### Controller Error Handling

```ruby
def update
  if @user.update(user_params)
    # Success handling
  else
    render :edit, status: :unprocessable_entity
  end
rescue => e
  Rails.logger.error "Profile update error: #{e.message}"
  @user.errors.add(:base, "An error occurred while updating your profile.")
  render :edit, status: :unprocessable_entity
end
```

### 10. Performance Considerations

#### Lazy Loading

- Profile pictures are loaded only when needed
- Thumbnails are generated on-demand
- Full-size images are loaded only in modal view

#### Caching

- Active Storage variants are cached after first generation
- Database queries are optimized with proper indexing
- View caching for profile display pages

#### Image Optimization

- Automatic thumbnail generation for different use cases
- Format conversion for better compression
- Quality settings for optimal file size

## File Structure

```
app/
├── controllers/
│   └── profiles_controller.rb          # Profile management logic
├── models/
│   └── user.rb                         # User model with profile picture methods
├── views/
│   ├── profiles/
│   │   ├── edit.html.erb              # Profile editing with upload
│   │   └── show.html.erb              # Profile display
│   └── layouts/
│       └── application.html.erb       # Global modal and navigation
├── javascript/
│   └── profile_picture.js             # Frontend interactivity
└── assets/
    └── stylesheets/
        └── application.css             # Profile picture styles

config/
├── routes.rb                           # Profile routes
└── storage.yml                         # Active Storage configuration

db/
└── schema.rb                           # Database schema including Active Storage tables
```

## Dependencies

### Gems

```ruby
# Gemfile
gem "image_processing", "~> 1.2"      # Image processing capabilities
gem "devise", "~> 4.9"                # User authentication
gem "tailwindcss-rails", "~> 2.0"     # CSS framework
```

### System Requirements

- **VIPS Library**: Required for image processing (`brew install vips` on macOS)
- **PostgreSQL**: Database with Active Storage support
- **Redis**: Optional for background job processing

## Testing

### Model Tests

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'profile picture' do
    it 'validates file type' do
      user = build(:user)
      user.profile_picture.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'test.txt')),
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      expect(user).not_to be_valid
      expect(user.errors[:profile_picture]).to include('must be a valid image format')
    end

    it 'validates file size' do
      user = build(:user)
      user.profile_picture.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'large_image.jpg')),
        filename: 'large_image.jpg',
        content_type: 'image/jpeg'
      )
      expect(user).not_to be_valid
      expect(user.errors[:profile_picture]).to include('must be less than 5MB')
    end
  end
end
```

### Controller Tests

```ruby
# spec/controllers/profiles_controller_spec.rb
RSpec.describe ProfilesController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'PUT #update' do
    it 'updates profile picture' do
      file = fixture_file_upload('test_image.jpg', 'image/jpeg')
      put :update, params: { user: { profile_picture: file } }
      expect(user.reload.profile_picture).to be_attached
    end
  end
end
```

## Deployment Considerations

### Environment Variables

```bash
# Production environment
RAILS_ENV=production
DATABASE_URL=postgresql://user:pass@host:port/dbname
ACTIVE_STORAGE_SERVICE=amazon  # or other cloud storage
```

### Storage Configuration

```ruby
# config/environments/production.rb
config.active_storage.service = :amazon
config.active_storage.variant_processor = :vips
```

### Performance Monitoring

- Monitor Active Storage variant generation times
- Track file upload success/failure rates
- Monitor storage usage and costs
- Set up alerts for storage quota limits

## Troubleshooting

### Common Issues

1. **VIPS Library Missing**

   ```bash
   # Error: Could not open library 'vips.42'
   brew install vips  # macOS
   apt-get install libvips-dev  # Ubuntu
   ```

2. **File Upload Failing**

   - Check multipart form attribute
   - Verify file size limits
   - Check content type validation

3. **Thumbnails Not Generating**

   - Ensure VIPS library is installed
   - Check Active Storage configuration
   - Verify image processing gem is included

4. **Modal Not Working**
   - Check JavaScript console for errors
   - Verify modal HTML is present in DOM
   - Check z-index conflicts

### Debug Commands

```ruby
# Rails console debugging
user = User.first
user.profile_picture.attached?                    # Check attachment status
user.profile_picture.content_type                 # Check file type
user.profile_picture.byte_size                    # Check file size
user.profile_picture_thumbnail                    # Test thumbnail generation
```

## Future Enhancements

### Planned Features

- **Multiple Image Support**: Allow multiple profile pictures
- **Image Cropping**: Client-side image cropping before upload
- **Background Processing**: Move image processing to background jobs
- **CDN Integration**: Serve images through CDN for better performance
- **Advanced Filters**: Apply filters and effects to profile pictures

### Scalability Considerations

- **Cloud Storage**: Migrate to S3 or similar for production
- **Image Optimization**: Implement WebP conversion and compression
- **Caching Strategy**: Implement Redis-based image caching
- **Load Balancing**: Distribute image processing across multiple servers

---

_This documentation covers the complete technical implementation of the profile picture upload system in RedlineAI. For additional support or questions, refer to the main README or create an issue in the repository._
