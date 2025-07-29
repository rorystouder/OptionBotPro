# Views Setup (Optional)

This guide helps you create basic web views for the TastyTrades UI application. This is optional if you're only using the API.

## Step 1: Create Application Layout

Create the main application layout:

```bash
mkdir -p app/views/layouts
```

Create `app/views/layouts/application.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>TastyTrades UI</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
    
    <!-- Bootstrap CSS for styling -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
  </head>

  <body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
      <div class="container">
        <%= link_to "TastyTrades UI", root_path, class: "navbar-brand" %>
        
        <div class="navbar-nav ms-auto">
          <% if logged_in? %>
            <%= link_to "Dashboard", dashboard_path, class: "nav-link" %>
            <%= link_to "Profile", user_path, class: "nav-link" %>
            <%= link_to "Logout", logout_path, method: :delete, class: "nav-link" %>
          <% else %>
            <%= link_to "Login", login_path, class: "nav-link" %>
            <%= link_to "Sign Up", signup_path, class: "nav-link" %>
          <% end %>
        </div>
      </div>
    </nav>

    <main class="container mt-4">
      <% if notice %>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
          <%= notice %>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      <% end %>

      <% if alert %>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
          <%= alert %>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      <% end %>

      <%= yield %>
    </main>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
```

## Step 2: Create Authentication Views

### Login View

Create `app/views/sessions/new.html.erb`:

```erb
<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card">
      <div class="card-header">
        <h3 class="mb-0">Login</h3>
      </div>
      <div class="card-body">
        <%= form_with url: login_path, local: true, class: "needs-validation", novalidate: true do |form| %>
          <div class="mb-3">
            <%= form.label :email, class: "form-label" %>
            <%= form.email_field :email, class: "form-control", required: true %>
            <div class="invalid-feedback">
              Please provide a valid email.
            </div>
          </div>

          <div class="mb-3">
            <%= form.label :password, class: "form-label" %>
            <%= form.password_field :password, class: "form-control", required: true %>
            <div class="invalid-feedback">
              Please provide a password.
            </div>
          </div>

          <hr>
          <h5>TastyTrade Authentication (Optional)</h5>
          <p class="text-muted small">Connect to your TastyTrade account for live trading</p>

          <div class="mb-3">
            <%= form.label :tastytrade_username, "TastyTrade Username", class: "form-label" %>
            <%= form.text_field :tastytrade_username, class: "form-control" %>
          </div>

          <div class="mb-3">
            <%= form.label :tastytrade_password, "TastyTrade Password", class: "form-label" %>
            <%= form.password_field :tastytrade_password, class: "form-control" %>
          </div>

          <div class="d-grid">
            <%= form.submit "Login", class: "btn btn-primary" %>
          </div>
        <% end %>

        <div class="text-center mt-3">
          <%= link_to "Don't have an account? Sign up", signup_path %>
        </div>
      </div>
    </div>
  </div>
</div>
```

### Signup View

Create `app/views/users/new.html.erb`:

```erb
<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card">
      <div class="card-header">
        <h3 class="mb-0">Create Account</h3>
      </div>
      <div class="card-body">
        <%= form_with model: @user, url: signup_path, local: true, class: "needs-validation", novalidate: true do |form| %>
          <% if @user.errors.any? %>
            <div class="alert alert-danger">
              <h4><%= pluralize(@user.errors.count, "error") %> prohibited this account from being saved:</h4>
              <ul class="mb-0">
                <% @user.errors.full_messages.each do |message| %>
                  <li><%= message %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <%= form.label :first_name, class: "form-label" %>
                <%= form.text_field :first_name, class: "form-control", required: true %>
                <div class="invalid-feedback">
                  Please provide your first name.
                </div>
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <%= form.label :last_name, class: "form-label" %>
                <%= form.text_field :last_name, class: "form-control", required: true %>
                <div class="invalid-feedback">
                  Please provide your last name.
                </div>
              </div>
            </div>
          </div>

          <div class="mb-3">
            <%= form.label :email, class: "form-label" %>
            <%= form.email_field :email, class: "form-control", required: true %>
            <div class="invalid-feedback">
              Please provide a valid email.
            </div>
          </div>

          <div class="mb-3">
            <%= form.label :password, class: "form-label" %>
            <%= form.password_field :password, class: "form-control", required: true, minlength: 6 %>
            <div class="invalid-feedback">
              Password must be at least 6 characters.
            </div>
          </div>

          <div class="mb-3">
            <%= form.label :password_confirmation, class: "form-label" %>
            <%= form.password_field :password_confirmation, class: "form-control", required: true %>
            <div class="invalid-feedback">
              Passwords must match.
            </div>
          </div>

          <div class="mb-3">
            <%= form.label :tastytrade_customer_id, "TastyTrade Customer ID", class: "form-label" %>
            <%= form.text_field :tastytrade_customer_id, class: "form-control" %>
            <div class="form-text">Your TastyTrade customer ID (optional)</div>
          </div>

          <div class="d-grid">
            <%= form.submit "Create Account", class: "btn btn-success" %>
          </div>
        <% end %>

        <div class="text-center mt-3">
          <%= link_to "Already have an account? Login", login_path %>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Step 3: Create Dashboard View

Create `app/views/dashboard/index.html.erb`:

```erb
<div class="d-flex justify-content-between align-items-center mb-4">
  <h1>Trading Dashboard</h1>
  <div>
    <% if @tastytrade_authenticated %>
      <span class="badge bg-success">TastyTrade Connected</span>
    <% else %>
      <span class="badge bg-warning">TastyTrade Not Connected</span>
    <% end %>
  </div>
