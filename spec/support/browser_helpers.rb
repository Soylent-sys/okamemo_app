module BrowerHelpers
  # execute_cdp('Page.addScriptToEvaluateOnNewDocument')で事前設定したスクリプトを削除する
  def remove_script(script_id)
    return unless script_id

    page.driver.browser.execute_cdp(
      'Page.removeScriptToEvaluateOnNewDocument',
      identifier: script_id['identifier']
    )
  end
end

RSpec.configure do |config|
  config.include BrowerHelpers, type: :system
end
