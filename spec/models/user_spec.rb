require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many login_tokens' do
      association = described_class.reflect_on_association(:login_tokens)

      expect(association.macro).to eq(:has_many)
    end

    it 'destroys associated login_tokens when destroyed' do
      user = create(:user)
      create(:login_token, user: user)

      expect do
        user.destroy
      end.to change(LoginToken, :count).by(-1)
    end
  end

  describe 'validations' do
    it 'is valid with a valid email' do
      user = build(:user, email: 'test@example.com')

      expect(user).to be_valid
    end

    it 'is invalid without an email' do
      user = build(:user, email: nil)

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'email normalization' do
    it 'strips surrounding spaces' do
      user = create(:user, email: '  Marcelo@example.com  ')

      expect(user.reload.email).to eq('marcelo@example.com')
    end

    it 'downcases the email' do
      user = create(:user, email: 'MARCELO@EXAMPLE.COM')

      expect(user.reload.email).to eq('marcelo@example.com')
    end

    it 'normalizes before uniqueness validation' do
      create(:user, email: 'marcelo@example.com')
      user = build(:user, email: '  MARCELO@EXAMPLE.COM  ')

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end
  end
end
