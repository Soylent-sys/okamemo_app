const bootstrapConfirm = (message, formElement) => {
  const modalElement = document.getElementById('turbo-confirm-modal')
  const titleElement = document.getElementById('turbo-confirm-modal-title')
  const messageElement = document.getElementById('turbo-confirm-modal-message')
  const confirmButtonElement = document.getElementById('turbo-confirm-modal-confirm-button')
  const modal = new bootstrap.Modal(modalElement)

  titleElement.textContent = formElement.getAttribute('data-turbo-confirm-title')
  messageElement.textContent = message
  confirmButtonElement.classList = formElement.getAttribute('data-turbo-confirm-button-class')
  confirmButtonElement.textContent = formElement.getAttribute('data-turbo-confirm-submit-text')
  modal.show()

  return new Promise((resolve) => {
    confirmButtonElement.addEventListener(
      'click',
      () => {
        resolve(true)
        modal.hide()
      },
      { once: true },
    )
  })
}

Turbo.setConfirmMethod(bootstrapConfirm)
