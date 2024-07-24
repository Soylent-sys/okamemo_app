// お買い物登録画面のアイテムチェックのリセットボタン押下時の処理
function setUncheckAll() {
  const checkbox = document.getElementsByName("shopping_record_form[hashids][]");
  const checkCount = document.getElementById("check-count");
  const checkCountContainer = document.getElementById("check-count-box");

  if (checkCount) {
    // 全てのcheckboxのチェックを外す
    function uncheckAll() {
      for(let i = 0; i < checkbox.length; i++) {
        checkbox[i].checked = false;
      }

      checkCount.textContent = 0;
      checkCountContainer.classList.add("d-none");
    }

    document.getElementById("check_reset_button").addEventListener('click', uncheckAll);
  }
}

document.addEventListener('turbo:load', setUncheckAll);
document.addEventListener('turbo:render', setUncheckAll);
