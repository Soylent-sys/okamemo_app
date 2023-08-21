module ApplicationHelper
  BASE_TITLE = "おかメchan".freeze

  def full_title(title: '')
    title.blank? ? "#{BASE_TITLE} - 買い物お助けサービス" : "#{title} - #{BASE_TITLE}"
  end
end
