require 'rails_helper'

RSpec.describe "Home", type: :system do
  describe "index" do
    context "サインインしていない場合" do
      before do
        visit root_path
      end

      it "挨拶文が表示されていること" do
        within ".introduction" do
          expect(page).to have_selector("h1", text: "こんにちは！おかメchan へようこそ！")
        end
      end

      it "ユーザー登録画面に遷移するリンクが存在すること" do
        within ".introduction" do
          expect(page).to have_link("ユーザー登録する！", href: new_user_registration_path)
        end
      end

      it "ユーザー登録する！をクリックしてユーザー登録画面へ遷移できること" do
        within ".introduction" do
          click_link "ユーザー登録する！"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(new_user_registration_path)
      end

      it "アプリの利用が推奨されるケースについて表示されていること" do
        expect(page).to have_selector("h2", text: "おかメchan はこんなヒトにオススメ！")
      end

      it "オカメインコの画像（reverse）が表示されていること" do
        expect(page).to have_selector("img[src*='okame_reverse']")
      end

      it "アプリの使い方紹介の主な項目が表示されていること" do
        expect(page).to have_selector("h2", text: "ー おかメchanの使い方 ー")

        within ".instructions-1" do
          expect(page).to have_selector("h3", text: "お買い物登録する")
        end

        within ".instructions-2" do
          expect(page).to have_selector("h3", text: "お買い物モードにしてお買い物する！")
        end

        within ".instructions-3" do
          expect(page).to have_selector("h3", text: "お買い物が終わったら")
        end
      end

      it "アプリのオプション機能紹介の項目が表示されていること" do
        within ".other-features" do
          expect(page).to have_selector("h2", text: "こんな機能もあるよ！")
        end
      end

      it "アプリの利用を促す文言が表示されていること" do
        expect(page).to have_selector("p", text: "買い忘れが多くて大変なヒトはおかメchan をぜひ使ってみてね！")
      end

      it "オカメインコの画像（通常版）が表示されていること" do
        expect(page).to have_selector("img[src*='okame_std']")
      end

      it "ヘルプボタンが表示されていないこと" do
        expect(page).to_not have_selector("button", text: "ヘルプ")
      end

      shared_examples "ブラウザ幅 576px以上 の時のサービスロゴ表示テスト" do
        it "サービスロゴの画像（通常版）が表示されていること" do
          within ".introduction" do
            expect(page).to have_selector("img[src*='logo_std']", visible: true)
          end
        end

        it "サービスロゴの画像（モバイル版）が表示されていないこと" do
          within ".introduction" do
            expect(page).to have_selector("img[src*='logo_sm']", visible: false)
          end
        end
      end

      shared_examples "ブラウザ幅 767px以下 の時のお買い物機能紹介画像の表示テスト" do
        it "お買い物登録の手順を示す画像（モバイル版）が表示されていること" do
          within ".instructions-1" do
            expect(page).to have_selector("img[src*='instruction_1a_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_1b_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_1c_mini']", visible: true)
          end
        end

        it "お買い物登録の手順を示す画像（通常版）が表示されていないこと" do
          within ".instructions-1" do
            expect(page).to have_selector("img[src*='instruction_1a_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_1b_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_1c_std']", visible: false)
          end
        end

        it "お買い物モードの利用手順を示す画像（モバイル版）が表示されていること" do
          within ".instructions-2" do
            expect(page).to have_selector("img[src*='instruction_2a_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2b_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2c_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2d_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2e_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2f_mini']", visible: true)
          end
        end

        it "お買い物モードの利用手順を示す画像（通常版）が表示されていないこと" do
          within ".instructions-2" do
            expect(page).to have_selector("img[src*='instruction_2a_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2b_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2c_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2d_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2e_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2f_std']", visible: false)
          end
        end

        it "お買い物履歴・場所確認の機能を示す画像（モバイル版）が表示されていること" do
          within ".instructions-3" do
            expect(page).to have_selector("img[src*='instruction_3a_mini']", visible: true)
            expect(page).to have_selector("img[src*='instruction_3b_mini']", visible: true)
          end
        end

        it "お買い物履歴・場所確認の機能を示す画像（通常版）が表示されていないこと" do
          within ".instructions-3" do
            expect(page).to have_selector("img[src*='instruction_3a_std']", visible: false)
            expect(page).to have_selector("img[src*='instruction_3b_std']", visible: false)
          end
        end
      end

      shared_examples "ブラウザ幅 767px以下 の時のお買い物機能紹介画像モーダルのテスト" do
        it "img[src*='instruction_1a_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-1a-m", visible: false)

          find("img[src*='instruction_1a_mini']").click

          expect(page).to have_selector("#instruction-1a-m", visible: true)

          within "#instruction-1a-m" do
            expect(page).to have_selector("img[src*='instruction_1a_mini']")
          end
        end

        it "img[src*='instruction_1a_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_1a_mini']").click

          expect(page).to have_selector("#instruction-1a-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-1a-m", visible: false)
        end

        it "img[src*='instruction_1b_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-1b-m", visible: false)

          find("img[src*='instruction_1b_mini']").click

          expect(page).to have_selector("#instruction-1b-m", visible: true)

          within "#instruction-1b-m" do
            expect(page).to have_selector("img[src*='instruction_1b_mini']")
          end
        end

        it "img[src*='instruction_1b_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_1b_mini']").click

          expect(page).to have_selector("#instruction-1b-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-1b-m", visible: false)
        end

        it "img[src*='instruction_1c_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-1c-m", visible: false)

          find("img[src*='instruction_1c_mini']").click

          expect(page).to have_selector("#instruction-1c-m", visible: true)

          within "#instruction-1c-m" do
            expect(page).to have_selector("img[src*='instruction_1c_mini']")
          end
        end

        it "img[src*='instruction_1c_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_1c_mini']").click

          expect(page).to have_selector("#instruction-1c-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-1c-m", visible: false)
        end

        it "img[src*='instruction_2a_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2a-m", visible: false)

          find("img[src*='instruction_2a_mini']").click

          expect(page).to have_selector("#instruction-2a-m", visible: true)

          within "#instruction-2a-m" do
            expect(page).to have_selector("img[src*='instruction_2a_mini']")
          end
        end

        it "img[src*='instruction_2a_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2a_mini']").click

          expect(page).to have_selector("#instruction-2a-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2a-m", visible: false)
        end

        it "img[src*='instruction_2b_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2b-m", visible: false)

          find("img[src*='instruction_2b_mini']").click

          expect(page).to have_selector("#instruction-2b-m", visible: true)

          within "#instruction-2b-m" do
            expect(page).to have_selector("img[src*='instruction_2b_mini']")
          end
        end

        it "img[src*='instruction_2b_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2b_mini']").click

          expect(page).to have_selector("#instruction-2b-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2b-m", visible: false)
        end

        it "img[src*='instruction_2c_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2c-m", visible: false)

          find("img[src*='instruction_2c_mini']").click

          expect(page).to have_selector("#instruction-2c-m", visible: true)

          within "#instruction-2c-m" do
            expect(page).to have_selector("img[src*='instruction_2c_mini']")
          end
        end

        it "img[src*='instruction_2c_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2c_mini']").click

          expect(page).to have_selector("#instruction-2c-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2c-m", visible: false)
        end

        it "img[src*='instruction_2d_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2d-m", visible: false)

          find("img[src*='instruction_2d_mini']").click

          expect(page).to have_selector("#instruction-2d-m", visible: true)

          within "#instruction-2d-m" do
            expect(page).to have_selector("img[src*='instruction_2d_mini']")
          end
        end

        it "img[src*='instruction_2d_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2d_mini']").click

          expect(page).to have_selector("#instruction-2d-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2d-m", visible: false)
        end

        it "img[src*='instruction_2e_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2e-m", visible: false)

          find("img[src*='instruction_2e_mini']").click

          expect(page).to have_selector("#instruction-2e-m", visible: true)

          within "#instruction-2e-m" do
            expect(page).to have_selector("img[src*='instruction_2e_mini']")
          end
        end

        it "img[src*='instruction_2e_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2e_mini']").click

          expect(page).to have_selector("#instruction-2e-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2e-m", visible: false)
        end

        it "img[src*='instruction_2f_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2f-m", visible: false)

          find("img[src*='instruction_2f_mini']").click

          expect(page).to have_selector("#instruction-2f-m", visible: true)

          within "#instruction-2f-m" do
            expect(page).to have_selector("img[src*='instruction_2f_mini']")
          end
        end

        it "img[src*='instruction_2f_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2f_mini']").click

          expect(page).to have_selector("#instruction-2f-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2f-m", visible: false)
        end

        it "img[src*='instruction_3a_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-3a-m", visible: false)

          find("img[src*='instruction_3a_mini']").click

          expect(page).to have_selector("#instruction-3a-m", visible: true)

          within "#instruction-3a-m" do
            expect(page).to have_selector("img[src*='instruction_3a_mini']")
          end
        end

        it "img[src*='instruction_3a_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_3a_mini']").click

          expect(page).to have_selector("#instruction-3a-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-3a-m", visible: false)
        end

        it "img[src*='instruction_3b_mini']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-3b-m", visible: false)

          find("img[src*='instruction_3b_mini']").click

          expect(page).to have_selector("#instruction-3b-m", visible: true)

          within "#instruction-3b-m" do
            expect(page).to have_selector("img[src*='instruction_3b_mini']")
          end
        end

        it "img[src*='instruction_3b_mini']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_3b_mini']").click

          expect(page).to have_selector("#instruction-3b-m", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-3b-m", visible: false)
        end
      end

      context "ブラウザ幅が 768px以上 の場合", js: true do
        before do
          page.driver.browser.manage.window.resize_to(768, 1050)
        end

        # window幅のリセット
        after do
          page.driver.browser.manage.window.resize_to(1680, 1050)
        end

        it_behaves_like "ブラウザ幅 576px以上 の時のサービスロゴ表示テスト"

        it "お買い物登録の手順を示す画像（通常版）が表示されていること" do
          within ".instructions-1" do
            expect(page).to have_selector("img[src*='instruction_1a_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_1b_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_1c_std']", visible: true)
          end
        end

        it "お買い物登録の手順を示す画像（モバイル版）が表示されていないこと" do
          within ".instructions-1" do
            expect(page).to have_selector("img[src*='instruction_1a_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_1b_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_1c_mini']", visible: false)
          end
        end

        it "お買い物モードの利用手順を示す画像（通常版）が表示されていること" do
          within ".instructions-2" do
            expect(page).to have_selector("img[src*='instruction_2a_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2b_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2c_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2d_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2e_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_2f_std']", visible: true)
          end
        end

        it "お買い物モードの利用手順を示す画像（モバイル版）が表示されていないこと" do
          within ".instructions-2" do
            expect(page).to have_selector("img[src*='instruction_2a_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2b_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2c_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2d_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2e_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_2f_mini']", visible: false)
          end
        end

        it "お買い物履歴・場所確認の機能を示す画像（通常版）が表示されていること" do
          within ".instructions-3" do
            expect(page).to have_selector("img[src*='instruction_3a_std']", visible: true)
            expect(page).to have_selector("img[src*='instruction_3b_std']", visible: true)
          end
        end

        it "お買い物履歴・場所確認の機能を示す画像（モバイル版）が表示されていないこと" do
          within ".instructions-3" do
            expect(page).to have_selector("img[src*='instruction_3a_mini']", visible: false)
            expect(page).to have_selector("img[src*='instruction_3b_mini']", visible: false)
          end
        end

        it "img[src*='instruction_1a_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-1a", visible: false)

          find("img[src*='instruction_1a_std']").click

          expect(page).to have_selector("#instruction-1a", visible: true)

          within "#instruction-1a" do
            expect(page).to have_selector("img[src*='instruction_1a_std']")
          end
        end

        it "img[src*='instruction_1a_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_1a_std']").click

          expect(page).to have_selector("#instruction-1a", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-1a", visible: false)
        end

        it "img[src*='instruction_1b_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-1b", visible: false)

          find("img[src*='instruction_1b_std']").click

          expect(page).to have_selector("#instruction-1b", visible: true)

          within "#instruction-1b" do
            expect(page).to have_selector("img[src*='instruction_1b_std']")
          end
        end

        it "img[src*='instruction_1b_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_1b_std']").click

          expect(page).to have_selector("#instruction-1b", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-1b", visible: false)
        end

        it "img[src*='instruction_1c_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-1c", visible: false)

          find("img[src*='instruction_1c_std']").click

          expect(page).to have_selector("#instruction-1c", visible: true)

          within "#instruction-1c" do
            expect(page).to have_selector("img[src*='instruction_1c_std']")
          end
        end

        it "img[src*='instruction_1c_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_1c_std']").click

          expect(page).to have_selector("#instruction-1c", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-1c", visible: false)
        end

        it "img[src*='instruction_2a_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2a", visible: false)

          find("img[src*='instruction_2a_std']").click

          expect(page).to have_selector("#instruction-2a", visible: true)

          within "#instruction-2a" do
            expect(page).to have_selector("img[src*='instruction_2a_std']")
          end
        end

        it "img[src*='instruction_2a_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2a_std']").click

          expect(page).to have_selector("#instruction-2a", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2a", visible: false)
        end

        it "img[src*='instruction_2b_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2b", visible: false)

          find("img[src*='instruction_2b_std']").click

          expect(page).to have_selector("#instruction-2b", visible: true)

          within "#instruction-2b" do
            expect(page).to have_selector("img[src*='instruction_2b_std']")
          end
        end

        it "img[src*='instruction_2b_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2b_std']").click

          expect(page).to have_selector("#instruction-2b", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2b", visible: false)
        end

        it "img[src*='instruction_2c_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2c", visible: false)

          find("img[src*='instruction_2c_std']").click

          expect(page).to have_selector("#instruction-2c", visible: true)

          within "#instruction-2c" do
            expect(page).to have_selector("img[src*='instruction_2c_std']")
          end
        end

        it "img[src*='instruction_2c_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2c_std']").click

          expect(page).to have_selector("#instruction-2c", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2c", visible: false)
        end

        it "img[src*='instruction_2d_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2d", visible: false)

          find("img[src*='instruction_2d_std']").click

          expect(page).to have_selector("#instruction-2d", visible: true)

          within "#instruction-2d" do
            expect(page).to have_selector("img[src*='instruction_2d_std']")
          end
        end

        it "img[src*='instruction_2d_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2d_std']").click

          expect(page).to have_selector("#instruction-2d", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2d", visible: false)
        end

        it "img[src*='instruction_2e_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2e", visible: false)

          find("img[src*='instruction_2e_std']").click

          expect(page).to have_selector("#instruction-2e", visible: true)

          within "#instruction-2e" do
            expect(page).to have_selector("img[src*='instruction_2e_std']")
          end
        end

        it "img[src*='instruction_2e_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2e_std']").click

          expect(page).to have_selector("#instruction-2e", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2e", visible: false)
        end

        it "img[src*='instruction_2f_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-2f", visible: false)

          find("img[src*='instruction_2f_std']").click

          expect(page).to have_selector("#instruction-2f", visible: true)

          within "#instruction-2f" do
            expect(page).to have_selector("img[src*='instruction_2f_std']")
          end
        end

        it "img[src*='instruction_2f_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_2f_std']").click

          expect(page).to have_selector("#instruction-2f", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-2f", visible: false)
        end

        it "img[src*='instruction_3a_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-3a", visible: false)

          find("img[src*='instruction_3a_std']").click

          expect(page).to have_selector("#instruction-3a", visible: true)

          within "#instruction-3a" do
            expect(page).to have_selector("img[src*='instruction_3a_std']")
          end
        end

        it "img[src*='instruction_3a_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_3a_std']").click

          expect(page).to have_selector("#instruction-3a", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-3a", visible: false)
        end

        it "img[src*='instruction_3b_std']をクリックして画像のモーダルが表示されること" do
          expect(page).to have_selector("#instruction-3b", visible: false)

          find("img[src*='instruction_3b_std']").click

          expect(page).to have_selector("#instruction-3b", visible: true)

          within "#instruction-3b" do
            expect(page).to have_selector("img[src*='instruction_3b_std']")
          end
        end

        it "img[src*='instruction_3b_std']のモーダルの外をクリックするとモーダルが閉じること" do
          find("img[src*='instruction_3b_std']").click

          expect(page).to have_selector("#instruction-3b", visible: true)

          # モーダルの外をクリックする
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#instruction-3b", visible: false)
        end
      end

      context "ブラウザ幅が 767px以下 の場合", js: true do
        before do
          page.driver.browser.manage.window.resize_to(767, 1050)
        end

        # window幅のリセット
        after do
          page.driver.browser.manage.window.resize_to(1680, 1050)
        end

        it_behaves_like "ブラウザ幅 576px以上 の時のサービスロゴ表示テスト"

        it_behaves_like "ブラウザ幅 767px以下 の時のお買い物機能紹介画像の表示テスト"

        it_behaves_like "ブラウザ幅 767px以下 の時のお買い物機能紹介画像モーダルのテスト"
      end

      context "ブラウザ幅が 575px以下 の場合", js: true do
        before do
          page.driver.browser.manage.window.resize_to(575, 1050)
        end

        # window幅のリセット
        after do
          page.driver.browser.manage.window.resize_to(1680, 1050)
        end

        it_behaves_like "ブラウザ幅 767px以下 の時のお買い物機能紹介画像の表示テスト"

        it_behaves_like "ブラウザ幅 767px以下 の時のお買い物機能紹介画像モーダルのテスト"

        it "サービスロゴの画像（モバイル版）が表示されていること" do
          within ".introduction" do
            expect(page).to have_selector("img[src*='logo_sm']", visible: true)
          end
        end

        it "サービスロゴの画像（通常版）が表示されていないこと" do
          within ".introduction" do
            expect(page).to have_selector("img[src*='logo_std']", visible: false)
          end
        end
      end
    end

    context "サインインしている場合" do
      let(:user) { create(:user) }
      # ログアウト時に実行されるbeforeアクションと
      # 管理機能のコントローラー上でマスター管理ユーザーの
      # インスタンス変数を定義するためにそれぞれ必要
      let!(:master_user) { create(:user, :master_admin) }

      before do
        sign_in_as(user)
      end

      include_examples "ユーザー情報の表示テスト"

      # ナビゲーションのテスト用変数
      let(:navigation_content) { "ようこそ！ #{user.name} さん！\nここはメインメニューだよ。" }

      include_examples "ナビゲーションのテスト"

      it "ページタイトルが表示されていること" do
        expect(page).to have_selector("h1", text: "メインメニュー")
      end

      it "お買い物登録画面へ遷移するリンクが存在すること" do
        within "ul.list-unstyled" do
          expect(page).to have_link("お買い物の登録", href: shopping_new_path)
        end
      end

      it "お買い物登録をクリックしてお買い物登録画面へ遷移できること" do
        within "ul.list-unstyled" do
          click_link "お買い物の登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(shopping_new_path)
      end

      it "お買い物モード画面へ遷移するリンクが存在すること" do
        within "ul.list-unstyled" do
          expect(page).to have_link("お買い物モード", href: shopping_index_path)
        end
      end

      it "お買い物モードをクリックしてお買い物モード画面へ遷移できること" do
        within "ul.list-unstyled" do
          click_link "お買い物モード"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(shopping_index_path)
      end

      it "お買い物履歴画面へ遷移するリンクが存在すること" do
        within "ul.list-unstyled" do
          expect(page).to have_link("お買い物の履歴", href: shopping_result_group_path)
        end
      end

      it "お買い物の履歴をクリックしてお買い物履歴画面へ遷移できること" do
        within "ul.list-unstyled" do
          click_link "お買い物の履歴"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(shopping_result_group_path)
      end

      it "通知対象ユーザー一覧画面へ遷移するリンクが存在すること" do
        within "ul.list-unstyled" do
          expect(page).to have_link("通知メール登録", href: notification_target_users_path)
        end
      end

      it "通知メール登録をクリックして通知対象ユーザー一覧画面へ遷移できること" do
        within "ul.list-unstyled" do
          click_link "通知メール登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(notification_target_users_path)
      end

      it "アイテム一覧画面へ遷移するリンクが存在すること" do
        within "ul.list-unstyled" do
          expect(page).to have_link("アイテム登録", href: items_path)
        end
      end

      it "アイテム登録をクリックしてアイテム一覧画面へ遷移できること" do
        within "ul.list-unstyled" do
          click_link "アイテム登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(items_path)
      end

      it "ユーザー編集画面へ遷移するリンクが存在すること" do
        within "ul.list-unstyled" do
          expect(page).to have_link("ユーザー設定", href: edit_user_registration_path)
        end
      end

      it "ユーザー設定をクリックしてユーザー編集画面へ遷移できること" do
        within "ul.list-unstyled" do
          click_link "ユーザー設定"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq(edit_user_registration_path)
      end

      # ログアウトボタン・モーダルの基本機能テスト用変数
      let(:selector) { "ul.list-unstyled" }

      include_examples "ログアウトボタン・モーダルの基本機能テスト"

      # ヘルプモーダルの基本機能テスト用変数
      let(:page_title) { "メインメニュー" }

      include_examples "ヘルプモーダルの基本機能テスト"

      it "ヘルプモーダル内の主な項目が正しく表示されること" do
        within "#helpModal.modal" do
          expect(page).to have_selector("h3", text: "各機能の説明")
          expect(page).to have_selector("h4", text: "お買い物機能")
          expect(page).to have_selector("h5", text: "お買い物の登録")
          expect(page).to have_selector("h5", text: "お買い物モード")
          expect(page).to have_selector("h5", text: "お買い物の履歴")
          expect(page).to have_selector("h4", text: "ユーティリティ")
          expect(page).to have_selector("h5", text: "通知メール登録")
          expect(page).to have_selector("h5", text: "アイテム登録")
          expect(page).to have_selector("h5", text: "ユーザー設定")
          expect(page).to have_selector("h4", text: "その他")
          expect(page).to have_selector("h5", text: "ログアウト")
        end
      end
    end

    describe "ユーザー区分で異なる箇所のテスト" do
      before do
        sign_in_as(user)
      end

      context "一般ユーザー・ゲストユーザーの場合" do
        let(:user) { create(:user) }

        it "管理者機能へ遷移するリンクが存在しないこと" do
          within "ul.list-unstyled" do
            expect(page).to_not have_link("管理者機能", href: management_users_path)
          end
        end
      end

      context "管理ユーザー・マスター管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }
        # 管理機能のコントローラー上でマスター管理ユーザーのインスタンス変数を定義するために必要
        let!(:master_user) { create(:user, :master_admin) }

        it "管理者機能へ遷移するリンクが存在すること" do
          within "ul.list-unstyled" do
            expect(page).to have_link("管理者機能", href: management_users_path)
          end
        end

        it "管理者機能をクリックして管理画面へ遷移できること" do
          within "ul.list-unstyled" do
            click_link "管理者機能"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq(management_users_path)
        end
      end
    end
  end
end
