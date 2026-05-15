require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#full_title" do
    let(:default_title) { "#{ApplicationHelper::BASE_TITLE} - 買い物お助けサービス" }

    context "ページタイトル(title)が存在する場合" do
      it "ページタイトル(title)とBASE_TITLEが含まれている文字列を返すこと" do
        expect(helper.full_title(title: "TOPページ")).to eq("TOPページ - #{ApplicationHelper::BASE_TITLE}")
      end
    end

    context "ページタイトル(:title)が存在しない場合" do
      it "デフォルトタイトル(BASE_TITLEを含む定型文字列)を返すこと" do
        expect(helper.full_title(title: "")).to eq(default_title)
      end
    end

    context "ページタイトル(:title)にnilを渡した場合" do
      it "デフォルトタイトル(BASE_TITLEを含む定型文字列)を返すこと" do
        expect(helper.full_title(title: nil)).to eq(default_title)
      end
    end

    context "ページタイトル(:title)にスペース（空白）を渡した場合" do
      it "デフォルトタイトル(BASE_TITLEを含む定型文字列)を返すこと" do
        expect(helper.full_title(title: " ")).to eq(default_title)
      end
    end
  end

  describe "#html_safe_newline" do
    it "改行を <br> に変換すること" do
      input = "Hello\nWorld"
      expected_output = "Hello<br>World"

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end

    it "キャリッジリターンを <br> に変換すること" do
      input = "Hello\rWorld"
      expected_output = "Hello<br>World"

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end

    it "キャリッジリターンと改行の組み合わせを <br> に変換すること" do
      input = "Hello\r\nWorld"
      expected_output = "Hello<br>World"

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end

    it "複数の改行をすべて <br> に変換すること" do
      input = "Hello\nWorld\n!!"
      expected_output = "Hello<br>World<br>!!"

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end

    it "HTMLセーフな文字列を返すこと" do
      input = "Hello\nWorld"
      result = helper.html_safe_newline(input)

      expect(result).to be_html_safe
    end

    it "HTMLをエスケープすること" do
      input = "<script>alert('XSS');</script>\nHello"
      expected_output = "&lt;script&gt;alert(&#39;XSS&#39;);&lt;/script&gt;<br>Hello"

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end

    it "空文字を渡したときは空文字を返すこと" do
      input = ""
      expected_output = ""

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end

    it "nilを渡したときは空文字を返すこと" do
      input = nil
      expected_output = ""

      expect(helper.html_safe_newline(input)).to eq(expected_output)
    end
  end

  describe "#position_flash" do
    context "サインインしている場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "position-flashの文字列を返すこと" do
        expect(helper.position_flash).to eq("position-flash")
      end
    end

    context "サインインしていない場合" do
      it "position-flash-no-loginの文字列を返すこと" do
        expect(helper.position_flash).to eq("position-flash-no-login")
      end
    end
  end

  describe "#now_info" do
    subject { helper.now_info(path) }

    context "引数のpathに management の文字列を含む場合" do
      let(:path) { "management/users" }

      it { is_expected.to eq("管理機能を利用中！") }
    end

    context "引数のpathに users/edit の文字列を含む場合" do
      let(:path) { "users/edit/pfofile" }

      it { is_expected.to eq("ユーザー編集中！") }
    end

    context "引数のpathに shopping/new の文字列を含む場合" do
      let(:path) { "shopping/new" }

      it { is_expected.to eq("お買い物登録中！") }
    end

    context "引数のpathに progress の文字列を含む場合" do
      let(:path) { "shopping/hashid/progress" }

      it { is_expected.to eq("お買い物中！") }
    end

    context "引数のpathに location の文字列を含む場合" do
      let(:path) { "shopping/result/hashid/location/new" }

      it { is_expected.to eq("マップ記録中！") }
    end

    context "引数のpathに notification_target_users/new の文字列を含む場合" do
      let(:path) { "notification_target_users/new" }

      it { is_expected.to eq("通知ユーザー登録中！") }
    end

    context "引数のpathに items/new の文字列を含む場合" do
      let(:path) { "items/new" }

      it { is_expected.to eq("アイテム登録中！") }
    end

    context "引数のpathが items/{任意の文字列}/edit のフォーマットと一致する場合" do
      let(:path) { "items/hashid/edit" }

      it { is_expected.to eq("アイテム編集中！") }
    end

    context "その他のpathの場合" do
      let(:path) { "contact" }

      it { is_expected.to eq("ログイン中！") }
    end

    context "pathが空文字の場合" do
      let(:path) { "" }

      it { is_expected.to eq("ログイン中！") }
    end
  end

  describe "#management_menu_active_class" do
    let(:request_path) { "/management/users/1/edit" }

    subject { helper.management_menu_active_class(path, request_path) }

    context "第二引数(request_path)に第一引数(path)が含まれている場合" do
      let(:path) { "/management/users" }

      it { is_expected.to eq("mx-3 rounded-2 bg-secondary-subtle") }
    end

    context "第二引数(request_path)に第一引数(path)が含まれていない場合" do
      let(:path) { "/management/items" }

      it { is_expected.to be_nil }
    end
  end

  describe "#management_flash_margin_off" do
    subject { helper.management_flash_margin_off(path) }

    context "引数(path)に management の文字列が含まれている場合" do
      let(:path) { "/management/users" }

      it { is_expected.to eq("mb-0") }
    end

    context "引数(path)に management の文字列が含まれていない場合" do
      let(:path) { "/users" }

      it { is_expected.to be_nil }
    end
  end
end
