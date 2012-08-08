require 'devise_couch'
require 'devise/orm/couchrest_model/schema'
require 'devise/orm/couchrest_model/date_time'
require 'orm_adapter/adapters/couchrest_model'
require 'devise/hooks/activatable'
require 'devise/strategies/database_authenticatable'
require 'orm_adapter/to_adapter'
require 'orm_adapter/base'

module Devise
  module Orm
    module CouchrestModel
      module Hook
        def devise_modules_hook!
          extend Schema
          create_authentication_views
          yield
          return unless Devise.apply_schema
          devise_modules.each { |m| send(m) if respond_to?(m, true) }
        end

        private
        def create_authentication_views

          design do
            view :by_confirmation_token
            view :by_authentication_token
            view :by_reset_password_token
            view :by_unlock_token
          end
        end
      end
    end
  end
end

# resource returns a view - we want a an object of type CouchRest::Model
module Devise
  module Strategies
    # Default strategy for signing in a user, based on his email and password in the database.
    class DatabaseAuthenticatable < Authenticatable
      def authenticate!
        resource = valid_password? && mapping.to.find_for_database_authentication(authentication_hash)

        ########## GET FIRST RESULT ###############
        resource = resource.first
        ##############################################

        if validate(resource){ resource.valid_password?(password) }
          resource.after_database_authentication
          success!(resource)
        elsif !halted?
          fail(:invalid)
        end
      end
    end
  end
end

CouchRest::Model::Base.extend Devise::Models
CouchRest::Model::Base.extend Devise::Orm::CouchrestModel::Hook
