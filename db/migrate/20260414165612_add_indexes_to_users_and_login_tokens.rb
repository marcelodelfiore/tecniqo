class AddIndexesToUsersAndLoginTokens < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :email, unique: true
    add_index :login_tokens, :token_digest, unique: true
    add_index :login_tokens, :expires_at
  end
end
