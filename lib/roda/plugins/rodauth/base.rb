require 'securerandom'
require 'bcrypt'

class Roda
  module RodaPlugins
    module Rodauth
      Base = Feature.define(:base) do
        auth_value_methods(
          :account_id,
          :account_model,
          :account_open_status_value,
          :account_status_id,
          :default_redirect,
          :login_column,
          :login_confirm_param,
          :login_errors_message,
          :login_param,
          :login_redirect,
          :logins_do_not_match_message,
          :no_matching_login_message,
          :password_confirm_param,
          :password_does_not_meet_requirements_message,
          :password_hash_column,
          :password_hash_cost,
          :password_hash_table,
          :password_param,
          :passwords_do_not_match_message,
          :prefix,
          :require_login_notice_message,
          :require_login_redirect,
          :session_key
        )

        auth_methods(
          :account_from_login,
          :account_from_session,
          :clear_session,
          :logged_in?,
          :password_hash,
          :password_meets_requirements?,
          :random_key,
          :require_login,
          :session_value,
          :set_error_flash,
          :set_notice_flash,
          :set_redirect_error_flash,
          :set_title,
          :update_session
        )

        attr_reader :scope
        attr_reader :account

        def initialize(scope)
          @scope = scope
        end

        def features
          self.class.features
        end

        def request
          scope.request
        end

        def response
          scope.response
        end

        def session
          scope.session
        end

        def flash
          scope.flash
        end

        # Overridable methods

        def session_value
          account.send(account_id)
        end

        def account_from_login(login)
          @account = account_model.where(login_column=>login, account_status_id=>account_open_status_value).first
        end

        def update_session
          session[session_key] = session_value
        end

        def account_model
          ::Account
        end

        def clear_session
          session.clear
        end

        def default_redirect
          '/'
        end

        def require_login_redirect
          "#{prefix}/login"
        end
        alias login_redirect require_login_redirect

        def require_login_notice_message
          "Please login to continue"
        end

        def prefix
          ''
        end

        def login_required
          set_notice_flash require_login_notice_message
          request.redirect require_login_redirect
        end

        def random_key
          SecureRandom.urlsafe_base64(32)
        end

        def set_title(title)
        end

        def set_error_flash(message)
          flash.now[:error] = message
        end

        def set_redirect_error_flash(message)
          flash[:error] = message
        end

        def set_notice_flash(message)
          flash[:notice] = message
        end

        def login_column
          :email
        end

        def password_hash_column
          :password_hash
        end

        def password_hash_table
          :account_password_hashes
        end

        def no_matching_login_message
          "no matching login"
        end

        def logged_in?
          session[session_key]
        end

        def login_param
          'login'
        end

        def login_confirm_param
          'login-confirm'
        end

        def login_errors_message
          if errors = account.errors.on(login_column)
            errors.join(', ')
          end
        end

        def logins_do_not_match_message
          'logins do not match'
        end

        def password_param
          'password'
        end

        def password_confirm_param
          'password-confirm'
        end

        def session_key
          :account_id
        end

        def account_id
          :id
        end

        def account_status_id
          :status_id
        end

        def passwords_do_not_match_message
          'passwords do not match'
        end

        def password_does_not_meet_requirements_message
          'invalid password, does not meet requirements'
        end

        def password_meets_requirements?(password)
          true
        end

        def account_open_status_value
          2
        end

        def account_from_session
          @account = account_model.where(account_status_id=>account_open_status_value, account_id=>scope.session[session_key]).first
        end

        def password_hash_cost
          BCrypt::Engine::DEFAULT_COST
        end

        def password_hash(password)
          BCrypt::Password.create(password, :cost=>password_hash_cost)
        end

        def set_password(password)
          hash = password_hash(password)
          if account_model.db[password_hash_table].where(account_id=>account.send(account_id)).update(password_hash_column=>hash) == 0
            account_model.db[password_hash_table].insert(account_id=>account.send(account_id), password_hash_column=>hash)
          end
        end

        def transaction(&block)
          account_model.db.transaction(&block)
        end

        def view(page, title)
          set_title(title)
          _view(:view, page)
        end

        def render(page)
          _view(:render, page)
        end

        def verify_created_accounts?
          false
        end

        def allow_reset_password?
          false
        end

        private

        def _view(meth, page)
          scope.instance_exec do
            template_opts = find_template(parse_template_opts(page, {}))
            unless File.file?(template_path(template_opts))
              template_opts[:path] = File.join(File.dirname(__FILE__), '../../../../templates', "#{page}.str")
            end
            send(meth, template_opts)
          end
        end
      end
    end
  end
end
