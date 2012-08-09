RedmineApp::Application.routes.draw do
  root :to => 'account#ssl_login', :as => 'home', :force_ssl => true
  match 'login', :to => 'account#ssl_login', :as => 'signin', :force_ssl => true
  match 'login/ssl', :to => 'account#ssl_login', :as => 'signin', :force_ssl => true
end
