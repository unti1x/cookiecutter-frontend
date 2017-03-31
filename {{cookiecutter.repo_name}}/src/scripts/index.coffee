do ->
  expander = document.getElementById 'links-expander'
  linksList = document.getElementById 'links-list'

  expander.addEventListener 'click', (event)->
    event.preventDefault()

    linksList.classList.toggle 'hidden'
    @classList.toggle 'active'
    return

  return
