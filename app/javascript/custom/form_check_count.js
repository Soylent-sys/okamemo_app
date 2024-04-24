function setFormCheckCount() {
  const checkbox = document.getElementsByName("shopping_record_form[hashids][]");
  const checkCount = document.getElementById("check-count");
  const checkCountContainer = document.getElementById("check-count-box");
  const clickPoint = document.getElementsByName("checkbox_click_point");

  if (checkCount) {
    function formCheckCount() {
      let count = 0;
      const MAX_COUNT = 20;
      for(let i = 0; i < checkbox.length; i++) {
        if (checkbox[i].checked) {
          count++;
        }
      }

      if (count === 0) {
        checkCountContainer.classList.add("d-none");
      } else {
        checkCountContainer.classList.remove("d-none");
      }

      if (count <= MAX_COUNT) {
        checkCountContainer.classList.replace("check_count_over_bg_color", "check_count_bg_color");
      } else {
        checkCountContainer.classList.replace("check_count_bg_color", "check_count_over_bg_color");
      }

      checkCount.textContent = count;
    }

    for(let i = 0; i < clickPoint.length; i++) {
      clickPoint[i].addEventListener('click', formCheckCount);
    }

    formCheckCount();
  }
}

document.addEventListener('turbo:load', setFormCheckCount);
document.addEventListener('turbo:render', setFormCheckCount);
