RSpec.shared_context "skip call back set_email_confirmation" do
  before do
    NotificationTargetUser.skip_callback(:create, :before, :set_email_confirmation)
  end

  after do
    NotificationTargetUser.set_callback(:create, :before, :set_email_confirmation)
  end
end
