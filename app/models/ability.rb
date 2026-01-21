# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    else
      # Blogs
      can :read, Blog, published: true
      can :read, Blog, user_id: user.id
      can :create, Blog
      can :update, Blog, user_id: user.id
      can :destroy, Blog, user_id: user.id
      can :publish, Blog, user_id: user.id
      
      # Comments
      can :read, Comment
      can :create, Comment
      can :update, Comment, user_id: user.id
      can :destroy, Comment, user_id: user.id
    end
  end
end
