require 'pagy/extras/bootstrap'
require 'pagy/extras/overflow'

Pagy::I18n.load({ locale: 'ja',
                  filepath: 'config/locales/pagy-ja.yml' })
Pagy::DEFAULT[:overflow] = :last_page
