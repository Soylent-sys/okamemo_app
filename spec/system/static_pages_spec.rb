require 'rails_helper'

RSpec.describe "StaticPages", type: :system do
  describe "ビューの要素" do
    describe "terms" do
      before do
        visit terms_path
      end

      it "ページタイトルが正しいこと" do
        expect(page).to have_title "利用規約"
      end

      it "メインの見出しが表示されること" do
        expect(page).to have_selector("h1", text: "利用規約")
      end

      it "トップページにもどる のリンクが存在すること" do
        expect(page).to have_link("トップページ にもどる", href: root_path)
      end

      it "トップページにもどる のリンクをクリックしてrootページに遷移すること" do
        click_link "トップページ にもどる"

        expect(page).to have_http_status(:success)
        expect(current_path).to eq root_path
      end

      it "利用規約の本文が表示されること" do
        expect(page).to have_content "この利用規約（以下、「本規約」といいます。）は、"
        expect(page).to have_content "登録ユーザーの皆さま（以下、「ユーザー」といいます。）には、本規約に従って、本サービスをご利用いただきます。"
      end

      it "利用規約の各セクションの見出しが表示されること" do
        section_headings = [
          "適用範囲",
          "利用登録",
          "ユーザー登録情報の管理",
          "禁止事項",
          "本サービスの提供の停止",
          "利用制限および登録抹消",
          "退会",
          "保証の否認および免責事項",
          "サービス内容の変更等",
          "利用規約の変更",
          "個人情報の取扱い",
          "通知または連絡",
        ]
        section_headings.each do |heading|
          expect(page).to have_selector("h4", text: heading)
        end
      end

      it "プライバシーポリシーのページへ繊維するリンクが存在すること" do
        expect(page).to have_link("プライバシーポリシー", href: policy_path)
      end

      it "プライバシーポリシー のリンクをクリックしてプライバシーポリシーのページに遷移すること" do
        click_link "プライバシーポリシー"

        expect(page).to have_http_status(:success)
        expect(current_path).to eq policy_path
      end

      it "推奨環境の各セクションの見出しが表示されること" do
        expect(page).to have_selector("h2", text: "推奨環境")
        section_headings = [
          "OS",
          "デバイス",
          "ブラウザ",
          "OSのバージョン",
          "JavaScriptについて",
        ]
        section_headings.each do |heading|
          expect(page).to have_selector("h3", text: heading)
        end
        expect(page).to have_selector("h5", text: "パソコン")
        expect(page).to have_selector("h5", text: "スマートフォン・タブレット")
      end

      it "推奨環境の本文が表示されること" do
        expect(page).to have_content "当サイトのご利用にあたっては以下の環境にてご利用ください。"
        expect(page).to have_content "推奨以外のOS、デバイス、ブラウザをご利用の場合、動作や表示が正しく行われない可能性があります。"
      end
    end

    describe "policy" do
      before do
        visit policy_path
      end

      it "ページタイトルが正しいこと" do
        expect(page).to have_title "プライバシーポリシー"
      end

      it "メインの見出しが表示されること" do
        expect(page).to have_selector("h1", text: "プライバシーポリシー")
      end

      it "トップページにもどる のリンクが存在すること" do
        expect(page).to have_link("トップページ にもどる", href: root_path)
      end

      it "トップページにもどる のリンクをクリックしてrootページに遷移すること" do
        click_link "トップページ にもどる"

        expect(page).to have_http_status(:success)
        expect(current_path).to eq root_path
      end

      it "プライバシーポリシーの本文が表示されること" do
        expect(page).to have_content "当サイト、okamemo.com（以下、「当サイト」といいます。）は、"
        expect(page).to have_content "ユーザーの個人情報の取扱いについて、以下のとおりプライバシーポリシー（以下、「本ポリシー」といいます。）を定めます。"
      end

      it "プライバシーポリシーの各セクションの見出しが表示されること" do
        section_headings = [
          "基本方針",
          "取得する情報",
          "利用目的",
          "個人情報の管理",
          "個人情報の第三者提供",
          "適正な取得",
          "個人情報の利用停止等",
          "プライバシーポリシーの変更",
          "個人情報関連のお問い合わせ",
        ]
        section_headings.each do |heading|
          expect(page).to have_selector("h4", text: heading)
        end
      end
    end
  end
end
