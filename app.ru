# frozen_string_literal: true
require 'bundler/setup'
require "rails"
require "active_record/railtie"
require "rails/command"
require "rails/commands/server/server_command"

Rails.logger = Logger.new(STDOUT)

database = "#{Rails.env}.sqlite3"

ENV['DATABASE_URL'] = "sqlite3:#{database}"
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :donuts, force: true do |t|
    t.boolean :available
    t.bigint :orders, default: 0

    t.timestamps
  end
end

class App < ::Rails::Application
  config.consider_all_requests_local = false
  config.eager_load = true
  config.secret_key_base = 'secret'

  routes.append do
    get "up" => "rails/health#show", as: :rails_health_check

    root 'donuts#index'

    put 'donuts' => 'donuts#update', as: :donuts
    put 'order' => 'donuts#order', as: :order
  end
end

class Donut < ActiveRecord::Base
end

Donut.create!(available: true) if Donut.count.zero?

class DonutsController < ActionController::Base
  include Rails.application.routes.url_helpers

  http_basic_authenticate_with name: "hot", password: "donuts", only: :update

  before_action :load_donut

  def index
    render inline: """
      <!DOCTYPE html>
        <html>
          <head>
            <title>Hot donuts</title>
            <meta name='viewport' content='width=device-width,initial-scale=1'>
            <%= csrf_meta_tags %>
            <%= stylesheet_link_tag 'https://cdn.simplecss.org/simple.min.css' %>
          </head>
          <body>
            <main>
              <% if notice %>
                <p><mark><%= notice %></mark></p>
              <% end %>

              <p class='notice'>
                <%= content_tag(@donut.available? ? :mark : :span) do %>
                  Hot Donuts are <%= @donut.available? ? 'available!' : '<strong>not available.</strong'.html_safe %>
                <% end %>

                <% unless @donut.available? %>
                  <p>
                    <% if @donut.orders > 0 %>
                      <em><%= pluralize(@donut.orders, 'person') %> ordered a hot donut.</em>
                    <% else %>
                      Be the first to order a hot donut!
                    <% end %>
                  </p>

                  <%= form_with url: order_path, method: :put do |form| %>
                    <%= form.submit 'Order a donut' %>
                  <% end %>
                <% end %>
              </p>

              <%= form_with url: donuts_path, method: :put do |form| %>
                <%= form.submit @donut.available? ? 'Sold out' : 'Make available' %>
              <% end %>
            </main>
          </body>
        </html>
    """
  end

  def update
    @donut.toggle!(:available)

    redirect_to root_path
  end

  def order
    @donut.increment!(:orders)

    redirect_to root_path, notice: "Thanks for ordering a donut!"
  end

  def load_donut
    @donut = Donut.last
  end
end

App.initialize!

Rails::Server.new(app: App, Host: "0.0.0.0", Port: 80).start
