function setUncheckAll() {
  const checkbox = document.getElementsByName("shopping_record_form[hashids][]");

  function uncheckAll() {
    for(let i = 0; i < checkbox.length; i++) {
      checkbox[i].checked = false
    }
  }

  document.getElementById("check_reset_button").addEventListener('click', uncheckAll);
}

document.addEventListener('turbo:load', setUncheckAll);
document.addEventListener('turbo:render', setUncheckAll);
