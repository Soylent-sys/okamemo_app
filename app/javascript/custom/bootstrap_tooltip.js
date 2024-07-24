// bootstrap tooltip設定
function setTooltip() {
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
}

document.addEventListener('turbo:load', setTooltip);
document.addEventListener('turbo:render', setTooltip);
