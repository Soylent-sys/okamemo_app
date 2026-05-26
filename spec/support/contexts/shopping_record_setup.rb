RSpec.shared_context "shopping record setup" do
  let(:user) { create(:user) }
  let(:shopping_record) { create(:shopping_record, user: user) }
end
