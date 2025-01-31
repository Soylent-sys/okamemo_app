require "rails_helper"

RSpec.describe AdminConstraint do
  let(:request) { instance_double("Request", env: { "warden" => warden }) }
  let(:warden) { instance_double("Warden::Proxy", user: user) }

  context "管理ユーザーがサインインしている場合" do
    let(:user) { instance_double("User", admin?: true) }

    it "true を返すこと" do
      expect(AdminConstraint.matches?(request)).to be true
    end
  end

  context "一般ユーザーがサインインしている場合" do
    let(:user) { instance_double("User", admin?: false) }

    it "false を返すこと" do
      expect(AdminConstraint.matches?(request)).to be false
    end
  end

  context "サインインしていない場合" do
    let(:user) { nil }

    it "false を返すこと" do
      expect(AdminConstraint.matches?(request)).to be false
    end
  end
end
