# -*- encoding : utf-8 -*-
Rails.application.routes.draw do
  mount Refinery::Core::Engine, :at => "/"
end