</div>

<!-- Portfolio Summary -->
<div class="row mb-4">
  <div class="col-md-3">
    <div class="card text-center">
      <div class="card-body">
        <h5 class="card-title">Total Positions</h5>
        <h3 class="text-primary"><%= @portfolio_summary[:total_positions] %></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card text-center">
      <div class="card-body">
        <h5 class="card-title">Market Value</h5>
        <h3 class="text-success">$<%= number_with_precision(@portfolio_summary[:total_market_value], precision: 2) %></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card text-center">
      <div class="card-body">
        <h5 class="card-title">Unrealized P&L</h5>
        <h3 class="<%= @portfolio_summary[:total_unrealized_pnl] >= 0 ? 'text-success' : 'text-danger' %>">
          $<%= number_with_precision(@portfolio_summary[:total_unrealized_pnl], precision: 2) %>
        </h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card text-center">
      <div class="card-body">
        <h5 class="card-title">Options/Stocks</h5>
        <h3 class="text-info"><%= @portfolio_summary[:options_count] %>/<%= @portfolio_summary[:stocks_count] %></h3>
      </div>
    </div>
  </div>
</div>

<!-- Recent Orders -->
<div class="row">
  <div class="col-md-6">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Recent Orders</h5>
      </div>
      <div class="card-body">
        <% if @recent_orders.any? %>
          <div class="table-responsive">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Symbol</th>
                  <th>Type</th>
                  <th>Qty</th>
                  <th>Price</th>
                  <th>Status</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                <% @recent_orders.each do |order| %>
                  <tr>
                    <td><%= order.symbol %></td>
                    <td><%= order.action %></td>
                    <td><%= order.quantity %></td>
                    <td>$<%= order.price || 'Market' %></td>
                    <td>
                      <span class="badge bg-<%= order.status == 'filled' ? 'success' : 'primary' %>">
                        <%= order.status.humanize %>
                      </span>
                    </td>
                    <td><%= order.created_at.strftime("%m/%d %H:%M") %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <p class="text-muted">No recent orders</p>
        <% end %>
      </div>
    </div>
  </div>

  <!-- Current Positions -->
  <div class="col-md-6">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Current Positions</h5>
      </div>
      <div class="card-body">
        <% if @positions.any? %>
          <div class="table-responsive">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Symbol</th>
                  <th>Qty</th>
                  <th>Avg Price</th>
                  <th>Current</th>
                  <th>P&L</th>
                </tr>
              </thead>
              <tbody>
                <% @positions.each do |position| %>
                  <tr>
                    <td><%= position.symbol %></td>
                    <td><%= position.quantity %></td>
                    <td>$<%= number_with_precision(position.average_price, precision: 2) %></td>
                    <td>$<%= number_with_precision(position.current_price || 0, precision: 2) %></td>
                    <td class="<%= (position.unrealized_pnl || 0) >= 0 ? 'text-success' : 'text-danger' %>">
                      $<%= number_with_precision(position.unrealized_pnl || 0, precision: 2) %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <p class="text-muted">No current positions</p>
        <% end %>
      </div>
    </div>
  </div>
</div>

