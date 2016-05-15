optionsFields = ['dbUrl', 'dbUsername', 'dbPassword', 'creatorId',
                 'creatorName', 'creatorNick']

# Saves options to chrome.storage.sync.
save_options = () ->
  toSetOptions = {}
  toSetOptions[field] = document.getElementById(field).value for field in optionsFields

  chrome.storage.sync.set toSetOptions, () ->
      # Update status to let user know options were saved.
      status = document.getElementById 'status'
      status.textContent = 'Options saved.'
      setTimeout (-> status.textContent = ''), 1000

# Restores select box and checkbox state using the preferences
# stored in chrome.storage.
restore_options = () ->
  chrome.storage.sync.get (items) ->
    for field in optionsFields
      document.getElementById(field).value = items[field] if items[field]?
    return

document.addEventListener 'DOMContentLoaded', restore_options
document.getElementById('save').addEventListener 'click', save_options