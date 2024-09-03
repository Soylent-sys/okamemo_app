require 'rails_helper'

RSpec.describe BootstrapHelper, type: :helper do
  describe "#bootstrap_alert" do
    subject { helper.bootstrap_alert(message_type) }

    context "引数が alert の文字列の場合" do
      let(:message_type) { "alert" }

      it { is_expected.to eq "warning" }
    end

    context "引数が notice の文字列の場合" do
      let(:message_type) { "notice" }

      it { is_expected.to eq "success" }
    end

    context "引数が error の文字列の場合" do
      let(:message_type) { "error" }

      it { is_expected.to eq "danger" }
    end
  end

  describe "#bootstrap_alert_icon" do
    subject { helper.bootstrap_alert_icon(message_type) }

    context "引数が alert の文字列の場合" do
      let(:message_type) { "alert" }

      it { is_expected.to eq "fas fa-circle-exclamation" }
    end

    context "引数が notice の文字列の場合" do
      let(:message_type) { "notice" }

      it { is_expected.to eq "fas fa-circle-check" }
    end

    context "引数が error の文字列の場合" do
      let(:message_type) { "error" }

      it { is_expected.to eq "fas fa-triangle-exclamation" }
    end
  end
end
