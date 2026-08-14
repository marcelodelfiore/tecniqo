class EnforceAuthenticationConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :email, false
    change_column_null :login_tokens, :token_digest, false
    change_column_null :login_tokens, :expires_at, false
  end
end
