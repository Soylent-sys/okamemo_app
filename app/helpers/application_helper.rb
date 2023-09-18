module ApplicationHelper
  BASE_TITLE = "おかメchan".freeze

  def full_title(title: '')
    title.blank? ? "#{BASE_TITLE} - 買い物お助けサービス" : "#{title} - #{BASE_TITLE}"
  end

  def html_safe_newline(str)
    h(str).gsub(/\n|\r|\r\n/, "<br>").html_safe
  end
end
