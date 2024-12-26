require 'rails_helper'

RSpec.describe "ShoppingLocations", type: :system do
  # Google Maps API のモックヘルパーメソッド
  def google_maps_mock_setup
    page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: <<~JS)
      window.google = {
        maps: {
          importLibrary: async function (libraryName) {
            switch (libraryName) {
              case "maps":
                return {
                  Map: class MapMock {
                    constructor(element, options) {
                      this.center = options.center;
                      this.zoom = options.zoom;
                      this.element = element;
                      this.eventListeners = {};
                    }
                    getCenter() {
                      return this.center;
                    }
                    // event.addListenerで設定するイベントリスナー登録用メソッド
                    addEventListener(eventName, callback) {
                      this.eventListeners[eventName] = callback;
                    }
                    // Googleマップへのタップを再現するイベント発火用メソッド
                    trigger(eventName, eventArgs) {
                      const callback = this.eventListeners[eventName];
                      if (callback) {
                        callback({
                          latLng: new window.google.maps.LatLng(eventArgs.lat, eventArgs.lng)
                        });
                      }
                    }
                  }
                };
              case "marker":
                return {
                  Marker: class MarkerMock {
                    constructor({ position }) {
                      this.position = position;
                    }
                    setPosition(position) {
                      this.position = position;
                    }
                    getPosition() {
                      return this.position;
                    }
                  },
                  Animation: { DROP: "DROP" }
                };
              case "core":
                return {
                  LatLng: class LatLngMock {
                    constructor(lat, lng) {
                      this.latValue = lat;
                      this.lngValue = lng;
                    }
                    lat() {
                      return this.latValue;
                    }
                    lng() {
                      return this.lngValue;
                    }
                    // LatLngMock オブジェクトの値をテストする場合に使用する（例：gMap.getCenter().toJSON()）
                    toJSON() {
                      return { lat: this.latValue, lng: this.lngValue };
                    }
                  },
                  event: {
                    addListener: (map, eventName, callback) => {
                      map.addEventListener(eventName, callback);
                    }
                  }
                };
              default:
                throw new Error(`Unknown library: ${libraryName}`);
            }
          },
          // MapMockのtriggerメソッドで使用する window.google.maps.LatLng のモック
          LatLng: class LatLngMock {
            constructor(lat, lng) {
              this.latValue = lat;
              this.lngValue = lng;
            }
            lat() {
              return this.latValue;
            }
            lng() {
              return this.lngValue;
            }
            // LatLngMock オブジェクトの値をテストする場合に使用する（例：gMap.getCenter().toJSON()）
            toJSON() {
              return { lat: this.latValue, lng: this.lngValue };
            }
          }
        }
      };
    JS
  end

  # geolocation のモックヘルパーメソッド（位置情報を使用するケース）
  def geolocation_success_mock_setup(latitude, longitude)
    page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: <<~JS)
      navigator.geolocation.getCurrentPosition = function(success) {
        success({
          coords: {
            latitude: #{latitude},
            longitude: #{longitude}
          }
        });
      };
    JS
  end

  # geolocation のモックヘルパーメソッド（位置情報を使用しないケース）
  def geolocation_error_mock_setup
    page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: <<~JS)
      navigator.geolocation.getCurrentPosition = function(success, error) {
        error({ code: 1, message: "位置情報の取得は許可されませんでした。" });
      };
    JS
  end

  describe "ビューの要素" do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }
    let!(:shopping_record_buy) do
      create(
        :buy, :purchased,
        user: user, shopping_record: shopping_record,
        item_name: item.name, item_hiragana: item.hiragana
      )
    end

    describe "new" do
      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "お買い物場所が未登録の場合" do
          before do
            visit new_shopping_location_path(shopping_record.hashid)
          end

          include_examples "ユーザー情報の表示テスト"

          # ナビゲーションのテスト用変数
          let(:navigation_content) { "「#{shopping_record.title}」のお買い物場所を記録するよ！" }

          include_examples "ナビゲーションのテスト"

          it "ページタイトルが表示されること" do
            expect(page).to have_selector("h1", text: "お買い物場所の記録")
          end

          it "お買い物履歴の詳細ページに戻るリンクが存在すること" do
            expect(page).to have_link("詳細ページ にもどる", href: shopping_results_path(shopping_record.hashid))
          end

          it "詳細ページに戻るリンクをクリックしてお買い物履歴の詳細ページに遷移すること" do
            click_link "詳細ページ にもどる"

            expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
            expect(current_path).to eq shopping_results_path(shopping_record.hashid)
          end

          it "お買い物場所を記録するの項目が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h2", text: "お買い物場所を記録する")
            end
          end

          it "Googleマップが表示される領域が存在すること" do
            # Googleマップが表示される要素を確認
            expect(page).to have_selector("div#map")
          end

          it "緯度・経度が入力されるhiddenフィールドが存在すること" do
            expect(page).to have_field("shopping_location_latitude", type: "hidden")
            expect(page).to have_field("shopping_location_longitude", type: "hidden")
          end

          it "お買い物のハッシュIDの値を持ったhiddenフィールドが存在すること", js: true do
            expect(
              find_field(
                "shopping_location_shopping_record_hashid",
                type: "hidden",
                with: shopping_record.hashid
              )
            ).to be_truthy
          end

          it "お買い物場所を記録のボタンが存在すること" do
            expect(page).to have_button("お買い物場所を記録")
          end

          # ヘルプモーダルの基本機能テスト用変数
          let(:page_title) { "お買い物場所の記録" }

          include_examples "ヘルプモーダルの基本機能テスト"

          it "ヘルプモーダル内の主な項目が正しく表示されること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "お買い物場所の登録の仕方")
              expect(page).to have_selector("h5", text: "① GoogleMap上でお買い物した場所をクリック（タップ）してマーカーを立てる")
              expect(page).to have_selector("h5", text: "② お買い物場所を記録ボタンを押す")
              expect(page).to have_selector("h3", text: "ボタンについて")
              expect(page).to have_selector("h4", text: "各ボタンの説明")
              expect(page).to have_selector("div.btn", text: "お買い物場所を記録")
              expect(page).to have_selector("h5", text: "お買い物場所を記録ボタン")
            end
          end
        end

        context "お買い物場所が登録済みの場合" do
          let!(:shopping_location) { create(:shopping_location, shopping_record: shopping_record) }

          before do
            visit new_shopping_location_path(shopping_record.hashid)
          end

          it "お買い物更新画面にリダイレクトされること" do
            expect(page).to have_selector("h1", text: "お買い物場所の更新")
            expect(current_path).to eq edit_shopping_location_path(shopping_record.hashid)
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit new_shopping_location_path(shopping_record.hashid)
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "Google Mapsに関連する箇所のテスト", js: true do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"

          @google_maps_script_id = google_maps_mock_setup
        end

        after do
          # テスト終了時にモックスクリプトを削除
          remove_script(@google_maps_script_id)
          remove_script(@geolocation_script_id)
        end

        context "位置情報取得状態に関わらず共通する挙動のテスト" do
          before do
            @geolocation_script_id = geolocation_success_mock_setup(35.68956, 139.69167)

            visit new_shopping_location_path(shopping_record.hashid)
          end

          it "初期状態のマーカーが正しい位置に設定されること" do
            # Marker モックの初期化確認
            expect(page.evaluate_script("window.test.marker")).not_to be_nil

            # 初期マーカーの位置を確認
            marker_position = page.evaluate_script("window.test.marker.getPosition().toJSON()")
            expect(marker_position).to eq({ "lat" => 35.68956, "lng" => 139.69167 })
          end

          it "マップ上のクリックでマーカーの位置が更新されること" do
            # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
            page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

            # クリック後のマーカーの位置を確認
            marker_position = page.evaluate_script("window.test.marker.getPosition().toJSON()")
            expect(marker_position).to eq({ "lat" => 35.68962, "lng" => 139.70076 })
          end

          it "マップ上のクリックで緯度経度のフォームの値が更新されること" do
            # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
            page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

            # フォームの値がクリックした座標に更新されることを確認
            expect(find_field("shopping_location_latitude", type: "hidden").value).to eq "35.68962"
            expect(find_field("shopping_location_longitude", type: "hidden").value).to eq "139.70076"
          end
        end

        context "正常に位置情報を取得できる場合" do
          before do
            @geolocation_script_id = geolocation_success_mock_setup(35.68956, 139.69167)

            visit new_shopping_location_path(shopping_record.hashid)
          end

          it "取得した位置情報でマップが初期化されること" do
            # Map モックの初期化確認
            expect(page.evaluate_script("window.test.gMap")).not_to be_nil

            # 初期化時の中心座標が正しいか確認（位置情報を想定）
            center = page.evaluate_script("window.test.gMap.getCenter().toJSON()")
            expect(center).to eq({ "lat" => 35.68956, "lng" => 139.69167 })
          end

          it "初期状態でユーザーの現在位置の緯度・経度がフォームに反映されていること" do
            # hidden フィールドに期待する値が設定されているか確認
            expect(find_field("shopping_location_latitude", type: "hidden").value).to eq "35.68956"
            expect(find_field("shopping_location_longitude", type: "hidden").value).to eq "139.69167"
          end
        end

        context "位置情報が取得できない場合" do
          # ビューのDEFAULT_POSITION定数を取得する
          let(:default_position) { page.evaluate_script("DEFAULT_POSITION") }

          before do
            # 位置情報の取得が許可されなかった状態を再現する
            @geolocation_script_id = geolocation_error_mock_setup

            visit new_shopping_location_path(shopping_record.hashid)
          end

          it "デフォルトの緯度・経度でマップが初期化されること" do
            # Map モックの初期化確認
            expect(page.evaluate_script("window.test.gMap")).not_to be_nil

            # 初期化時の中心座標が正しいか確認（デフォルト値の緯度・経度を想定）
            center = page.evaluate_script("window.test.gMap.getCenter().toJSON()")
            expect(center).to eq({ "lat" => default_position['latitude'], "lng" => default_position['longitude'] })
          end

          it "初期状態でデフォルトの緯度・経度がフォームに反映されていること" do
            # hidden フィールドに期待する値が設定されているか確認
            expect(find_field("shopping_location_latitude", type: "hidden").value).to eq default_position['latitude'].to_s
            expect(find_field("shopping_location_longitude", type: "hidden").value).to eq default_position['longitude'].to_s
          end
        end
      end
    end

    describe "edit" do
      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "お買い物場所が登録済みの場合" do
          let!(:shopping_location) { create(:shopping_location, shopping_record: shopping_record) }

          before do
            visit edit_shopping_location_path(shopping_record.hashid)
          end

          include_examples "ユーザー情報の表示テスト"

          # ナビゲーションのテスト用変数
          let(:navigation_content) { "「#{shopping_record.title}」のお買い物場所を登録し直すよ！" }

          include_examples "ナビゲーションのテスト"

          it "ページタイトルが表示されること" do
            expect(page).to have_selector("h1", text: "お買い物場所の更新")
          end

          it "お買い物履歴の詳細ページに戻るリンクが存在すること" do
            expect(page).to have_link("詳細ページ にもどる", href: shopping_results_path(shopping_record.hashid))
          end

          it "詳細ページに戻るリンクをクリックしてお買い物履歴の詳細ページに遷移すること" do
            click_link "詳細ページ にもどる"

            expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
            expect(current_path).to eq shopping_results_path(shopping_record.hashid)
          end

          it "お買い物場所を更新するの項目が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h2", text: "お買い物場所を更新する")
            end
          end

          it "Googleマップが表示される領域が存在すること" do
            # Googleマップが表示される要素を確認
            expect(page).to have_selector("div#map")
          end

          it "緯度・経度が入力されるhiddenフィールドが存在すること" do
            expect(page).to have_field("shopping_location_latitude", type: "hidden")
            expect(page).to have_field("shopping_location_longitude", type: "hidden")
          end

          it "お買い物場所を更新のボタンが存在すること" do
            expect(page).to have_button("お買い物場所を更新")
          end

          # ヘルプモーダルの基本機能テスト用変数
          let(:page_title) { "お買い物場所の更新" }

          include_examples "ヘルプモーダルの基本機能テスト"

          it "ヘルプモーダル内の主な項目が正しく表示されること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "お買い物場所の更新の仕方")
              expect(page).to have_selector("h5", text: "① GoogleMap上でお買い物した場所をクリック（タップ）してマーカーを立てる")
              expect(page).to have_selector("h5", text: "② お買い物場所を更新のボタンを押す")
              expect(page).to have_selector("h3", text: "ボタンについて")
              expect(page).to have_selector("h4", text: "各ボタンの説明")
              expect(page).to have_selector("div.btn", text: "お買い物場所を更新")
              expect(page).to have_selector("h5", text: "お買い物場所更新ボタン")
            end
          end
        end

        context "お買い物場所が未登録の場合" do
          before do
            visit edit_shopping_location_path(shopping_record.hashid)
          end

          it "お買い物履歴の年月一覧画面へリダイレクトされること" do
            expect(page).to have_content "指定されたお買い物場所の記録は存在しません。"
            expect(current_path).to eq shopping_result_group_path
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit edit_shopping_location_path(shopping_record.hashid)
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "Google Mapsに関連する箇所のテスト", js: true do
        let!(:shopping_location) do
          create(:shopping_location, shopping_record: shopping_record, latitude: 35.68956, longitude: 139.69167)
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"

          @google_maps_script_id = google_maps_mock_setup
          visit edit_shopping_location_path(shopping_record.hashid)
        end

        after do
          # テスト終了時にモックスクリプトを削除
          remove_script(@google_maps_script_id)
        end

        it "取得した位置情報でマップが初期化されること" do
          # Map モックの初期化確認
          expect(page.evaluate_script("window.test.gMap")).not_to be_nil

          # 初期化時の中心座標が正しいか確認（DB上のshopping_locationの緯度・経度を想定）
          # LatLngMockオブジェクトは使わないためtoJSONメソッドは不要
          center = page.evaluate_script("window.test.gMap.getCenter()")
          expect(center).to eq({ "lat" => shopping_location.latitude, "lng" => shopping_location.longitude })
        end

        it "初期状態のマーカーが正しい位置に設定されること" do
          # Marker モックの初期化確認
          expect(page.evaluate_script("window.test.marker")).not_to be_nil

          # Merkerの初期positionにはDB上のshopping_locationの緯度・経度の値を使用する
          # LatLngMockオブジェクトは使わないためtoJSONメソッドは不要
          marker_position = page.evaluate_script("window.test.marker.getPosition()")
          expect(marker_position).to eq({ "lat" => shopping_location.latitude, "lng" => shopping_location.longitude })
        end

        it "初期状態でお買い物場所の緯度・経度がフォームに反映されていること" do
          # 登録済みの緯度・経度の値が設定されているか確認
          expect(find_field("shopping_location_latitude", type: "hidden").value).to eq shopping_location.latitude.to_s
          expect(find_field("shopping_location_longitude", type: "hidden").value).to eq shopping_location.longitude.to_s
        end

        it "マップ上のクリックでマーカーの位置が更新されること" do
          # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
          page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

          # クリック後のマーカーの位置を確認
          marker_position = page.evaluate_script("window.test.marker.getPosition().toJSON()")
          expect(marker_position).to eq({ "lat" => 35.68962, "lng" => 139.70076 })
        end

        it "マップ上のクリックで緯度経度のフォームの値が更新されること" do
          # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
          page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

          # フォームの値がクリックした座標に更新されることを確認
          expect(find_field("shopping_location_latitude", type: "hidden").value).to eq "35.68962"
          expect(find_field("shopping_location_longitude", type: "hidden").value).to eq "139.70076"
        end
      end
    end
  end

  # お買い物場所の登録・更新のフローでは通常操作ではユーザーによる直接入力は行わないため異常系のテストは実施しない
  # デベロッパーツールによる不正な値の入力などのエッジケースにおける制御については別途テストを設ける
  describe "お買い物場所登録のフロー", js: true do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }
    let!(:shopping_record_buy) do
      create(
        :buy, :purchased,
        user: user, shopping_record: shopping_record,
        item_name: item.name, item_hiragana: item.hiragana
      )
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"

      @google_maps_script_id = google_maps_mock_setup
    end

    after do
      # テスト終了時にモックスクリプトを削除
      remove_script(@google_maps_script_id)
      remove_script(@geolocation_script_id)
    end

    context "位置情報が取得される場合" do
      before do
        @geolocation_script_id = geolocation_success_mock_setup(35.68956, 139.69167)

        visit shopping_results_path(shopping_record.hashid)
        expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
      end

      scenario "ユーザーがお買い物履歴のお買い物場所登録画面へのリンクからお買い物場所を登録する（位置情報変更なし）" do
        click_link(href: new_shopping_location_path(shopping_record.hashid))

        expect(page).to have_selector("h1", text: "お買い物場所の記録")
        # Map モックの初期化確認
        expect(page.evaluate_script("window.test.gMap")).not_to be_nil

        # 初期化時の中心座標が正しいか確認（位置情報を想定）
        center = page.evaluate_script("window.test.gMap.getCenter().toJSON()")
        expect(center).to eq({ "lat" => 35.68956, "lng" => 139.69167 })

        expect do
          click_button "お買い物場所を記録"
          expect(page).to have_content "お買い物場所が登録されました。"
          expect(current_path).to eq shopping_results_path(shopping_record.hashid)
        end.to change { ShoppingLocation.count }.by(1)

        shopping_location = ShoppingLocation.last
        expect(shopping_location.shopping_record_id).to eq shopping_record.id
        expect(shopping_location.latitude).to eq 35.68956
        expect(shopping_location.longitude).to eq 139.69167
      end

      scenario "ユーザーがお買い物履歴のお買い物場所登録画面へのリンクからお買い物場所を登録する（位置情報変更あり）" do
        click_link(href: new_shopping_location_path(shopping_record.hashid))

        expect(page).to have_selector("h1", text: "お買い物場所の記録")
        # Map モックの初期化確認
        expect(page.evaluate_script("window.test.gMap")).not_to be_nil

        # 初期化時の中心座標が正しいか確認（位置情報を想定）
        center = page.evaluate_script("window.test.gMap.getCenter().toJSON()")
        expect(center).to eq({ "lat" => 35.68956, "lng" => 139.69167 })

        # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
        page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

        # クリック後のマーカーの位置を確認
        marker_position = page.evaluate_script("window.test.marker.getPosition().toJSON()")
        expect(marker_position).to eq({ "lat" => 35.68962, "lng" => 139.70076 })

        expect do
          click_button "お買い物場所を記録"
          expect(page).to have_content "お買い物場所が登録されました。"
          expect(current_path).to eq shopping_results_path(shopping_record.hashid)
        end.to change { ShoppingLocation.count }.by(1)

        shopping_location = ShoppingLocation.last
        expect(shopping_location.shopping_record_id).to eq shopping_record.id
        expect(shopping_location.latitude).to eq 35.68962
        expect(shopping_location.longitude).to eq 139.70076
      end
    end

    context "位置情報が取得されない場合" do
      # ビューのDEFAULT_POSITION定数を取得する
      let(:default_position) { page.evaluate_script("DEFAULT_POSITION") }

      before do
        @geolocation_script_id = geolocation_error_mock_setup

        visit shopping_results_path(shopping_record.hashid)
        expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
      end

      scenario "ユーザーがお買い物履歴のお買い物場所登録画面へのリンクからお買い物場所を登録する" do
        click_link(href: new_shopping_location_path(shopping_record.hashid))

        expect(page).to have_selector("h1", text: "お買い物場所の記録")
        # Map モックの初期化確認
        expect(page.evaluate_script("window.test.gMap")).not_to be_nil

        # 初期化時の中心座標が正しいか確認（デフォルトの位置情報を想定）
        center = page.evaluate_script("window.test.gMap.getCenter().toJSON()")
        expect(center).to eq({ "lat" => default_position['latitude'], "lng" => default_position['longitude'] })

        # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
        page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

        # クリック後のマーカーの位置を確認
        marker_position = page.evaluate_script("window.test.marker.getPosition().toJSON()")
        expect(marker_position).to eq({ "lat" => 35.68962, "lng" => 139.70076 })

        expect do
          click_button "お買い物場所を記録"
          expect(page).to have_content "お買い物場所が登録されました。"
          expect(current_path).to eq shopping_results_path(shopping_record.hashid)
        end.to change { ShoppingLocation.count }.by(1)

        shopping_location = ShoppingLocation.last
        expect(shopping_location.shopping_record_id).to eq shopping_record.id
        expect(shopping_location.latitude).to eq 35.68962
        expect(shopping_location.longitude).to eq 139.70076
      end
    end
  end

  describe "お買い物場所更新のフロー", js: true do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }
    let!(:shopping_record_buy) do
      create(
        :buy, :purchased,
        user: user, shopping_record: shopping_record,
        item_name: item.name, item_hiragana: item.hiragana
      )
    end
    let!(:shopping_location) do
      create(:shopping_location, shopping_record: shopping_record, latitude: 35.68956, longitude: 139.69167)
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"

      @google_maps_script_id = google_maps_mock_setup

      visit shopping_results_path(shopping_record.hashid)
      expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
    end

    after do
      # テスト終了時にモックスクリプトを削除
      remove_script(@google_maps_script_id)
    end

    scenario "ユーザーがお買い物履歴のお買い物場所更新画面へのリンクからお買い物場所を更新する" do
      click_link(href: edit_shopping_location_path(shopping_record.hashid))

      expect(page).to have_selector("h1", text: "お買い物場所の更新")
      # Map モックの初期化確認
      expect(page.evaluate_script("window.test.gMap")).not_to be_nil

      # 初期化時の中心座標が正しいか確認（DB上のshopping_locationの緯度・経度を想定）
      # LatLngMockオブジェクトは使わないためtoJSONメソッドは不要
      center = page.evaluate_script("window.test.gMap.getCenter()")
      expect(center).to eq({ "lat" => 35.68956, "lng" => 139.69167 })

      # マップ上の新しい座標（35.68962, 139.70076）のクリックを再現
      page.execute_script("window.test.gMap.trigger('click', { lat: 35.68962, lng: 139.70076 })")

      # クリック後のマーカーの位置を確認
      marker_position = page.evaluate_script("window.test.marker.getPosition().toJSON()")
      expect(marker_position).to eq({ "lat" => 35.68962, "lng" => 139.70076 })

      expect do
        click_button "お買い物場所を更新"
        expect(page).to have_content "お買い物場所が更新されました。"
        expect(current_path).to eq shopping_results_path(shopping_record.hashid)
      end.to change { shopping_location.reload.latitude }.from(35.68956).to(35.68962).
        and change { shopping_location.reload.longitude }.from(139.69167).to(139.70076)
    end
  end

  describe "お買い物場所削除のフロー" do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }
    let!(:shopping_record_buy) do
      create(
        :buy, :purchased,
        user: user, shopping_record: shopping_record,
        item_name: item.name, item_hiragana: item.hiragana
      )
    end
    let!(:shopping_location) do
      create(:shopping_location, shopping_record: shopping_record)
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"

      visit shopping_results_path(shopping_record.hashid)
      expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
    end

    scenario "ユーザーがお買い物履歴のお買い物場所削除ボタンからお買い物場所を削除する", js: true do
      within("div.confirm-window", text: "お買い物した場所") do
        find("i.delete-icon").click
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        within ".alert" do
          expect(page).to have_content "お買い物場所が削除されました。"
        end

        expect(current_path).to eq shopping_results_path(shopping_record.hashid)
      end.to change { ShoppingLocation.count }.by(-1)

      # お買い物場所がDBに存在しないことを確認
      expect(ShoppingLocation.where(id: shopping_location.id)).to_not exist
    end
  end
end
