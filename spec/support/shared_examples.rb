RSpec.shared_examples "ナビゲーションのテスト" do
  context "ブラウザ幅が 576px以上 の場合", js: true do
    before do
      page.driver.browser.manage.window.resize_to(576, 1050)
    end

    # window幅のリセット
    after do
      page.driver.browser.manage.window.resize_to(1680, 1050)
    end

    it "現在のページに関するナビゲーション（左吹き出し版）が表示されていること" do
      within ".okamechan_nav" do
        expect(page).to have_selector("img[src*='okame_reverse']")
        expect(page).to have_selector(".arrow-box-left", visible: true)
        expect(page).to have_content navigation_content
      end
    end

    it "現在のページに関するナビゲーション（左下吹き出し版）が表示されていないこと" do
      within ".okamechan_nav" do
        expect(page).to have_selector(".arrow-box-bottom-left", visible: false)
      end
    end
  end

  context "ブラウザ幅が 575px以下 の場合", js: true do
    before do
      page.driver.browser.manage.window.resize_to(575, 1050)
    end

    # window幅のリセット
    after do
      page.driver.browser.manage.window.resize_to(1680, 1050)
    end

    it "現在のページに関するナビゲーション（左下吹き出し版）が表示されていること" do
      within ".okamechan_nav" do
        expect(page).to have_selector("img[src*='okame_reverse']")
        expect(page).to have_selector(".arrow-box-bottom-left", visible: true)
        expect(page).to have_content navigation_content
      end
    end

    it "現在のページに関するナビゲーション（左吹き出し版）が表示されていないこと" do
      within ".okamechan_nav" do
        expect(page).to have_selector(".arrow-box-left", visible: false)
      end
    end
  end
end

RSpec.shared_examples "ヘルプモーダルの基本機能テスト" do
  it "ヘルプボタンが表示されていること" do
    expect(page).to have_selector("button", text: "ヘルプ", visible: true)
  end

  it "画面を一番下までスクロールするとヘルプボタンが非表示になること", js: true do
    expect(page).to have_selector("button", text: "ヘルプ", visible: true)
    # 画面を一番下までスクロールする
    page.execute_script("window.scrollTo(0, document.body.scrollHeight);")

    expect(page).to have_selector("button", text: "ヘルプ", visible: false)
  end

  it "初期状態ではヘルプモーダルが表示されないこと" do
    expect(page).to have_selector("#helpModal", visible: false)
  end

  it "ヘルプボタンをクリックするとヘルプモーダルが表示されること", js: true do
    expect(page).to have_selector("#helpModal", visible: false)

    click_button "ヘルプ"

    within "#helpModal" do
      expect(page).to have_selector(".modal-content", visible: true)
    end
  end

  it "ヘルプモーダルのヘッダーにタイトルが表示されること", js: true do
    click_button "ヘルプ"

    within "#helpModal" do
      within ".modal-header" do
        # page_title変数はテストするシステムスペック上で定義する
        expect(page).to have_selector("h1.modal-title", visible: true, text: "#{page_title}のヘルプ")
      end
    end
  end

  it "ヘルプモーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
    click_button "ヘルプ"

    within "#helpModal" do
      within ".modal-header" do
        expect(page).to have_selector("button.btn-close", visible: true)
      end
    end
  end

  it "ヘルプモーダルのヘッダーの閉じるボタンでモーダルが非表示になること", js: true do
    click_button "ヘルプ"

    within "#helpModal" do
      within ".modal-header" do
        expect(page).to have_selector("button.btn-close", visible: true)
        find("button.btn-close").click
      end
    end

    expect(page).to have_selector("#helpModal", visible: false)
  end

  it "ヘルプモーダルのフッターに閉じるボタンがあること", js: true do
    click_button "ヘルプ"

    within "#helpModal" do
      within ".modal-footer" do
        expect(page).to have_selector("button.btn", visible: true, text: "閉じる")
      end
    end
  end

  it "ヘルプモーダルのフッターの閉じるボタンでモーダルが非表示になること", js: true do
    click_button "ヘルプ"

    within "#helpModal" do
      within ".modal-footer" do
        expect(page).to have_selector("button.btn", visible: true, text: "閉じる")
        click_button "閉じる"
      end
    end

    expect(page).to have_selector("#helpModal", visible: false)
  end

  it "ヘルプモーダル外をクリックするとモーダルが閉じること", js: true do
    click_button "ヘルプ"

    expect(page).to have_selector('#helpModal', visible: true)

    # モーダルの外をクリック
    page.execute_script("document.querySelector('body').click();")

    expect(page).to have_selector('#helpModal', visible: false)
  end
end