<!-- Quick Actions -->
<div class="row mt-4">
  <div class="col-12">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Quick Actions</h5>
      </div>
      <div class="card-body">
        <div class="row">
          <div class="col-md-3">
            <button class="btn btn-primary w-100 mb-2" onclick="alert('Place Order - Use API endpoints')">
              Place Order
            </button>
          </div>
          <div class="col-md-3">
            <button class="btn btn-info w-100 mb-2" onclick="refreshPositions()">
              Refresh Positions
            </button>
          </div>
          <div class="col-md-3">
            <button class="btn btn-success w-100 mb-2" onclick="alert('Market Data - Use API endpoints')">
              Market Data
            </button>
          </div>
          <div class="col-md-3">
            <% unless @tastytrade_authenticated %>
              <button class="btn btn-warning w-100 mb-2" onclick="window.location.href='<%= login_path %>'">
                Connect TastyTrade
              </button>
            <% else %>
              <button class="btn btn-outline-success w-100 mb-2" disabled>
                TastyTrade Connected
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
function refreshPositions() {
  // This would call your API to refresh positions
  alert('Use API endpoint: GET /api/v1/positions?account_id=YOUR_ACCOUNT_ID');
}
</script>
```

## Step 4: Create User Profile Views

Create `app/views/users/show.html.erb`:

```erb
<div class="row">
  <div class="col-md-8">
    <div class="card">
      <div class="card-header">
        <h3 class="mb-0">Profile</h3>
      </div>
      <div class="card-body">
        <dl class="row">
          <dt class="col-sm-3">Name:</dt>
          <dd class="col-sm-9"><%= @user.full_name %></dd>

          <dt class="col-sm-3">Email:</dt>
          <dd class="col-sm-9"><%= @user.email %></dd>

          <dt class="col-sm-3">TastyTrade Customer ID:</dt>
          <dd class="col-sm-9"><%= @user.tastytrade_customer_id || "Not provided" %></dd>

          <dt class="col-sm-3">Status:</dt>
          <dd class="col-sm-9">
            <span class="badge bg-<%= @user.active? ? 'success' : 'secondary' %>">
              <%= @user.active? ? 'Active' : 'Inactive' %>
            </span>
          </dd>

          <dt class="col-sm-3">TastyTrade Connection:</dt>
          <dd class="col-sm-9">
            <span class="badge bg-<%= @user.tastytrade_authenticated? ? 'success' : 'warning' %>">
              <%= @user.tastytrade_authenticated? ? 'Connected' : 'Not Connected' %>
            </span>
          </dd>
        </dl>

        <div class="mt-4">
          <%= link_to "Edit Profile", edit_user_path, class: "btn btn-primary" %>
          <%= link_to "Back to Dashboard", dashboard_path, class: "btn btn-secondary" %>
        </div>
      </div>
    </div>
  </div>

  <div class="col-md-4">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Account Statistics</h5>
      </div>
      <div class="card-body">
        <dl class="row">
          <dt class="col-6">Total Orders:</dt>
          <dd class="col-6"><%= @user.orders.count %></dd>

          <dt class="col-6">Active Orders:</dt>
          <dd class="col-6"><%= @user.orders.active.count %></dd>

          <dt class="col-6">Total Positions:</dt>
          <dd class="col-6"><%= @user.positions.count %></dd>

          <dt class="col-6">Member Since:</dt>
          <dd class="col-6"><%= @user.created_at.strftime("%B %Y") %></dd>
        </dl>
      </div>
    </div>
  </div>
</div>
```

Create `app/views/users/edit.html.erb`:

```erb
<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card">
      <div class="card-header">
        <h3 class="mb-0">Edit Profile</h3>
      </div>
      <div class="card-body">
        <%= form_with model: @user, url: user_path, method: :patch, local: true, class: "needs-validation", novalidate: true do |form| %>
          <% if @user.errors.any? %>
            <div class="alert alert-danger">
              <h4><%= pluralize(@user.errors.count, "error") %> prohibited this profile from being saved:</h4>
              <ul class="mb-0">
                <% @user.errors.full_messages.each do |message| %>
                  <li><%= message %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <%= form.label :first_name, class: "form-label" %>
                <%= form.text_field :first_name, class: "form-control", required: true %>
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <%= form.label :last_name, class: "form-label" %>
                <%= form.text_field :last_name, class: "form-control", required: true %>
              </div>
            </div>
          </div>

          <div class="mb-3">
            <%= form.label :email, class: "form-label" %>
            <%= form.email_field :email, class: "form-control", required: true %>
          </div>

          <div class="mb-3">
            <%= form.label :tastytrade_customer_id, "TastyTrade Customer ID", class: "form-label" %>
            <%= form.text_field :tastytrade_customer_id, class: "form-control" %>
          </div>

          <hr>
          <h5>Change Password (optional)</h5>

          <div class="mb-3">
            <%= form.label :password, "New Password", class: "form-label" %>
            <%= form.password_field :password, class: "form-control", minlength: 6 %>
            <div class="form-text">Leave blank to keep current password</div>
          </div>

          <div class="mb-3">
            <%= form.label :password_confirmation, class: "form-label" %>
            <%= form.password_field :password_confirmation, class: "form-control" %>
          </div>

          <div class="d-grid gap-2 d-md-flex justify-content-md-end">
            <%= link_to "Cancel", user_path, class: "btn btn-secondary" %>
            <%= form.submit "Update Profile", class: "btn btn-primary" %>
          </div>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

