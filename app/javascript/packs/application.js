// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

//= require jquery3
//= require jquery_ujs
//= require popper
//= require bootstrap-sprockets
//= require bootstrap-table/bootstrap-table
//= require_tree .


import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

require('jquery')

Rails.start()
Turbolinks.start()
ActiveStorage.start()

import autoComplete from './auto-complete'
window.autoComplete = autoComplete