## Step 5: Add Basic Styling

Create `app/assets/stylesheets/application.css`:

```css
/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS (and SCSS, if configured) file within this directory, lib/assets/stylesheets, or any plugin's
 * vendor/assets/stylesheets directory can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the bottom of the
 * compiled file so the styles you add here take precedence over styles defined in any other CSS
 * files in this directory. Styles in this file should be added after the last require_* statement.
 * It is generally better to create a new file per style scope.
 *
 *= require_tree .
 *= require_self
 */

/* Custom styles for TastyTrades UI */
body {
  background-color: #f8f9fa;
}

.navbar-brand {
  font-weight: bold;
}

.card {
  box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  border: 1px solid rgba(0, 0, 0, 0.125);
}

.card-header {
  background-color: #fff;
  border-bottom: 1px solid rgba(0, 0, 0, 0.125);
}

.table th {
  border-top: none;
  font-weight: 600;
  font-size: 0.875rem;
}

.badge {
  font-size: 0.75rem;
}

/* Trading specific styles */
.text-profit {
  color: #28a745 !important;
}

.text-loss {
  color: #dc3545 !important;
}

.position-long {
  border-left: 4px solid #28a745;
}

.position-short {
  border-left: 4px solid #dc3545;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .table-responsive {
    font-size: 0.875rem;
  }
  
  .card-body {
    padding: 1rem;
  }
}
```

## Step 6: Test the Web Interface

1. **Start the Rails server:**
   ```bash
   bundle exec rails server
   ```

2. **Test the views:**
   - Visit: http://localhost:3000/
   - Should redirect to login page
   - Test signup process
   - Test login process  
   - View dashboard
   - Test profile pages

## Step 7: Add JavaScript Enhancements (Optional)

Create `app/assets/javascripts/application.js`:

```javascript
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "controllers"

// Bootstrap JS components
import "bootstrap"

// Custom JavaScript for TastyTrades UI
document.addEventListener('DOMContentLoaded', function() {
  // Form validation
  const forms = document.querySelectorAll('.needs-validation');
  Array.from(forms).forEach(form => {
    form.addEventListener('submit', event => {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
      }
      form.classList.add('was-validated');
    }, false);
  });

  // Auto-dismiss alerts after 5 seconds
  const alerts = document.querySelectorAll('.alert-dismissible');
  alerts.forEach(alert => {
    setTimeout(() => {
      if (alert.querySelector('.btn-close')) {
        alert.querySelector('.btn-close').click();
      }
    }, 5000);
  });
});

// API helper functions
window.TastyTradesAPI = {
  call: async function(endpoint, options = {}) {
    const token = localStorage.getItem('api_token');
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };
    
    const response = await fetch(`/api/v1${endpoint}`, {
      ...defaultOptions,
      ...options,
      headers: { ...defaultOptions.headers, ...options.headers }
    });
    
    return response.json();
  },

  refreshPositions: async function() {
    try {
      const result = await this.call('/positions');
      console.log('Positions updated:', result);
      // Reload page to show updated data
      window.location.reload();
    } catch (error) {
      console.error('Failed to refresh positions:', error);
      alert('Failed to refresh positions. Please try again.');
    }
  }
};
```

## Troubleshooting

### Views Not Rendering

1. **Check routes:**
   ```bash
   bundle exec rails routes
   ```

2. **Check controller actions exist**

3. **Check for syntax errors:**
   ```bash
   bundle exec rails runner "puts 'Syntax OK'"
   ```

### Styling Issues

1. **Check asset pipeline:**
   ```bash
   bundle exec rails assets:precompile
   ```

2. **Check importmap configuration:**
   ```bash
   bundle exec rails importmap:show
   ```

### Bootstrap Not Loading

Verify the CDN links are accessible:

```bash
curl -I https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css
```

## Verification

Test that all views work correctly:

- [ ] Application layout renders properly
- [ ] Login/signup forms work
- [ ] Dashboard displays data correctly
- [ ] Profile pages are functional
- [ ] Bootstrap styling is applied
- [ ] JavaScript enhancements work
- [ ] Forms validate properly
- [ ] Navigation works correctly

## Next Steps

With the web interface complete, you can:

1. **Enhance the UI** with real-time updates using Turbo Streams
2. **Add charts** for portfolio visualization
3. **Implement order forms** for placing trades through the web interface
4. **Add real-time market data** displays
5. **Create trading strategy pages**

The web interface provides a user-friendly way to interact with your trading API while the API endpoints remain available for programmatic access.